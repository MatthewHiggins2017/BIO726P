# **Part 5 - Population Genetics**

----------------------------------------------------------------------------

## **1. Introduction**

In this practical, we will use samples with two genotypes associated to two
distinct phenotypes. Our example assembly consists of two scaffolds from two
different chromosomes:

| Genotype label |  Phenotype description  |
| :------------: | :---------------------: |
|      *B*       |  *single-queen* colony  |
|      *b*       | *multiple-queen* colony |


The aim of our analysis is to test whether any parts of this assembly differ
between the individuals from these two groups (*B* and *b*).

In the first part, we will create genotype heatmaps and run Principal Component
Analysis (PCA). The PCA computation will be performed using **PLINK 2** and
the results plotted using a short **R** script.

In the second part, we will measure genetic differentiation (FST) between *B*
and *b* in sliding windows using **PLINK 2**, and nucleotide diversity (π) using
**VCFtools**. The results will again be visualised with a short R script.

!!! Info
      **All commands in this practical are run from the terminal. Short R plotting
      scripts are included where needed — you do not need prior R experience. Simply
      copy and paste each command block and focus on interpreting the results!**

----------------------------------------------------------------------------

## **2. Setting Up**

!!! Task
      As before, create a new directory for this practical (e.g.,
      `2025-09-30-population_genetics`) with the standard subdirectory structure and
      a `WHATIDID.txt` log file:

      ```bash
      mkdir 2025-09-30-population_genetics
      cd 2025-09-30-population_genetics
      mkdir input results tmp
      touch WHATIDID.txt
      ```

      Next, symlink the `snp.vcf.gz` and `snp.vcf.gz.tbi` files created in the
      previous practical to your `input/` directory.

      ```bash
      ln -s ~/2025-09-29-genotyping/results/snp.vcf.gz input/
      ln -s ~/2025-09-29-genotyping/results/snp.vcf.gz.tbi input/
      ```

      If you don't have these files, you can use the backup copies in
      `/shared/data/backup_vcf`.

      Once set up, the output of `tree` should look like this:

!!! terminal
      ```
      2025-09-30-population_genetics/
      ├── input
      │   ├── snp.vcf.gz -> ~/2025-09-29-genotyping/results/snp.vcf.gz
      │   └── snp.vcf.gz.tbi -> ~/2025-09-29-genotyping/results/snp.vcf.gz.tbi
      ├── results
      ├── tmp
      └── WHATIDID.txt
      ```

----------------------------------------------------------------------------

## **3. Extracting SNP Data**

Before running population genetic analyses, we need to extract the genotype
information from the VCF file into plain-text files that will be used by
downstream tools.

!!! Task
      Use `bcftools query` to extract the SNP genotype matrix and the list of
      sample names:

      ```bash
      # Extract genotype matrix: CHROM, POS, then one genotype column per sample
      bcftools query input/snp.vcf.gz -f '%CHROM\t%POS[\t%GT]\n' > ./tmp/snp_matrix.txt

      # Extract sample names (one per line, in the same order as the genotype columns)
      bcftools query -l input/snp.vcf.gz > ./tmp/sample_names.txt
      ```

      Inspect the resulting files once generated using either head / Nano / Vim! Can you figure out what the command did? 

!!! Info 

  `snp_matrix.txt` contains one row per SNP. The first two columns are the
  chromosome and position, followed by one genotype column per sample (0 = reference
  allele, 1 = alternative allele). `sample_names.txt` lists the 14 sample IDs in
  the same order as the columns.

!!! Question

      === "Question"

            * How many SNPs are in your dataset? (Hint: `wc -l snp_matrix.txt`)
            * How many samples do you have? (Hint: `wc -l sample_names.txt`)

      === "Answer"

            * The number of lines in `snp_matrix.txt` equals the number of SNPs.
            * You should have 14 samples (7 B and 7 b). This matches the number of
              BAM files used in the previous practical.

----------------------------------------------------------------------------

## **4. Building a Population File**

PLINK 2 requires a phenotype/population file to distinguish the two groups when
computing FST. We build this automatically from the sample names — any sample
whose ID contains an uppercase **B** is assigned to group B, all others are
assigned to group b.

!!! Task
      Create a file called `tmp/populations.tsv` by copying and pasting the
      following contents based on your `tmp/sample_names.txt` file:

      ```text
      #FID    IID         POP
      0       f1_B.bam    B
      0       f1b.bam     b
      0       f2_B.bam    B
      0       f2b.bam     b
      0       f3_B.bam    B
      0       f3b.bam     b
      0       f4_B.bam    B
      0       f4b.bam     b
      0       f5_B.bam    B
      0       f5b.bam     b
      0       f6_B.bam    B
      0       f6b.bam     b
      0       f7_B.bam    B
      0       f7b.bam     b
      ```

    `results/populations.tsv` is a three-column file containing a Family ID (FID,
    set to 0 for haploid data), the sample ID (IID), and the population label (B or b). 

!!! Task
      Inspect the file to confirm it looks correct:

      ```bash
      cat tmp/populations.tsv
      ```


!!! Task
    We will now create two per-population keep files. These are used later by VCFtools to restrict analyses to one group at a time. 

      ```
      # Create per-population keep-files for VCFtools (two-column IID IID format)
      awk 'NR>1 && $3=="B" { print $2"\t"$2 }' tmp/populations.tsv > tmp/keep_B.txt
      awk 'NR>1 && $3=="b" { print $2"\t"$2 }' tmp/populations.tsv > tmp/keep_b.txt
      ```

!!! Question

      === "Question"

        Can you understand what the AWK command is doing?

      === "Answer"
        * `NR>1` skips the header line (`#FID IID POP`) and processes only sample rows.
        * `$3=="B"` (or `$3=="b"`) keeps only rows where the population column (`POP`) matches that group.
        * `{ print $2"\t"$2 }` prints the sample ID column (`IID`, field 2) twice, separated by a tab.
        * This creates the two-column format expected by VCFtools `--keep` (FID and IID). Here we reuse IID in both columns.
        * `> tmp/keep_B.txt` and `> tmp/keep_b.txt` redirect the output into separate keep-files for each population.
        * Result: one file listing only B samples and one file listing only b samples, ready for per-population diversity analysis.


----------------------------------------------------------------------------

## **5. Converting VCF to PLINK 2 Format**

PLINK 2 works with its own binary file format (`.pgen` / `.psam` / `.pvar`).
We convert the VCF once and then use the resulting files for all subsequent
PLINK analyses.

!!! Task
      Convert the VCF to a PLINK 2 pfile:

      ```
      plink2 \
        --vcf input/snp.vcf.gz \
        --allow-extra-chr \
        --set-all-var-ids '@:#' \
        --max-alleles 2 \
        --make-pgen \
        --out tmp/snp
      ```

The key flags used here are:

* `--allow-extra-chr` — required because our scaffold names (e.g. `scaffold_1`)
  are not standard chromosome identifiers.

* `--set-all-var-ids '@:#'` — assigns variant IDs in the format `CHROM:POS`,
  since our VCF does not contain named SNP IDs.

* `--max-alleles 2` — retains only biallelic sites.

* `--make-pgen` — writes the PLINK 2 binary files (`.pgen`, `.psam`, `.pvar`).

!!! Question

      === "Question"

            * How many variants and samples were retained after conversion?
              (Check the PLINK 2 log output printed to the terminal)

      === "Answer"

            * The summary line printed by PLINK 2 reports the number of samples
              loaded and the number of variants written. The variant count should
              match the number of SNPs in `snp_matrix.txt`.

----------------------------------------------------------------------------

## **6. Principal Component Analysis (PCA)**

PCA summarises the genetic variation across all samples into a small number of
principal components (PCs). If B and b individuals are genetically distinct, we
expect them to separate into distinct clusters .

With newer PLINK 2 builds, PCA on small datasets (fewer than 50 samples) needs
an explicit allele-frequency file. We therefore generate frequencies once and
provide them with `--read-freq` in all PCA runs.

### **6.1 Running PCA with PLINK 2**

!!! Task
      First, generate allele frequencies from the full dataset:

      ```bash
      plink2 \
        --pfile tmp/snp \
        --allow-extra-chr \
        --freq \
        --out tmp/snp_freq
      ```

!!! Task
      Then run PCA on the whole dataset and separately for each scaffold:

      ```bash
      # Whole-genome PCA
      plink2 \
        --pfile tmp/snp \
        --read-freq tmp/snp_freq.afreq \
        --allow-extra-chr \
        --pca 10 \
        --out results/pca_all

      # Per-scaffold PCA
      for scaffold in scaffold_1 scaffold_2; do
        plink2 \
          --pfile tmp/snp \
          --read-freq tmp/snp_freq.afreq \
          --allow-extra-chr \
          --chr "$scaffold" \
          --pca 10 \
          --out "results/pca_${scaffold}"
      done
      ```

`--pca 10` computes the top 10 principal components. PLINK 2 produces two output
files per run:

* `.eigenvec` — the PC scores for each sample (one row per individual).
* `.eigenval` — the variance explained by each PC.

Running PCA separately for each scaffold lets us test whether the B/b separation
is driven by one chromosome rather than the whole genome.

### **6.2 Visualising PCA with R**

!!! Task
      Run the following R script to read the PLINK 2 output and generate PCA plots. Please do not worry about understanding the full block of R code below, we have included it here as a means of generating the PCA plot necessary for you to interpret. 

      **Problem - these scripts need to be run in RStudio as R not accessible via terminal for some reason. This creates additional hassle. In future switch this to be python based and ask Vit to install matplotlib**

      ```
      Rscript - <<'REOF'
      suppressPackageStartupMessages(library(ggplot2))

      for (tag in c("all", "scaffold_1", "scaffold_2")) {
        vec_f <- paste0("results/pca_", tag, ".eigenvec")
        val_f <- paste0("results/pca_", tag, ".eigenval")
        if (!file.exists(vec_f)) next

        # PLINK 2 eigenvec header: #FID IID PC1 PC2 ...
        ev  <- read.table(vec_f, header = TRUE, check.names = FALSE)
        val <- scan(val_f, quiet = TRUE)
        pct <- round(val / sum(val) * 100, 1)
        ev$POP <- ifelse(grepl("B", ev[[2]]), "B", "b")   # col 2 = IID

        p <- ggplot(ev, aes(.data[["PC1"]], .data[["PC2"]], colour = POP)) +
          geom_point(size = 3) +
          xlab(paste0("PC1 (", pct[1], "%)")) +
          ylab(paste0("PC2 (", pct[2], "%)")) +
          ggtitle(paste("PCA -", tag)) +
          theme_minimal() + coord_fixed()

        ggsave(paste0("results/pca_", tag, ".png"), p, width = 6, height = 5, dpi = 150)
      }
      REOF
      ```

The script reads the `.eigenvec` and `.eigenval` files, colours each point by
population (B or b), and saves a PNG image to `results/`. The percentage of
variance explained is automatically added to each axis label.

!!! Question

      === "Question"

            * Do B and b individuals separate along PC1 in the whole-genome PCA?
            * Which scaffold is responsible for the separation between B and b?
            * What does it mean if one scaffold separates B from b but the other
              does not?

      === "Answer"

            * B and b should clearly separate along PC1 in the whole-genome PCA.
            * scaffold_2 should drive the B/b separation; scaffold_1 should show
              little or no separation between groups.
            * It indicates that the genetic differences between B and b are
              concentrated on scaffold_2 — the chromosome carrying the supergene —
              while scaffold_1 (from a different chromosome) segregates
              independently of colony type.

----------------------------------------------------------------------------

## **7. Genotype Heatmaps**

A genotype heatmap shows the raw genotype of each individual (rows) at each SNP
position (columns). This gives a visual overview of how consistently the alleles
differ between the B and b groups across the genome.

!!! Task
      Run the following R script to generate heatmaps for the whole genome and
      each scaffold individually:

      ```bash
      Rscript - <<'REOF'
      suppressPackageStartupMessages(library(adegenet))

      snp_data     <- read.table("snp_matrix.txt")
      sample_names <- gsub("\\.bam$", "", readLines("sample_names.txt"))
      loci         <- snp_data[, 1:2]
      snp_mat      <- t(snp_data[, 3:ncol(snp_data)])
      row.names(snp_mat) <- sample_names

      bb <- sample_names[grep("B", sample_names)]   # B group
      lb <- sample_names[grep("b", sample_names)]   # b group
      snp_mat <- snp_mat[c(bb, lb), ]

      gl <- new("genlight", snp_mat,
                chromosome = loci[, 1], position = loci[, 2],
                pop = as.factor(c(rep("B", length(bb)), rep("b", length(lb)))))

      for (sc in c("all", "scaffold_1", "scaffold_2")) {
        obj <- if (sc == "all") gl else gl[, which(gl@chromosome == sc)]
        png(paste0("results/heatmap_", sc, ".png"), width = 1000, height = 500)
        glPlot(obj, main = paste("Genotype heatmap -", sc))
        dev.off()
      }
      REOF
      ```

In the heatmap, each row is a sample and each column is a SNP. Light cells
indicate the reference allele (0) and dark cells indicate the alternative allele
(1). Samples are ordered with all B individuals at the top and all b individuals
at the bottom, making group-level patterns easy to see.

!!! Question

      === "Question"

            * In the whole-genome heatmap, is the genotype difference between B
              and b consistent across the entire genome?
            * Compare the `heatmap_scaffold_1.png` and `heatmap_scaffold_2.png`
              images. What do you observe?

      === "Answer"

            * No — the B/b genotype difference is clearly visible in one scaffold
              but not the other.
            * scaffold_2 shows a strong block-like pattern where B and b carry
              consistently different alleles across most SNP positions. scaffold_1
              shows no such pattern, with alleles appearing mixed between B and b
              individuals.

----------------------------------------------------------------------------

## **8. Measuring Genetic Differentiation (FST)**

FST (the fixation index) measures the degree of genetic differentiation between
two populations. FST = 0 means the two groups are genetically identical at that
position; FST = 1 means they are completely differentiated. We calculate FST in
10 kb sliding windows to identify which regions of the genome show the strongest
B/b differentiation.

### **8.1 Windowed FST with PLINK 2**

!!! Task
      Calculate FST in 10 kb non-overlapping windows across the genome:

      ```bash
      plink2 \
        --pfile results/snp \
        --allow-extra-chr \
        --pheno results/populations.tsv \
        --pheno-name POP \
        --fst POP \
        --fst-window-size 10000 \
        --fst-window-bp-step 10000 \
        --out results/fst
      ```

* `--pheno` and `--pheno-name POP` tell PLINK 2 to use the `POP` column in our
  population file to define the two groups (B and b).
* `--fst-window-size 10000` sets each window to 10,000 bp.
* `--fst-window-bp-step 10000` moves the window forward by 10,000 bp, producing
  non-overlapping windows.

PLINK 2 writes a `.fst.summary` file with columns: `#CHROM`, `BIN_START`,
`BIN_END`, `OBS_CT` (number of SNPs in the window), and `FST`.

!!! Task
      Inspect the output file to see what it looks like:

      ```bash
      # The filename includes the two population labels, e.g. fst.B.b.fst.summary
      ls results/fst*
      head results/fst.B.b.fst.summary
      ```

### **8.2 Visualising FST**

!!! Task
      Plot the windowed FST values across both scaffolds:

      ```bash
      Rscript - <<'REOF'
      suppressPackageStartupMessages(library(ggplot2))

      fst_file <- Sys.glob("results/fst.*.fst.summary")[1]
      fst <- read.table(fst_file, header = TRUE, comment.char = "")
      colnames(fst)[1] <- "CHROM"
      fst$MID <- (fst$BIN_START + fst$BIN_END) / 2

      p <- ggplot(fst, aes(MID, FST, colour = CHROM)) +
        geom_point(size = 1.5) +
        facet_wrap(~ CHROM, scales = "free_x") +
        xlab("Genomic position (bp)") + ylab("FST") +
        ggtitle("Windowed FST - B vs b (10 kb windows)") +
        theme_minimal() + theme(legend.position = "none")
      ggsave("results/fst_windows.png", p, width = 10, height = 4, dpi = 150)
      REOF
      ```

The script reads the PLINK 2 FST output, calculates the midpoint of each window,
and produces a scatter plot faceted by scaffold. Each point represents the FST
value in one 10 kb window.

!!! Question

      === "Question"

            * Which scaffold shows consistently high FST?
            * Knowing that B and b do not recombine with each other in one region
              of the genome, why do you think FST is high in one scaffold but not
              the other?

      === "Answer"

            * scaffold_2 should show high FST, while scaffold_1 should show values
              close to 0.
            * The scaffold_2 region corresponds to the supergene — because B and b
              do not recombine here, the two haplotypes have accumulated many fixed
              differences over time (high FST). scaffold_1 is outside the supergene
              and recombines freely, so alleles are shared between B and b
              individuals (low FST).

----------------------------------------------------------------------------

## **9. Measuring Nucleotide Diversity**

Nucleotide diversity (π) measures the average number of nucleotide differences
between pairs of individuals *within* a population. Low π can indicate a recent
population bottleneck or a selective sweep — events that reduce the amount of
genetic variation within a group.

### **9.1 Per-window π with VCFtools**

!!! Task
      Calculate nucleotide diversity in 10 kb windows separately for the B and b
      groups:

      ```bash
      for pop in B b; do
        vcftools \
          --gzvcf input/snp.vcf.gz \
          --keep "results/keep_${pop}.txt" \
          --window-pi 10000 \
          --out "results/diversity_${pop}"
      done
      ```

* `--keep` restricts the analysis to only the samples listed in the given file,
  so each run analyses one population at a time.
* `--window-pi 10000` computes π across non-overlapping 10 kb windows.

VCFtools outputs a `.windowed.pi` file with columns: `CHROM`, `BIN_START`,
`BIN_END`, `N_VARIANTS`, and `PI`.

### **9.2 Visualising Nucleotide Diversity**

!!! Task
      Plot the per-window diversity for both populations:

      ```bash
      Rscript - <<'REOF'
      suppressPackageStartupMessages(library(ggplot2))

      for (pop in c("B", "b")) {
        f <- paste0("results/diversity_", pop, ".windowed.pi")
        if (!file.exists(f)) next
        d <- read.table(f, header = TRUE)
        d$MID <- (d$BIN_START + d$BIN_END) / 2
        p <- ggplot(d, aes(MID, PI, colour = CHROM)) +
          geom_point(size = 1.5) +
          facet_wrap(~ CHROM, scales = "free_x") +
          xlab("Genomic position (bp)") + ylab("Nucleotide diversity (pi)") +
          ggtitle(paste("Nucleotide diversity -", pop, "group (10 kb windows)")) +
          theme_minimal() + theme(legend.position = "none")
        ggsave(paste0("results/diversity_", pop, ".png"), p, width = 10, height = 4, dpi = 150)
      }
      REOF
      ```

The script loops over both populations, reads their `.windowed.pi` files, and
saves a plot for each to `results/`.

!!! Question

      === "Question"

            * Compare the nucleotide diversity of the B and b groups in each
              scaffold. Which group has lower diversity in scaffold_2?
            * What evolutionary processes could explain very low nucleotide diversity
              within the b group in scaffold_2?

      === "Answer"

            * The b group should show much lower nucleotide diversity in scaffold_2
              compared to the B group.
            * The b supergene haplotype has accumulated very little genetic variation.
              This is consistent with a selective sweep — if the b haplotype spread
              rapidly through the population at some point in the past, it would
              carry very little standing diversity. The complete absence of
              recombination on the b haplotype also means variation cannot be
              reshuffled, so diversity remains low.

----------------------------------------------------------------------------

## **10. Summary of Output Files**

Once all steps are complete, your `results/` directory should contain the
following key files:

!!! terminal
      ```
      results/
      ├── populations.tsv             # Population assignments (B/b)
      ├── keep_B.txt                  # Sample list for B group (VCFtools format)
      ├── keep_b.txt                  # Sample list for b group (VCFtools format)
      ├── snp.pgen / .psam / .pvar    # PLINK 2 binary genotype files
      ├── pca_all.eigenvec / .eigenval
      ├── pca_scaffold_1.eigenvec / .eigenval
      ├── pca_scaffold_2.eigenvec / .eigenval
      ├── fst.B.b.fst.summary         # Windowed FST values (PLINK 2)
      ├── diversity_B.windowed.pi     # Per-window pi - B group (VCFtools)
      ├── diversity_b.windowed.pi     # Per-window pi - b group (VCFtools)
      ├── heatmap_all.png
      ├── heatmap_scaffold_1.png
      ├── heatmap_scaffold_2.png
      ├── pca_all.png
      ├── pca_scaffold_1.png
      ├── pca_scaffold_2.png
      ├── fst_windows.png
      ├── diversity_B.png
      └── diversity_b.png
      ```
