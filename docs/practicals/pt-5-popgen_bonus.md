# **Part 6 Bonus - Population Genomics with PLINK 2**

----------------------------------------------------------------------------

## **1. Introduction**

In **Part 5** you used *R* to show that the *B* and *b* fire ants differ
genetically. In this bonus practical you will reach the same conclusion using
only the command line and [**PLINK 2**](https://www.cog-genomics.org/plink/2.0/),
a widely used tool for analysing genotype data. You will then go one step further
and measure **linkage disequilibrium**, which reveals *why* the two groups differ.

### **1.1. Why PLINK?**

PLINK is one of the most widely used programs in genomics. The original version
was published in 2007 for human genome-wide association studies (GWAS), and
it has since been cited tens of thousands of times. PLINK 2 is a complete rewrite
that keeps the same idea but is much faster. Many bioinformaticians reach for
PLINK first when working with genotype data, for several reasons:

* **It is fast and scales to huge datasets.** PLINK stores genotypes in compact
  binary files and processes them very efficiently. The same commands you run
  today on 14 ants and 1,859 SNPs are used on biobanks with hundreds of thousands
  of people and millions of SNPs.
* **One tool, many analyses.** Quality control (missing data, allele
  frequencies), population differentiation (FST), linkage disequilibrium,
  relatedness, principal component analysis and association testing are all
  built in. Most tasks are a single flag rather than a new program to learn.
* **It reads and writes the common formats.** PLINK can import VCF files like
  ours and export to the formats other tools expect, so it often sits at the
  centre of a pipeline.
* **It runs from the command line.** Every analysis is a command you can record
  in `WHATIDID.txt`, put in a script, rerun on new data, or submit to a
  computing cluster. This makes your work reproducible, which is much harder
  with point-and-click tools.
* **It works for any species.** PLINK was built for humans, but with a few
  flags - which you will meet today - it handles non-model organisms such as
  fire ants, with unusual chromosome names and haploid males.

Learning PLINK is therefore a skill you can take straight into a research
project, whatever organism you end up working on.

### **1.2. Our dataset**

| Genotype label |  Phenotype description  | Number of samples |
| :------------: | :---------------------: | :---------------: |
|      *B*       |  *single-queen* colony  |         7         |
|      *b*       | *multiple-queen* colony |         7         |

There are 14 **haploid** males and **two scaffolds** (`scaffold_1` and
`scaffold_2`) from two different chromosomes.


!!! Info
    **How this practical works.** Each challenge tells you *what* to do. Try to
    work out the command yourself first using the hints. If you get stuck, open
    the **worked command** box. 

!!! Tip
    Three habits that will help you with PLINK 2:

    * `plink2 --help <flag>` explains any flag, e.g. `plink2 --help fst`.
    * PLINK prints what it did to the screen and to a `.log` file. **Always read
      it** - especially the lines starting with `Error` or `Warning`.
    * Long commands can be split over several lines by ending each line with a
      `\`. There must be nothing (not even a space) after the `\`.

----------------------------------------------------------------------------

## **2. Setting Up**

!!! Task
    Create a project directory with the usual structure:

    ```
    mkdir 2026-09-29-popgen_bonus_simple
    cd 2026-09-29-popgen_bonus_simple
    mkdir input results tmp
    touch WHATIDID.txt
    ```

    Link in the VCF file from the genotyping practical:

    ```
    ln -s ~/2026-09-29-genotyping/results/snp.vcf.gz input/
    ln -s ~/2026-09-29-genotyping/results/snp.vcf.gz.tbi input/
    ```

    If you do not have these files, use the backups in `/shared/data/backup_vcf`.

!!! Task
    Check PLINK 2 is available:

    ```
    plink2 --version
    ```

    You should see `PLINK v2.0.0-a.7.1LM` or similar.

Remember to record every command you run in `WHATIDID.txt`.

----------------------------------------------------------------------------

## **3. Challenge 1 - Load the Data Into PLINK 2**

PLINK 2 converts a VCF into its own fast binary format, called a **pfile**. A
pfile is three files that share a name:

* `.pgen` - the genotypes;
* `.pvar` - the list of SNPs;
* `.psam` - the list of samples.

### **3.1. Convert the VCF**

!!! Task
    Run this command. **It will fail** - that is on purpose.

    ```
    plink2 --vcf input/snp.vcf.gz --make-pgen --out tmp/snp
    ```

    Read the error message. What is PLINK complaining about? Add the flag it
    suggests and run the command again.

??? tip "Hint"
    PLINK expects human chromosome names such as `1`, `2` or `X`. Ours are called
    `scaffold_1` and `scaffold_2`. The error message tells you which flag allows
    other names. You will need that flag on **every** PLINK command today.

!!! Task
    Once it works, add two more flags that will make later steps easier:

    * `--set-all-var-ids '@:#'` gives every SNP a name made from its scaffold
      (`@`) and position (`#`), e.g. `scaffold_1:1043`. Our VCF has no SNP names.
    * `--max-alleles 2` keeps only SNPs with exactly two alleles.

??? example "Stuck? Worked command - Challenge 1a"
    ```
    plink2 \
      --vcf input/snp.vcf.gz \
      --allow-extra-chr \
      --set-all-var-ids '@:#' \
      --max-alleles 2 \
      --make-pgen \
      --out tmp/snp
    ```

!!! Task
    Look at what you made:

    ```
    ls tmp/
    grep -v '^##' tmp/snp.pvar | head -n 5
    cat tmp/snp.psam
    ```

    The `.pvar` file starts with many lines beginning `##` copied from the VCF
    header. `grep -v '^##'` hides them so you can see the SNPs.

!!! Question

    === "Question"

        * How many SNPs and how many samples did PLINK load? (Look at the screen
          output or `tmp/snp.log`.)
        * What are the sample names in `tmp/snp.psam`?

    === "Answer"

        * 1,859 SNPs and 14 samples (with the backup VCF).
        * The names are the original BAM file names, e.g. `f1_B.bam` and `f1b.bam`.
          Samples with `_B` in the name are *B*; the others are *b*.

### **3.2. Tell PLINK which sample belongs to which group**

PLINK does not know which samples are *B* and which are *b*. We tell it with a
**population file**: one line per sample, giving its name and its group.

!!! Task
    Create `tmp/populations.tsv` with the following two commands. The first writes
    the header line; the second adds one line per sample.

    ```
    printf '#IID\tPOP\n' > tmp/populations.tsv
    awk 'NR > 1 { if ($1 ~ /_B/) print $1 "\tB"; else print $1 "\tb" }' tmp/snp.psam >> tmp/populations.tsv
    ```

    Check the result:

    ```
    cat tmp/populations.tsv
    ```

!!! Question

    === "Question"

        What does each part of the `awk` command do?

    === "Answer"

        * `NR > 1` skips the first line of `tmp/snp.psam` (its header).
        * `$1` is the first column: the sample name.
        * `$1 ~ /_B/` checks whether the name contains `_B`.
        * If it does, `awk` prints the name, a tab (`\t`) and `B`; otherwise it
          prints the name, a tab and `b`.
        * `>>` **appends** to the file, so the header written by `printf` is kept.
          A single `>` would have overwritten it.

----------------------------------------------------------------------------

## **4. Challenge 2 - Genetic Differentiation (FST)**

**FST** measures how different two groups are at each SNP:

* **FST = 0** - both groups have the same allele frequencies;
* **FST = 1** - the groups share no alleles at all: every *B* carries one
  allele and every *b* carries the other. This is called a **fixed difference**.

In Part 5 you calculated FST in *R*. Now you will do it with PLINK.

### **4.1. Calculate FST for every SNP**

!!! Task
    Calculate FST between *B* and *b* for every SNP, and save the results with the
    prefix `results/fst`. You need to:

    * load your population file;
    * tell PLINK which column holds the groups (`POP`);
    * ask for the **Hudson** method, which works best with small groups;
    * ask for one result **per SNP**, not just an overall average.

??? tip "Hints"
    The flags you need are `--pheno`, `--pheno-name` and `--fst`. Run
    `plink2 --help fst` and look for the modifiers `method=hudson` and
    `report-variants`.

??? example "Stuck? Worked command - Challenge 2a"
    ```
    plink2 \
      --pfile tmp/snp \
      --allow-extra-chr \
      --pheno tmp/populations.tsv \
      --pheno-name POP \
      --fst POP method=hudson report-variants \
      --out results/fst
    ```

!!! Task
    Find out what PLINK wrote, then look at the files:

    ```
    ls results/
    cat results/fst.fst.summary
    head results/fst.B.b.fst.var
    ```

    `fst.fst.summary` holds one FST value for the whole dataset.
    `fst.B.b.fst.var` holds one FST value per SNP.

### **4.2. Compare the two scaffolds**

One number for the whole genome hides where the differences are. Let's compare
the two scaffolds.

!!! Task
    First, find which **column number** holds the FST value. This command lists
    the column names of the header, one per line, numbered:

    ```
    head -n 1 results/fst.B.b.fst.var | tr '\t' '\n' | cat -n
    ```

    Save that number in a shell variable so you do not have to type it again. The
    command below finds it for you automatically:

    ```
    FST_COL=$(head -n 1 results/fst.B.b.fst.var | tr '\t' '\n' | grep -n 'FST$' | cut -d: -f1)
    echo "FST is in column $FST_COL"
    ```

!!! Task
    Now list the **10 SNPs with the highest FST**. Which scaffold are they on?

??? tip "Hint"
    `sort -k5,5gr` sorts by column 5, as numbers (`g`), largest first (`r`).
    Replace `5` with `$FST_COL`.

??? example "Stuck? Worked command - Challenge 2b"
    ```
    sort -k${FST_COL},${FST_COL}gr results/fst.B.b.fst.var | head -n 10
    ```

!!! Task
    Finally, for **each scaffold**, calculate the number of SNPs, their mean FST, and
    how many SNPs are fixed differences (FST of 0.99 or more).

??? tip "Hint"
    Use a `for` loop over `scaffold_1 scaffold_2`. Inside it, `awk` can keep only
    the lines where column 1 equals the scaffold name, and add up the FST column.

??? example "Stuck? Worked command - Challenge 2c"
    ```
    for sc in scaffold_1 scaffold_2; do
      awk -v sc="$sc" -v c="$FST_COL" '
        $1 == sc && $c != "nan" { n++; sum += $c; if ($c >= 0.99) fixed++ }
        END { print sc, "- SNPs:", n, "- mean FST:", sum/n, "- fixed differences:", fixed+0 }
      ' results/fst.B.b.fst.var
    done
    ```

    How it works:

    * `-v sc="$sc"` and `-v c="$FST_COL"` pass the shell variables into `awk`.
    * `$1 == sc` keeps only lines for the current scaffold (this also skips the
      header, which starts with `#CHROM`).
    * `sum += $c` adds up the FST column; `n++` counts the SNPs.
    * The `END` block runs once at the end and prints the results.

!!! Task
    Now look at the **5 lowest** FST values. Remove the `r` from the `sort`
    command so it sorts smallest first, and use `grep -v '^#'` to drop the header
    line (otherwise it would be sorted to the top):

    ```
    grep -v '^#' results/fst.B.b.fst.var | sort -k${FST_COL},${FST_COL}g | head -n 5
    ```

!!! Question

    === "Question"

        * Which scaffold are the top 10 SNPs on?
        * Which scaffold has the higher mean FST? How many fixed differences does
          each scaffold have?
        * What is the lowest FST value you found, and on which scaffold? How can
          FST be **below 0**, when it is meant to range from 0 to 1?
        * *B* and *b* differ at a **supergene**: a block of genes that is
          inherited as one unit. Which scaffold carries it?

    === "Answer"

        * All of them are on `scaffold_1`, and all have FST = 1.
        * `scaffold_1` has a mean FST of about 0.67 and **524** fixed differences -
          about half of its 1,106 SNPs. `scaffold_2` has a mean FST of about 0.01
          and **no** fixed differences.
        * The lowest value is about **-0.077**, on `scaffold_2`. FST is an
          *estimate*: the Hudson method corrects for the small number of samples,
          and with only 7 per group that correction can push the estimate slightly
          below 0 when the true value is 0. Treat values at or just below 0 as
          "no difference".
        * `scaffold_1`. Hundreds of SNPs where every *B* differs from every *b*
          are what you expect if the two groups carry different versions of a
          supergene. `scaffold_2` behaves like an ordinary chromosome.

----------------------------------------------------------------------------

## **5. Challenge 3 - Linkage Disequilibrium**

**Linkage disequilibrium (LD)** measures how strongly the alleles at two SNPs are
associated, using a value called **r²**:

* **r² = 1** - knowing the allele at one SNP tells you the allele at the other;
* **r² = 0** - the two SNPs are independent.

On a normal chromosome, **recombination** shuffles alleles every generation, so
SNPs far apart become independent (low r²). A supergene is protected from
recombination: the whole block is inherited in one piece, so r² stays **high even
for SNPs far apart**.

This is something you did *not* test in Part 5.

### **5.1. Calculate r² on each scaffold**

!!! Task
    For each scaffold separately, calculate r² between pairs of SNPs, and save the
    results as `results/ld_scaffold_1` and `results/ld_scaffold_2`.

    Use the command below. Before running it, read what each flag does.

    ```
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
    ```

    | Flag | What it does |
    | :--- | :--- |
    | `--chr "$sc"` | uses only one scaffold |
    | `--maf 0.14` | drops rare SNPs (seen in fewer than 2 of the 14 samples), which give misleading r² values |
    | `--r2-unphased` | calculates r² between pairs of SNPs |
    | `--ld-window 100000` and `--ld-window-kb 1000` | compares SNPs up to 100,000 SNPs or 1,000 kb apart - i.e. across the whole scaffold |
    | `--ld-window-r2 0` | keeps **all** pairs; by default PLINK only reports pairs with high r² |

!!! Task
    Look at the output. Each line is one **pair** of SNPs:

    ```
    ls results/
    head results/ld_scaffold_1.vcor
    wc -l results/ld_scaffold_1.vcor results/ld_scaffold_2.vcor
    ```

### **5.2. Near pairs versus far pairs**

!!! Task
    For each scaffold, compare SNP pairs that are **close together** (less than
    10 kb apart) with pairs that are **far apart** (more than 100 kb apart). For
    both groups, report the mean r² and the proportion of pairs with r² of 0.8 or
    more.

    First, find the column numbers for the two positions and for r²:

    ```
    head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | cat -n

    POS_A_COL=$(head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | grep -n -x 'POS_A' | cut -d: -f1)
    POS_B_COL=$(head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | grep -n -x 'POS_B' | cut -d: -f1)
    R2_COL=$(head -n 1 results/ld_scaffold_1.vcor | tr '\t' '\n' | grep -n 'R2$' | cut -d: -f1)
    echo "POS_A: $POS_A_COL  POS_B: $POS_B_COL  R2: $R2_COL"
    ```

??? tip "Hint"
    The distance between two SNPs is `POS_B - POS_A`. Build on the `awk` command
    from Challenge 2: keep separate totals for near and far pairs.

??? example "Stuck? Worked command - Challenge 3"
    ```
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
    ```

!!! Question

    === "Question"

        * On `scaffold_2`, is r² higher for near pairs or for far pairs?
        * On `scaffold_1`, does r² drop between near and far pairs?
        * On which scaffold are more pairs in near-perfect LD (r² ≥ 0.8)?
        * Explain the difference using the word *recombination*.

    === "Answer"

        * On `scaffold_2`, near pairs have higher r² (about 0.36, with about 15% of
          pairs at r² ≥ 0.8) than far pairs (about 0.3, with under 10% at
          r² ≥ 0.8). Recombination has started to separate distant SNPs.
        * No. On `scaffold_1`, r² is about the same for near and far pairs (about
          0.58, with about a third of pairs at r² ≥ 0.8). SNPs 100 kb apart are just
          as strongly associated as SNPs next to each other.
        * `scaffold_1`, at every distance.
        * On an ordinary chromosome (`scaffold_2`), recombination breaks up
          combinations of alleles, and it does so more often for SNPs further apart,
          so r² falls with distance. On `scaffold_1`, recombination between the *B*
          and *b* versions is suppressed, so the whole region is inherited as one
          block and r² stays high regardless of distance. This is the defining
          property of a supergene.

!!! Warning
    With only 14 samples, r² values are noisy and generally too high - which is
    why even `scaffold_2` never drops close to 0. PLINK's documentation recommends
    at least 50 samples for LD analysis. The *difference* between the two scaffolds
    is still clear, but you would need more samples to measure LD precisely.

----------------------------------------------------------------------------

## **6. Wrap-Up**

!!! Question

    === "Question"

        In two or three sentences, summarise what your PLINK results tell you about
        `scaffold_1` and `scaffold_2`.

    === "Answer"

        `scaffold_1` carries the supergene: *B* and *b* are strongly differentiated
        (high FST, hundreds of fixed differences) and SNPs remain in strong LD
        across the whole scaffold because recombination is suppressed.
        `scaffold_2` behaves like a normal chromosome: FST is close to zero, there
        are no fixed differences, and LD is lower and falls with distance.

!!! Info
    Finished early? Try the full
    [Part 6 (Bonus) - Population Genomics on the Command Line](pt-6-popgen_bonus.md),
    which adds a genetic relationship matrix, sliding-window FST and LD pruning.

### **Files you should have produced**

!!! terminal
    ```
    tmp/
    ├── snp.pgen / snp.pvar / snp.psam   # PLINK 2 pfile
    └── populations.tsv                  # sample -> B or b
    results/
    ├── fst.fst.summary                  # overall FST
    ├── fst.B.b.fst.var                  # FST per SNP
    ├── ld_scaffold_1.vcor               # r2 between SNP pairs, scaffold_1
    └── ld_scaffold_2.vcor               # r2 between SNP pairs, scaffold_2
    ```
