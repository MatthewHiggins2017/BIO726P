# Part 6: Using the Teaching Cluster

------------------------

This practical introduces the QMUL Teaching Cluster and uses it to run some structural variant analysis using **Nanopore data** from ***Plasmodium falciparum***. The focus is not just on running a few commands, but on understanding how to set up a fresh compute environment, install software reproducibly, organise a project, and automate your analysis with some bash scripting!

Before starting this practical, you should have finished all prior practicals!

------------------------

# 1. Overview and Aims

By the end of this practical, you should be able to:

1. Access and use the Teaching Cluster through your web browser.
2. Understand what Conda environments are and why they are useful.
3. Install bioinformatics software from `conda-forge` and `bioconda`.
4. Source and download reference and sequencing data using the command line.
5. Run a structural variant analysis workflow.
6. Create you workflow as a reusable bash script.

------------------------

# 2. Accessing the Teaching Cluster

The Teaching Cluster provides a remote Linux environment that you can access through your browser. It is a JupyterHub-based system, which means each user launches their own Jupyter server. By default, this opens as a JupyterLab session, but from there you can also open other tools and work across multiple tabs. Each server type provides access to a defined set of shared compute resources. For this practical, you should use **SBBS MSc Projects (CPU)**, which provides **32 CPU cores** and **32 GB RAM**.

!!! Task
    Go to [https://hub.comp-teach.qmul.ac.uk/](https://hub.comp-teach.qmul.ac.uk/) and log in with your QMUL account.

    Use your QMUL username only, for example `abc123`.
    Do **not** add `@qmul.ac.uk`.

![TC 1](../img/Teaching_Cluster_Login.png)

!!! Task
    Once, logged in you will be taken to a page where you can select the instance you would like to use. For this scroll down to the bottom on the page and select the tab **Project Work**. This will provide several options, however you should select the option **SBBS MSc Projects (CPU)**. Once you have clicked on this option, scroll down to the bottom of the page and select **start**. 

![TC 2](../img/Teaching_Cluster_Instance_Selection.png)

![TC 3](../img/Teaching_Cluster_SBBS_MSc_Projects.png)

!!! Task
    Wait for the loading screen to finish. Starting server can take few seconds to few minutes (depends on the cluster use). 
![TC 5](../img/Teaching_Cluster_Instance_Loading.png)

!!! Task
    Once you image is up and running you will be presented the standard Jupyter Lab interface with Launcher open as shown in the next screenshot below:

![TC 6](../img/Teaching_Cluster_Instance_Homepage.png)

!!! Info
    Before opening the terminal, take a moment to understand the layout of the JupyterLab screen:

    * Across the **top** is the menu bar, where you can access options such as `File`, `Edit`, `View`, `Run`, and `Settings`.
    * On the **left-hand side** is the file browser. This is where you can navigate through your folders and files on the Teaching Cluster. In the screenshot, you can already see directories such as `Archive` and `docs`.
    * The **middle of the screen** is the main working area. Right now it is showing the **Launcher**, which gives you shortcuts to open tools such as a Notebook, Terminal, Text File, Markdown File, Python file, RStudio, Desktop, or VS Code.
    * Along the **top of the main panel** you will also see tabs. As you open files, terminals, or notebooks, each one appears as a new tab in this area.
    * The small icons in the **far left sidebar** give quick access to tools such as the file browser, running sessions, table of contents, or extensions.

    In this practical, the parts you will use most are the **file browser on the left** and the **terminal launcher tile in the centre**.

!!! Task
    Click on the **terminal icon** to open the terminal.  


![TC 7](../img/Teaching_Cluster_Terminal_Open.png)


------------------------

# 3. Creating your project directory

As in the previous practicals, start by making a well-organised working directory.

!!! Task
    Create a main directory for today's session, together with subdirectories for input data, reference files, intermediate files, final results, and your command log.

    For example:

    ```bash
    mkdir BIO726P_Teaching_Cluster
    cd BIO726P_Teaching_Cluster
    mkdir input references tmp results
    touch WHATIDID.txt
    ```

Your directory structure should look like this:

!!! terminal
    ```
    BIO726P_Teaching_Cluster
    ├── input
    ├── references
    ├── results
    ├── tmp
    └── WHATIDID.txt
    ```

------------------------

# 4. Package management with Conda

Most bioinformatics workflows depend on many external tools. Installing those tools manually can be difficult because different programs may require different versions of the same dependency.

[Conda](https://docs.conda.io/en/latest/) is a package and environment manager that helps solve this problem.

## 4.1 Why use Conda?

Conda allows you to:

* install software without admin access,
* keep project dependencies together in an isolated environment,
* avoid conflicts between tools required for different analyses,
* share software environments with other users.

The two channels you will commonly see in bioinformatics are:

* `conda-forge` for general-purpose scientific software,
* `bioconda` for bioinformatics software.

!!! Info
    A **channel** in Conda is a source (repository) of installable packages.

    When you run an install command, Conda searches the channels you specify and resolves package versions from them.

    In bioinformatics, we commonly combine `conda-forge` and `bioconda` because many bioinformatics tools in `bioconda` depend on shared libraries provided by `conda-forge`.

    Channel order matters: Conda resolves packages based on channel priority, so using a consistent channel setup helps avoid version conflicts and improves reproducibility.


!!! Info
    An **environment** is an isolated software space with its own installed packages and versions. Activating an environment changes which software your shell uses.

!!! Question

    === "Question"

        What kinds of problems can happen if you install many tools into one single base environment?

    === "Answer"

        Different tools may require incompatible versions of the same dependency. This can lead to installation failures, broken software, or commands behaving differently between projects.

!!! Task 
    Take a look through the conda sub-commands (e.g. conda export) and understand when you would use each of them! If you have any questions then please ask a demonstrator.


## 4.2 A note on alternatives

Conda is not the only way to install software.

Other common approaches include:

* `pip` for Python packages,
* system package managers such as `apt` or `brew`,
* containers such as Docker or Apptainer.

For this practical, Conda is the simplest way to build a user-controlled analysis environment. Later in your training you may encounter containers when you need stronger reproducibility or more complex software stacks.

------------------------

# 5. Creating a Conda environment for structural variant analysis

We will create an environment containing software for a small Nanopore-based structural variant workflow.

!!! Info 
    **Structural variants (SVs)** are larger genomic changes, usually affecting regions of around 50 base pairs or more.

    Common SV types include:

    * **Deletions (DEL):** sequence is missing relative to the reference.
    * **Insertions (INS):** extra sequence is present relative to the reference.
    * **Inversions (INV):** a region is reversed in orientation.
    * **Duplications (DUP):** a segment appears in extra copies.
    * **Translocations (BND/TRA):** sequence is rearranged between genomic locations.

    SVs can have major biological effects because they may disrupt genes, alter gene copy number, or change regulatory regions. Long Nanopore reads are particularly useful for this analysis because individual reads can span larger rearrangements that are often difficult to resolve with short-read data.


The tools we will use are:

| Tool | Purpose in this practical | GitHub repository | Conda package page |
|---|---|---|---|
| NanoPlot | Basic Nanopore read QC | [wdecoster/NanoPlot](https://github.com/wdecoster/NanoPlot) | [bioconda: nanoplot](https://bioconda.github.io/recipes/nanoplot/README.html) |
| chopper | Read filtering | [wdecoster/chopper](https://github.com/wdecoster/chopper) | [bioconda: chopper](https://bioconda.github.io/recipes/chopper/README.html) |
| minimap2 | Read mapping | [lh3/minimap2](https://github.com/lh3/minimap2) | [bioconda: minimap2](https://bioconda.github.io/recipes/minimap2/README.html) |
| samtools | Alignment file processing | [samtools/samtools](https://github.com/samtools/samtools) | [bioconda: samtools](https://bioconda.github.io/recipes/samtools/README.html) |
| sniffles | Structural variant calling | [fritzsedlazeck/Sniffles](https://github.com/fritzsedlazeck/Sniffles) | [bioconda: sniffles](https://bioconda.github.io/recipes/sniffles/README.html) |


!!! Task
    Test that Conda is available by running one of the following commands:

    ```bash
    conda
    # or
    conda --help
    ```

    Your terminal output should look similar to the example below.

![TC 9](../img/Teaching_Cluster_Running_Conda_Command.png)


!!! Task
    Create and activate a new Conda environment called `sv_nanopore`.

    You can either list the packages you want at creation time, as shown below, or create the environment first and install additional packages after it is active.

    ```bash
    conda create -n sv_nanopore -c conda-forge -c bioconda nanoplot chopper minimap2 samtools sniffles -y
    ```
    Now activate your new environment:

    ```bash 
    conda activate sv_nanopore
    ```


!!! Task
    Check that each tool is available:

    ```bash
    which NanoPlot
    which chopper
    which minimap2
    which samtools
    which sniffles
    ```

    Then check the versions:

    ```bash
    NanoPlot --version
    chopper --help
    minimap2 --version
    samtools --version
    sniffles --version
    ```

!!! Task
    When you are finished, test deactivating and reactivating the environment:

    ```bash
    conda deactivate
    conda activate sv_nanopore
    ```

!!! Question

    === "Question"

        Why is it important to test whether a package actually runs after installation?

    === "Answer"

        A package may install successfully but still fail at runtime if there is a path issue, a missing dependency, or confusion over which environment is active. A quick test confirms the tool is really available.


!!! Question

    === "Question"

        Based on the tools listed above and your understanding from previous practicals, what order should we run them in for structural variant analysis?

    === "Answer"

        1. NanoPlot (initial read QC)
        2. chopper (read filtering)
        3. minimap2 (read mapping)
        4. samtools (sorting and indexing alignments)
        5. sniffles (structural variant calling)

------------------------

# 6. Downloading the reference genome and annotation

We now need a reference genome for *Plasmodium falciparum* 3D7.

!!! Task
    Change into your `references` directory and download the genome FASTA file. 


    ```bash
    cd ~/BIO726P_Teaching_Cluster/references
    wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/765/GCF_000002765.6_GCA_000002765/GCF_000002765.6_GCA_000002765_genomic.fna.gz
    ```

    Decompress the FASTA file:

    ```bash
    gunzip GCF_000002765.6_GCA_000002765_genomic.fna.gz
    ```

    Inspect the FASTA file, does it match what you expect? 

    ```bash
    ls -lh
    grep "^>" GCF_000002765.6_GCA_000002765_genomic.fna | head
    ```


------------------------

# 7. Downloading & Uploading Example Nanopore data


!!! Task 
    You will need to download the sequence data from each sample directly from QMPlus. This can be done by clicking on the 'Plasmodium_falciparum_Sample_Data' folder and then selecting the `download folder` button as shown below. 

    ![Raw Data Download](../img/TC_Download_Data_From_QMPLus.png)

!!! Task 
    Next **upload the data to the Teaching Cluster** using the upload button as shown in the image below: 

    ![Data Upload](../img/TC_Upload_Data.png)

    Finally move the uploaded data into your `input` directory:

    ```bash
    mv Pf*.fastq.gz  ~/BIO726P_Teaching_Cluster/input

    ```


!!! Task
    Check the file exists and inspect the first read:

    ```bash
    ls -lh Pf_Sample_A.fastq.gz
    zcat Pf_Sample_A.fastq.gz | head
    ```

!!! Question

    === "Question"

        What are the four lines that make up one FASTQ record?

    === "Answer"

        A FASTQ record contains:
            - 1) A read header line beginning with `@`, 
            - 2) The nucleotide sequence, 
            - 3) A separator line usually containing `+`,
            - 4) A quality string with one character per base.

!!! Info
    In this session the FASTQ file is supplied for you. In a real project, data may come from public archives such as ENA, SRA, or institutional storage. **We will come back to this later in a bonus task**
------------------------

# 8. Part 1: Exploring the structural variant workflow step-by-step

In this first part, you will run each command manually so that you understand what every step is doing.

## 8.1 Quality control of the raw reads

!!! Task
    Change into your `tmp` directory and run NanoPlot on the raw FASTQ file:

    ```bash
    cd ~/BIO726P_Teaching_Cluster/tmp
    NanoPlot --fastq ../input/Pf_Sample_A.fastq.gz --outdir Pf_Sample_A_nanoplot_raw
    ```

!!! Task
    Inspect the output directory:

    ```bash
    ls Pf_Sample_A_nanoplot_raw
    ```

    The directory should contain the following files: 

    ```
    ls Pf_Sample_A_nanoplot_raw
    LengthvsQualityScatterPlot_dot.html
    LengthvsQualityScatterPlot_dot.png
    LengthvsQualityScatterPlot_kde.html
    LengthvsQualityScatterPlot_kde.png
    NanoPlot_20260804_0826.log
    NanoPlot-report.html
    NanoStats.txt
    Non_weightedHistogramReadlength.html
    Non_weightedHistogramReadlength.png
    Non_weightedLogTransformed_HistogramReadlength.html
    Non_weightedLogTransformed_HistogramReadlength.png
    WeightedHistogramReadlength.html
    WeightedHistogramReadlength.png
    WeightedLogTransformed_HistogramReadlength.html
    WeightedLogTransformed_HistogramReadlength.png
    Yield_By_Length.html
    Yield_By_Length.png

    ```

    Using the left-side bar, navigate to the directory and open the `NanoPlot-report.html`. **Note** - To view the figures you may have to click the Trust HTML button on top left side of the window. 
    


![NanoPlot_Image](../img/NanoPlot_Report.png)


!!! Task 

    Inspect the report to gauge the underlying quality of the nanopore sequencing data!

!!! Question

    === "Question"

        What kinds of features is NanoPlot useful for checking before alignment?

    === "Answer"

        It helps you inspect read-length distributions, quality-score distributions, total yield, and whether the dataset contains many short or low-quality reads.
    

## 8.2 Filter the reads

For many analyses, it is helpful to remove very short or very low-quality reads before alignment.

!!! Task
    Filter the reads using `chopper` and save the result as a gzipped FASTQ file.

    For this first round of filtering, use:

    * a minimum quality score of `10`
    * a minimum read length of `1000` bp

    Use `chopper -h` to work out which options you need. Then think back to previous practicals: if your input is compressed and you want the final output to stay compressed, what should your command pipeline include?

!!! Question

    === "Question"

        What `chopper` command would you use?

    === "Answer"

        ```
        zcat ../input/Pf_Sample_A.fastq.gz | chopper -q 10 -l 1000 | gzip > Pf_Sample_A_filtered_reads.fastq.gz
        ```

!!! Question

    === "Question"

        How many reads remained after filtering Pf_Sample_A?

    === "Answer"

        Kept 32939 reads out of 34084 reads



!!! Info
    Here, `-q 10` removes very low-quality reads and `-l 1000` keeps only reads that are at least 1000 bases long. The `zcat ... | ... | gzip` pattern decompresses the input on the fly and writes the filtered output back out as a compressed FASTQ file.

!!! Task
    Run NanoPlot again on the filtered reads. Inspect the output report, can you confirm that the filtering implemented by chopper was successful? 

    ```bash
    NanoPlot --fastq Pf_Sample_A_filtered_reads.fastq.gz --outdir Pf_Sample_A_nanoplot_filtered
    ```

!!! Question

    === "Question"

        Why might filtering improve downstream structural variant calling?

    === "Answer"

        Very short or poor-quality reads can map less reliably and may increase false-positive variant calls. Filtering can improve mapping quality and reduce noise.


!!! Question

    === "Question"

        What other metrics does Chopper allow you to filter on and when would you implement these? 

    === "Answer"

        In addition to minimum quality (`-q`) and minimum length (`-l`), `chopper` can filter on maximum quality (`--maxqual`), maximum read length (`--maxlength`), minimum and maximum GC content (`--mingc`, `--maxgc`), and contaminant sequence matching using a FASTA file (`--contam`).


## 8.3 Map reads to the reference

We will now align the filtered reads to the reference genome using `minimap2`.

!!! Task
    Run the alignment and write the output to SAM format:

    ```
    minimap2 -ax map-ont -t 10 ../references/GCF_000002765.6_GCA_000002765_genomic.fna Pf_Sample_A_filtered_reads.fastq.gz -o Pf_Sample_A.sam
    ```

!!! Info
    The `-ax map-ont` preset is designed for Oxford Nanopore reads. Using the `-h` sub-command, see what the `-t` parameter is used for!


!!! Task
    Convert the SAM file to a sorted BAM file and index it:

    ```bash
    samtools sort -O BAM Pf_Sample_A.sam > Pf_Sample_A.sorted.bam
    samtools index Pf_Sample_A.sorted.bam
    ```

!!! Task
    Generate a few simple alignment statistics:

    ```bash
    samtools flagstat Pf_Sample_A.sorted.bam
    samtools idxstats Pf_Sample_A.sorted.bam| head
    ```

!!! Question

    === "Question"

        How could you redirect the stdout of these commands to a file? 

    === "Answer"

        ```
        samtools flagstat Pf_Sample_A.sorted.bam > Pf_Sample_A.stats
        ```

!!! Question

    === "Question"

        Why do we usually work with sorted and indexed BAM files rather than raw SAM files?

    === "Answer"

        BAM files are compressed and therefore smaller than SAM files. Sorting and indexing also make downstream analyses faster because tools can efficiently access alignments by genomic position.

## 8.4 Call structural variants with Sniffles

!!! Task
    Run Sniffles on the sorted BAM file:

    ```bash
    sniffles --input Pf_Sample_A.sorted.bam --vcf Pf_Sample_A.sniffles.vcf
    ```

!!! Task
    Inspect the first few lines of the VCF:

    ```bash
    head Pf_Sample_A.sniffles.vcf
    ```


!!! Question

    === "Question"

        How many variants were called?

    === "Answer"

        Only a single deletion was identified:

        ```bash
        grep -vc "^#" Pf_Sample_A.sniffles.vcf
        ```


!!! Question

    === "Question"

        What is the difference between the header lines and the variant lines in a VCF file?

    === "Answer"

        Header lines begin with `#` and describe the file format, metadata, and column names. Variant lines contain the actual variant records.

------------------------

# 9. Interpreting the structural variants

Now that you have a structural variant call set, start thinking about biological interpretation.

For this dataset, Sniffles reported exactly one structural variant in `Pf_Sample_A.sniffles.vcf`.

!!! Task
    Confirm how many variant records are present (non-header lines):

    ```bash
    grep -vc "^#" Pf_Sample_A.sniffles.vcf
    ```

    Then print the variant record itself:

    ```bash
    grep -v "^#" Pf_Sample_A.sniffles.vcf
    ```

!!! Info
    Your output should contain one line similar to:

    ```
    NC_004331.3 2840727 Sniffles2.DEL.12SA N <DEL> 60 PASS PRECISE;SVTYPE=DEL;SVLEN=-975;END=2841702;SUPPORT=20;...;VAF=1.000 GT:GQ:DR:DV:PS 1/1:55:0:20:.
    ```

    This line tells us:

    * `SVTYPE=DEL`: the event is a deletion.
    * `CHROM=NC_004331.3`, `POS=2840727`, `END=2841702`: the deleted interval is on chromosome NC_004331.3 from 2,840,727 to 2,841,702.
    * `SVLEN=-975`: deletion length is 975 bp (negative sign indicates deletion).
    * `FILTER=PASS`: the call passed Sniffles filtering.
    * `QUAL=60`: high confidence score.
    * `SUPPORT=20`: 20 reads support the variant.
    * `VAF=1.000`: all informative reads support the variant allele.
    * `GT=1/1`, `DR=0`, `DV=20`: genotype is homozygous alternate in this sample, with 0 reference reads and 20 variant reads.


!!! Question

    === "Question"

        Based on this VCF, what is the main structural variant call in Pf_Sample_A?

    === "Answer"

        A single, high-confidence 975 bp deletion on chromosome `NC_004331.3` from 2,840,727 to 2,841,702.

        The call is supported by 20 reads, has `FILTER=PASS`, and is genotyped as `1/1` (homozygous alternate) in this sample.


!!! Question

    === "Question"

        Why is it not enough to simply observe that Sniffles reported a deletion?

    === "Answer"

        Variant callers make predictions from read evidence, but those predictions still need interpretation.

        You should evaluate read support, breakpoint precision, coverage context, and whether the event overlaps biologically meaningful features such as genes.

!!! Question

    === "Question"

        What extra information would help you decide whether this deletion is likely to be real?

    === "Answer"

        Useful evidence includes consistent support in replicate samples, local inspection in a genome browser (for split-read and mapping pattern checks), read depth changes around the event, and whether the region is repetitive or difficult to map.


!!! Task

    If you have access to a GFF/GTF annotation file, you can test whether this structural variant overlaps genes of interest.

    As in Section 6, check the NCBI assembly page for the reference used in this practical:
    https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/765/GCF_000002765.6_GCA_000002765/

    If a GFF file is available, download it with `wget`.

    Then run a simple coordinate-overlap check with `awk`:

    ```
    awk -F'\t' '$1=="CONTIG_NAME" && $4<=START_POS && $5>=END_POS' Pf3D7_annotation.gff | head

    # Example

    awk -F'\t' '$1=="NC_004331.3" && $4<=2841000 && $5>=2840727' Pf3D7_annotation.gff | head
    ```


------------------------

# 10. Part 2: Turning the workflow into a bash script

Running commands manually is useful for learning, but it does not scale well. A script makes your workflow easier to rerun, easier to share, and easier to adapt when you want to analyse another sample or repeat the same workflow later.

In practice, a script does two important jobs:

* it records the exact commands you used, so you do not need to rely on memory or terminal history,
* it keeps repeated setup steps, file paths, and output names in one place, which reduces mistakes when you rerun the analysis.

You have already run the full workflow manually for `Pf_Sample_A.fastq.gz`.

Now the goal is to automate the same analysis for `Pf_Sample_B.fastq.gz` and `Pf_Sample_C.fastq.gz`.

The first version of the script below automates only the early preprocessing steps (QC and filtering) for both samples. That is deliberate: it lets you confirm your file paths, loop logic, and environment before adding mapping and variant calling.

## 10.1 Create your first analysis script

!!! Task
    Return to your main project directory and create a script called `run_sv_analysis.sh`:

    ```
    cd ~/BIO726P_Teaching_Cluster
    nano run_sv_analysis.sh
    ```

    Add the following script:

    ```
    #!/usr/bin/env bash
    set -euo pipefail

    PROJECT_DIR="$HOME/BIO726P_Teaching_Cluster"
    INPUT_DIR="$PROJECT_DIR/input"
    REFERENCE="$PROJECT_DIR/references/GCF_000002765.6_GCA_000002765_genomic.fna"
    TMP_DIR="$PROJECT_DIR/tmp/"
    RESULTS_DIR="$PROJECT_DIR/results"
    SAMPLES=("Pf_Sample_B" "Pf_Sample_C")

    mkdir -p "$TMP_DIR" "$RESULTS_DIR"

    for SAMPLE in "${SAMPLES[@]}"; do
        INPUT_FASTQ="$INPUT_DIR/${SAMPLE}.fastq.gz"
        SAMPLE_TMP_DIR="$TMP_DIR/${SAMPLE}"

        mkdir -p "$SAMPLE_TMP_DIR"

        NanoPlot --fastq "$INPUT_FASTQ" --outdir "$SAMPLE_TMP_DIR/nanoplot_raw"

        zcat "$INPUT_FASTQ" | chopper -q 10 -l 1000 | gzip > "$SAMPLE_TMP_DIR/${SAMPLE}.filtered.fastq.gz"

        NanoPlot --fastq "$SAMPLE_TMP_DIR/${SAMPLE}.filtered.fastq.gz" --outdir "$SAMPLE_TMP_DIR/nanoplot_filtered"
    done
    ```

!!! Info
    At the top of the script you will see:

    ```
    #!/usr/bin/env bash
    set -euo pipefail
    ```

    These lines make the script safer and more reproducible:

    * `#!/usr/bin/env bash` is the **shebang**. It tells the system to run this file using `bash`.
    * `set -e` makes the script stop immediately if a command fails.
    * `set -u` treats use of an undefined variable as an error.
    * `set -o pipefail` makes a pipeline fail if any command in that pipeline fails (not just the last one).

    Together, these settings help you catch mistakes early instead of silently producing incomplete or misleading output.

!!! Task
    Inspect the commands in this file. What steps of your analysis pipeline is it running, and which pieces are still left out?

    The variable names at the top make the script easier to read and update:

    * `PROJECT_DIR` stores the main project path in one place.
    * `INPUT_DIR` and `REFERENCE` point to the data files used by the workflow.
    * `TMP_DIR` and `RESULTS_DIR` separate temporary working files from final outputs.
    * `SAMPLES` defines which samples are processed, so you can scale the workflow by editing one line.

    The loop then runs two early-stage checks for each sample:

    * `NanoPlot` on the original FASTQ file for an initial quality-control summary,
    * `chopper` to filter out short or low-quality reads,
    * `NanoPlot` again on the filtered reads so you can see how the dataset changed after filtering.

    In other words, this version covers preprocessing and quality control for `Pf_Sample_B` and `Pf_Sample_C`, but it does not yet map reads or call structural variants.

    Save the file, then make it executable and run it once to see the intermediate output:

    ```bash
    chmod +x run_sv_analysis.sh
    ./run_sv_analysis.sh
    ```

!!! Question

    === "Question"

        Now extend the script so it also carries out the mapping, sorting, indexing, and structural variant calling steps for both samples. What would the full version look like?

    === "Answer"

        ```
        #!/usr/bin/env bash
        set -euo pipefail

        PROJECT_DIR="$HOME/BIO726P_Teaching_Cluster"
        INPUT_DIR="$PROJECT_DIR/input"
        REFERENCE="$PROJECT_DIR/references/GCF_000002765.6_GCA_000002765_genomic.fna"
        TMP_DIR="$PROJECT_DIR/tmp/"
        RESULTS_DIR="$PROJECT_DIR/results"
        SAMPLES=("Pf_Sample_B" "Pf_Sample_C")

        mkdir -p "$TMP_DIR" "$RESULTS_DIR"

        for SAMPLE in "${SAMPLES[@]}"; do
            INPUT_FASTQ="$INPUT_DIR/${SAMPLE}.fastq.gz"
            SAMPLE_TMP_DIR="$TMP_DIR/${SAMPLE}"

            mkdir -p "$SAMPLE_TMP_DIR"

            NanoPlot --fastq "$INPUT_FASTQ" --outdir "$SAMPLE_TMP_DIR/nanoplot_raw"

            zcat "$INPUT_FASTQ" | chopper -q 10 -l 1000 | gzip > "$SAMPLE_TMP_DIR/${SAMPLE}.filtered.fastq.gz"

            NanoPlot --fastq "$SAMPLE_TMP_DIR/${SAMPLE}.filtered.fastq.gz" --outdir "$SAMPLE_TMP_DIR/nanoplot_filtered"

            minimap2 -ax map-ont -t 10 "$REFERENCE" "$SAMPLE_TMP_DIR/${SAMPLE}.filtered.fastq.gz" > "$SAMPLE_TMP_DIR/${SAMPLE}.sam"

            samtools sort -O BAM "$SAMPLE_TMP_DIR/${SAMPLE}.sam" > "$SAMPLE_TMP_DIR/${SAMPLE}.sorted.bam"
            samtools index "$SAMPLE_TMP_DIR/${SAMPLE}.sorted.bam"

            samtools flagstat "$SAMPLE_TMP_DIR/${SAMPLE}.sorted.bam" > "$RESULTS_DIR/${SAMPLE}.flagstat.txt"

            sniffles --input "$SAMPLE_TMP_DIR/${SAMPLE}.sorted.bam" --vcf "$RESULTS_DIR/${SAMPLE}.sniffles.vcf"
        done
        ```


## 10.2 Comparing SV across Samples A, B & C


!!! Task 

    Inspect the structural variants identified across samples A, B, and C.

    Are any of the deletions similar between samples? Do any of them affect the same genes? If so, what biological phenotype might you expect?


!!! Question

    === "Question"

        Click here for answers to Task 10.2

    === "Answer"

        Comparing the three samples suggests the following pattern:

        * `Pf_Sample_A` contains a deletion affecting **histidine-rich protein III** (`hrp3`, `PF3D7_1372200`) on `NC_004331.3`.
        * `Pf_Sample_C` contains deletions affecting both **histidine-rich protein II** (`hrp2`, `PF3D7_0831800`) on `NC_004329.3` and **histidine-rich protein III** (`hrp3`, `PF3D7_1372200`) on `NC_004331.3`.
        * `Pf_Sample_B` does not show either of these deletions and can be treated as the comparison sample here.

        So, yes: some of the deletions are similar across samples because both `Pf_Sample_A` and `Pf_Sample_C` show loss of `hrp3`.

        The two relevant deleted regions are:

        * `NC_004329.3:1374236-1375299` overlapping **histidine-rich protein II** (`PF3D7_0831800`)
        * `NC_004331.3:2840727-2841703` overlapping **histidine-rich protein III** (`PF3D7_1372200`)

        A likely biological and clinical consequence is altered performance of **HRP2-based malaria rapid diagnostic tests (RDTs)**.

        Parasites with an `hrp2` deletion, especially when `hrp3` is also deleted, may be more difficult to detect with HRP2-based RDTs and can sometimes produce **false-negative diagnostic results**.

        In this comparison, `Pf_Sample_C` would be the sample of greatest concern for that phenotype because it lacks both `hrp2` and `hrp3`, whereas `Pf_Sample_A` only shows the `hrp3` deletion.


------------------------

# 11. Troubleshooting and dependency issues 

Unlike earlier, conda environments do not always solve perfectly on the first attempt, especially if package versions are constrained. 

This matters when you want to return to the same project for a second analysis pass, because later tools may need a different software stack from the one used for the main SV workflow. A common example is `medaka`, which is often used for polishing and can require a different Python version from the environment you created for NanoPlot, minimap2, samtools, and Sniffles.

!!! Task 
    To demonstrate a package conflict try to install medaka using the command below in your `sv_nanopore` environment.  

    ```
    conda install -c bioconda medaka
    ```

    This may take 1-2 minutes as conda tries to resolve the necessary dependancies. However eventually you should get an error like this:

    ```
    conda install -c bioconda medaka
        Channels:
        - bioconda
        - conda-forge
        Platform: linux-64
        Collecting package metadata (repodata.json): done
        Solving environment: failed

        LibMambaUnsatisfiableError: Encountered problems while solving:
        - nothing provides tensorflow 1.12.0 needed by medaka-0.5.2-py36h2b5150b_0

        Could not solve for environment specs
        The following packages are incompatible
        ├─ medaka =* * is installable with the potential options
        │  ├─ medaka [0.10.0|0.10.1|...|1.2.2] would require
        │  │  └─ python >=3.6,<3.7.0a0 *, which can be installed;
        │  ├─ medaka [0.5.2|0.6.0|...|0.7.0] would require
        │  │  └─ tensorflow ==1.12.0 *, which does not exist (perhaps a missing channel);
        │  ├─ medaka [1.1.1|1.1.2|...|1.2.2] would require
        │  │  └─ python >=3.7,<3.8.0a0 *, which can be installed;
        │  ├─ medaka [1.1.1|1.1.2|...|2.1.0] would require
        │  │  └─ python >=3.8,<3.9.0a0 *, which can be installed;
        │  ├─ medaka [1.10.0|1.11.0|...|2.2.1] would require
        │  │  └─ python >=3.10,<3.11.0a0 *, which can be installed;
        │  ├─ medaka [1.10.0|1.11.0|...|2.1.1] would require
        │  │  └─ python >=3.9,<3.10.0a0 *, which can be installed;
        │  ├─ medaka [1.2.3|1.2.5|...|1.6.1] would require
        │  │  └─ tensorflow =2.2 *, which does not exist (perhaps a missing channel);
        │  ├─ medaka [2.0.0|2.0.1|2.1.1|2.2.0|2.2.1] would require
        │  │  └─ python >=3.11,<3.12.0a0 *, which can be installed;
        │  └─ medaka [2.1.1|2.2.0|2.2.1|2.2.2] would require
        │     └─ python >=3.12,<3.13.0a0 *, which can be installed;
        └─ pin on python =3.13 * is not installable because it requires
        └─ python =3.13 *, which conflicts with any installable versions previously reported.

        Pins seem to be involved in the conflict. Currently pinned specs:
        - python=3.13
    ```

!!! Question

    === "Question"

        Based on the error message obtained what is the main problem?

    === "Answer"

        The main problem is a Python version pin conflict. The environment is pinned to `python=3.13`, but the available `medaka` builds require older Python versions and specific TensorFlow dependencies, so Conda cannot find a compatible set of packages.

        In practice, the fix is usually to keep the structural-variant workflow environment unchanged and create a separate environment for the follow-up tool rather than forcing everything into one install.

        **Follow the steps outlined previously and create a new conda environment with `medaka` installed!**


!!! Question

    === "Question"

        If Conda reports a dependency conflict, what are some sensible next steps?

    === "Answer"

        You can try creating a fresh environment, changing the package version, changing channel priority, installing fewer packages at once, or using `mamba` to obtain a clearer solver result.


!!! Info
    A good long-term habit is to export your environment once it works, especially if you want to move the analysis to another machine or recreate it later.

    This creates a record of the software versions used in the analysis:

    ```bash
    conda env export > sv_nanopore_environment.yml
    ```

    You can then use this file as a reference when rebuilding the environment elsewhere.

------------------------

# 12. Summary

In this practical you have:

* accessed a remote Linux environment,
* created a structured project directory,
* installed software with Conda,
* downloaded a reference genome and Nanopore data,
* run a structural variant workflow step by step,
* converted that workflow into a reusable bash script.

These are core skills that transfer directly to larger bioinformatics projects on HPC / cloud systems.

------------------------

# 13. Extension Questions & Tasks

!!! Task 

    **Bonus**

    Try to source additional nanopore sequencing data for *Plasmodium falciparum*  from NCBI SRA (https://www.ncbi.nlm.nih.gov/sra) and analyse this! For example take a look at the sample (ERX15224754)

!!! Task 

    **Bonus**
    
    Can you find any bioinformatics software which is good at visualising structural variants and available in Conda? If so try download it and take a look at the SV identified via your sniffles analysis!   