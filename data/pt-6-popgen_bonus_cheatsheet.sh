#!/usr/bin/env bash
# Cheat sheet / answer key for Part 6 (Bonus) - Population Genomics on the Command Line.
# Runs every analysis in docs/practicals/pt-6-popgen_bonus.md end to end.
#
# Usage:
#   bash pt-6-popgen_bonus_cheatsheet.sh [path/to/snp.vcf.gz] [output_dir]
#
# Defaults: VCF from the genotyping practical, falling back to the shared backup.

set -euo pipefail

VCF="${1:-$HOME/2026-09-29-genotyping/results/snp.vcf.gz}"
[[ -f "$VCF" ]] || VCF="/shared/data/backup_vcf/snp.vcf.gz"
OUTDIR="${2:-2026-09-29-popgen_bonus}"

WINDOW=10000         # FST window size (bp)
MIN_SNPS_WINDOW=5    # drop FST windows built from fewer SNPs than this
MAF=0.14             # = seen in at least 2 of 14 samples
LD_BIN=10000         # LD-decay distance bin (bp)
MIN_PAIRS_BIN=20     # drop LD-decay bins with fewer pairs than this
SCAFFOLDS=(scaffold_1 scaffold_2)

# Every PLINK call needs --allow-extra-chr because scaffold names are non-standard.
PLINK=(plink2 --allow-extra-chr)

section() { printf '\n==================== %s ====================\n' "$1"; }

# Prints a PLINK .rel matrix, rounded, with sample labels on each row.
show_rel() {
  paste <(awk '!/^#/ { print $NF }' "$1.rel.id") \
        <(awk '{ for (i=1; i<=NF; i++) printf "%.2f%s", $i, (i<NF ? "\t" : "\n") }' "$1.rel") \
    | column -t
}

# Fewer than 50 samples, so PLINK needs pre-computed frequencies for the GRM.
make_rel() {
  local out=$1; shift
  "${PLINK[@]}" --pfile tmp/snp --read-freq tmp/snp.afreq --mac 1 "$@" --make-rel square --out "$out"
}

#############################################################################
section "Setup"
#############################################################################
[[ -f "$VCF" ]] || { echo "ERROR: VCF not found: $VCF" >&2; exit 1; }
VCF_ABS="$(cd "$(dirname "$VCF")" && pwd)/$(basename "$VCF")"

mkdir -p "$OUTDIR"/{input,results,tmp}
cd "$OUTDIR"
touch WHATIDID.txt
ln -sf "$VCF_ABS"     input/snp.vcf.gz
ln -sf "$VCF_ABS.tbi" input/snp.vcf.gz.tbi

plink2 --version

#############################################################################
section "Challenge 1 - VCF to PLINK 2 pfile"
#############################################################################
"${PLINK[@]}" \
  --vcf input/snp.vcf.gz \
  --set-all-var-ids '@:#' \
  --max-alleles 2 \
  --make-pgen \
  --out tmp/snp

echo "VCF variants : $(bcftools view -H input/snp.vcf.gz | wc -l)"
echo "VCF samples  : $(bcftools query -l input/snp.vcf.gz | wc -l)"
echo "pfile variants: $(grep -vc '^#' tmp/snp.pvar)"
echo "pfile samples : $(grep -vc '^#' tmp/snp.psam)"

#############################################################################
section "Challenge 2 - Describe the data and define populations"
#############################################################################
"${PLINK[@]}" --pfile tmp/snp --freq    --out tmp/snp
"${PLINK[@]}" --pfile tmp/snp --missing --out tmp/snp

echo "-- Smallest non-zero ALT frequency (expect 1/14 = 0.0714):"
awk 'NR==1 { for (i=1;i<=NF;i++) if ($i=="ALT_FREQS") f=i; next }
     $f>0 && (m=="" || $f<m) { m=$f } END { print m }' tmp/snp.afreq

echo "-- Per-sample missingness:"
column -t tmp/snp.smiss

{ printf '#IID\tPOP\n'
  awk 'NR>1 { print $1"\t"( $1 ~ /_B\.bam$/ ? "B" : "b" ) }' tmp/snp.psam
} > tmp/populations.tsv

for pop in B b; do
  { printf '#IID\n'
    awk -v p="$pop" 'NR>1 && $2==p { print $1 }' tmp/populations.tsv
  } > "tmp/keep_${pop}.txt"
done

column -t tmp/populations.tsv
wc -l tmp/keep_B.txt tmp/keep_b.txt

#############################################################################
section "Challenge 3 - Genetic relationship matrix"
#############################################################################
make_rel results/rel_all
echo "-- All SNPs:"
show_rel results/rel_all

for sc in "${SCAFFOLDS[@]}"; do
  make_rel "results/rel_${sc}" --chr "$sc"
  echo "-- $sc:"
  show_rel "results/rel_${sc}"
done

#############################################################################
section "Challenge 4a - Per-variant FST (Hudson)"
#############################################################################
"${PLINK[@]}" \
  --pfile tmp/snp \
  --pheno tmp/populations.tsv \
  --pheno-name POP \
  --fst POP method=hudson report-variants \
  --out results/fst

FST_VAR=$(ls results/fst.*.fst.var)
echo "Per-variant file: $FST_VAR"
cat results/fst.fst.summary

#############################################################################
section "Challenge 4b/c - Windowed FST"
#############################################################################
awk -F'\t' -v W="$WINDOW" -v MIN="$MIN_SNPS_WINDOW" '
  NR==1 { for (i=1; i<=NF; i++) { if ($i ~ /FST$/) f=i; if ($i=="POS") p=i }; next }
  ($f+0==$f) {
    w = int($p/W)
    key = $1"\t"(w*W)"\t"((w+1)*W)
    sum[key] += $f; n[key]++
  }
  END { for (k in sum) if (n[k] >= MIN) printf "%s\t%d\t%.4f\n", k, n[k], sum[k]/n[k] }
' "$FST_VAR" | sort -k1,1 -k2,2n > results/fst_windows.tsv

echo "-- Top 10 windows (CHROM START END N_SNPS MEAN_FST):"
sort -k5,5gr results/fst_windows.tsv | awk 'NR<=10' | column -t

echo "-- Mean FST per scaffold:"
awk '{ s[$1]+=$5; c[$1]++ }
     END { for (k in s) printf "%s\tn_windows=%d\tmean_FST=%.4f\n", k, c[k], s[k]/c[k] }' \
  results/fst_windows.tsv

#############################################################################
section "Challenge 4d/e - Fixed differences between B and b"
#############################################################################
for pop in B b; do
  "${PLINK[@]}" --pfile tmp/snp --keep "tmp/keep_${pop}.txt" --freq --out "tmp/freq_${pop}"
done

awk '
  FNR==1 { for (i=1; i<=NF; i++) col[$i]=i; id=col["ID"]; fq=col["ALT_FREQS"]; ch=col["#CHROM"]; next }
  NR==FNR { fB[$id]=$fq; chrom[$id]=$ch; next }
  ($id in fB) {
    total[chrom[$id]]++
    if ((fB[$id]+0==1 && $fq+0==0) || (fB[$id]+0==0 && $fq+0==1)) fixed[chrom[$id]]++
  }
  END { for (c in total) printf "%s\tSNPs=%d\tfixed_differences=%d\t(%.1f%%)\n", c, total[c], fixed[c]+0, 100*fixed[c]/total[c] }
' tmp/freq_B.afreq tmp/freq_b.afreq

#############################################################################
section "Challenge 5a - Pairwise r2 per scaffold (MAF >= $MAF)"
#############################################################################
for sc in "${SCAFFOLDS[@]}"; do
  # Defaults are tuned for human data and would silently discard most long-range pairs.
  "${PLINK[@]}" \
    --pfile tmp/snp \
    --chr "$sc" \
    --maf "$MAF" \
    --r2-unphased \
    --ld-window 100000 \
    --ld-window-kb 10000 \
    --ld-window-r2 0 \
    --out "results/ld_${sc}"
done
ls results/ld_*

#############################################################################
section "Challenge 5b - LD decay by distance"
#############################################################################
for sc in "${SCAFFOLDS[@]}"; do
  echo "-- $sc:"
  awk -F'\t' -v BIN="$LD_BIN" -v MIN="$MIN_PAIRS_BIN" '
    NR==1 { for (i=1;i<=NF;i++) { if ($i ~ /R2$/) r=i; if ($i=="POS_A") a=i; if ($i=="POS_B") b=i }; next }
    ($r+0==$r) {
      d = ($b > $a) ? $b-$a : $a-$b
      k = int(d/BIN)
      sum[k] += $r; n[k]++; if ($r >= 0.8) hi[k]++
      if (k > maxk) maxk = k
    }
    END {
      printf "%-16s %8s %10s %12s\n", "distance_kb", "n_pairs", "mean_r2", "prop_r2>=0.8"
      for (k=0; k<=maxk; k++) if (n[k] >= MIN)
        printf "%-16s %8d %10.3f %12.3f\n", (k*BIN/1000)"-"((k+1)*BIN/1000), n[k], sum[k]/n[k], hi[k]/n[k]
    }
  ' "results/ld_${sc}.vcor"
done

#############################################################################
section "Challenge 5c - LD pruning and pruned relationship matrix"
#############################################################################
# --bad-ld overrides PLINK's 50-sample minimum; acceptable for an exploratory check only.
"${PLINK[@]}" --pfile tmp/snp --bad-ld --indep-pairwise 50kb 1 0.5 --out tmp/pruned

echo "-- SNPs kept / removed by pruning, per scaffold:"
awk '
  FNR==1 { which = (FILENAME ~ /prune\.in$/) ? "kept" : "removed" }
  { split($1, s, ":"); c[s[1]"\t"which]++ }
  END { for (k in c) print k"\t"c[k] }
' tmp/pruned.prune.in tmp/pruned.prune.out | sort | column -t

make_rel results/rel_scaffold_1_pruned --chr scaffold_1 --extract tmp/pruned.prune.in
echo "-- scaffold_1 (supergene), pruned SNPs only:"
show_rel results/rel_scaffold_1_pruned

#############################################################################
section "Extra (instructor only, not in practical) - Score samples on the B/b diagnostic panel"
#############################################################################
# Weight 1 on the allele every B carries at each fixed difference: B ~ 1, b ~ 0.
awk '
  FNR==1 { for (i=1; i<=NF; i++) col[$i]=i; id=col["ID"]; fq=col["ALT_FREQS"]; ref=col["REF"]; alt=col["ALT"]; next }
  NR==FNR { fB[$id]=$fq; next }
  ($id in fB) {
    if (fB[$id]+0==1 && $fq+0==0) print $id"\t"$alt"\t1"
    else if (fB[$id]+0==0 && $fq+0==1) print $id"\t"$ref"\t1"
  }
' tmp/freq_B.afreq tmp/freq_b.afreq > tmp/b_diagnostic.score

echo "Diagnostic SNPs: $(wc -l < tmp/b_diagnostic.score)"
if [[ -s tmp/b_diagnostic.score ]]; then
  # Swap --pfile for an unknown sample's data to classify it.
  "${PLINK[@]}" --pfile tmp/snp --read-freq tmp/snp.afreq --score tmp/b_diagnostic.score 1 2 3 --out results/b_diagnostic
  column -t results/b_diagnostic.sscore
else
  echo "No fixed differences found - skipping scoring."
fi

section "Done - outputs in $(pwd)/results"
ls results
