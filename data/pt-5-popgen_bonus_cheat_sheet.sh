#!/usr/bin/env bash
# Cheat sheet for Part 6 (Bonus, Simplified) - Population Genomics with PLINK 2.
# Runs every command in docs/practicals/pt-6-popgen_bonus_simplified.md in order.
#
# Usage:
#   bash pt-6-popgen_bonus_cheat_sheet_simplified.sh [path/to/snp.vcf.gz]

set -euo pipefail

VCF="${1:-$HOME/2026-09-29-genotyping/results/snp.vcf.gz}"
[[ -f "$VCF" ]] || VCF="/shared/data/backup_vcf/snp.vcf.gz"
[[ -f "$VCF" ]] || { echo "ERROR: VCF not found: $VCF" >&2; exit 1; }
VCF="$(cd "$(dirname "$VCF")" && pwd)/$(basename "$VCF")"

echo "==================== Setting up ===================="
mkdir -p 2026-09-29-popgen_bonus_simple
cd 2026-09-29-popgen_bonus_simple
mkdir -p input results tmp
touch WHATIDID.txt
ln -sf "$VCF"     input/snp.vcf.gz
ln -sf "$VCF.tbi" input/snp.vcf.gz.tbi
plink2 --version

echo "==================== Challenge 1a - Convert the VCF ===================="
plink2 \
  --vcf input/snp.vcf.gz \
  --allow-extra-chr \
  --set-all-var-ids '@:#' \
  --max-alleles 2 \
  --make-pgen \
  --out tmp/snp

grep -v '^##' tmp/snp.pvar | awk 'NR <= 5'
cat tmp/snp.psam

echo "==================== Challenge 1b - Population file ===================="
printf '#IID\tPOP\n' > tmp/populations.tsv
awk 'NR > 1 { if ($1 ~ /_B/) print $1 "\tB"; else print $1 "\tb" }' tmp/snp.psam >> tmp/populations.tsv
cat tmp/populations.tsv

echo "==================== Challenge 2a - FST per SNP ===================="
plink2 \
  --pfile tmp/snp \
  --allow-extra-chr \
  --pheno tmp/populations.tsv \
  --pheno-name POP \
  --fst POP method=hudson report-variants \
  --out results/fst

cat results/fst.fst.summary
head results/fst.B.b.fst.var

echo "==================== Challenge 2b - Top 10 SNPs by FST ===================="
head -n 1 results/fst.B.b.fst.var | tr '\t' '\n' | cat -n
FST_COL=$(head -n 1 results/fst.B.b.fst.var | tr '\t' '\n' | grep -n 'FST$' | cut -d: -f1)
echo "FST is in column $FST_COL"

# awk instead of head avoids a broken-pipe exit under 'set -o pipefail'.
sort -k${FST_COL},${FST_COL}gr results/fst.B.b.fst.var | awk 'NR <= 10'

echo "==================== Challenge 2c - FST per scaffold ===================="
for sc in scaffold_1 scaffold_2; do
  awk -v sc="$sc" -v c="$FST_COL" '
    $1 == sc && $c != "nan" { n++; sum += $c; if ($c >= 0.99) fixed++ }
    END { print sc, "- SNPs:", n, "- mean FST:", sum/n, "- fixed differences:", fixed+0 }
  ' results/fst.B.b.fst.var
done

echo "-- 5 lowest FST values:"
grep -v '^#' results/fst.B.b.fst.var | sort -k${FST_COL},${FST_COL}g | awk 'NR <= 5'

echo "==================== Challenge 3a - r2 per scaffold ===================="
for sc in scaffold_1 scaffold_2; do
  plink2 \
    --pfile tmp/snp \
    --allow-extra-chr \
    --chr "$sc" \
    --maf 0.14 \
    --r2-unphased \
    --ld-window 100000 \
    --ld-window-kb 1000 \
    --ld-window-r2 0 \
    --out "results/ld_${sc}"
done

head results/ld_scaffold_1.vcor
wc -l results/ld_scaffold_1.vcor results/ld_scaffold_2.vcor

echo "==================== Challenge 3b - Near vs far pairs ===================="
head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | cat -n
POS_A_COL=$(head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | grep -n -x 'POS_A' | cut -d: -f1)
POS_B_COL=$(head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | grep -n -x 'POS_B' | cut -d: -f1)
R2_COL=$(head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | grep -n 'R2$' | cut -d: -f1)
echo "POS_A: $POS_A_COL  POS_B: $POS_B_COL  R2: $R2_COL"

for sc in scaffold_1 scaffold_2; do
  echo "=== $sc ==="
  awk -v a="$POS_A_COL" -v b="$POS_B_COL" -v r="$R2_COL" '
    NR > 1 {
      dist = $b - $a
      if (dist < 0) dist = -dist
      if (dist < 10000)  { near_n++; near_sum += $r; if ($r >= 0.8) near_high++ }
      if (dist > 100000) { far_n++;  far_sum  += $r; if ($r >= 0.8) far_high++ }
    }
    END {
      print "Near pairs (<10 kb):  ", near_n, "pairs, mean r2 =", near_sum/near_n, ", proportion r2 >= 0.8 =", near_high/near_n
      print "Far pairs  (>100 kb): ", far_n,  "pairs, mean r2 =", far_sum/far_n,   ", proportion r2 >= 0.8 =", far_high/far_n
    }
  ' "results/ld_${sc}.vcor"
done

echo "==================== Done - outputs in $(pwd)/results ===================="
ls results
