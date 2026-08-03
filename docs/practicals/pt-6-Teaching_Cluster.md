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

# 7. Downloading the Nanopore data

You will also need a Nanopore FASTQ file for the sample we are analysing.

!!! Task
    Change into your `input` directory and download the FASTQ file using the link provided below: 

    ```bash
    cd ~/BIO726P_Teaching_Cluster/input
    wget -O Pf_sample_1.fastq.gz <ADD_LINK_TO_GDRIVE_HERE>
    wget -O Pf_sample_2.fastq.gz <ADD_LINK_TO_GDRIVE_HERE>
    wget -O Pf_sample_3.fastq.gz <ADD_LINK_TO_GDRIVE_HERE>
    ```

!!! Info
    In this session the FASTQ file is supplied for you. In a real project, data may come from public archives such as ENA, SRA, or institutional storage.

!!! Task
    Check the file exists and inspect the first read:

    ```bash
    ls -lh sample_1.fastq.gz
    zcat sample_1.fastq.gz | head
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

------------------------

# 8. Part 1: Exploring the structural variant workflow step-by-step

In this first part, you will run each command manually so that you understand what every step is doing.

## 8.1 Quality control of the raw reads

!!! Task
    Change into your `tmp` directory and run NanoPlot on the raw FASTQ file:

    ```bash
    cd ~/BIO726P_Teaching_Cluster/tmp
    NanoPlot --fastq ../input/sample_1.fastq.gz --outdir sample_1_nanoplot_raw
    ```

!!! Task
    Inspect the output directory:

    ```bash
    ls sample_1_nanoplot_raw
    ```

    Find and open the report.html file, to inspect the metrics used to assess sample quality. 


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
        zcat ../input/sample_1.fastq.gz | chopper -q 10 -l 1000 | gzip > filtered_reads.fastq.gz
        ```

!!! Info
    Here, `-q 10` removes very low-quality reads and `-l 1000` keeps only reads that are at least 1000 bases long. The `zcat ... | ... | gzip` pattern decompresses the input on the fly and writes the filtered output back out as a compressed FASTQ file.

!!! Task
    Run NanoPlot again on the filtered reads:

    ```bash
    NanoPlot --fastq filtered_reads.fastq.gz --outdir nanoplot_filtered
    ```

!!! Question

    === "Question"

        Why might filtering improve downstream structural variant calling?

    === "Answer"

        Very short or poor-quality reads can map less reliably and may increase false-positive variant calls. Filtering can improve mapping quality and reduce noise.


!!! Question

    === "Question"

        What other metrics does Chopper allow you to filter on? 

    === "Answer"

        In addition to minimum quality (`-q`) and minimum length (`-l`), `chopper` can filter on maximum quality (`--maxqual`), maximum read length (`--maxlength`), minimum and maximum GC content (`--mingc`, `--maxgc`), and contaminant sequence matching using a FASTA file (`--contam`).


## 8.3 Map reads to the reference

We will now align the filtered reads to the reference genome using `minimap2`.

!!! Task
    Run the alignment and write the output to SAM format:

    ```bash
    minimap2 -ax map-ont ../references/GCF_000002765.6_GCA_000002765_genomic.fna filtered_reads.fastq.gz > sample_1.sam
    ```

!!! Info
    The `-ax map-ont` preset is designed for Oxford Nanopore reads. 


!!! Task
    Convert the SAM file to a sorted BAM file and index it:

    ```bash
    samtools sort -O BAM sample_1.sam > sample_1.sorted.bam
    samtools index sample_1.sorted.bam
    ```

!!! Task
    Generate a few simple alignment statistics:

    ```bash
    samtools flagstat sample_1.sorted.bam
    samtools idxstats sample_1.sorted.bam | head
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
    sniffles --input sample_1.sorted.bam --vcf sample_1.sniffles.vcf
    ```

!!! Task
    Inspect the first few lines of the VCF:

    ```bash
    head sample_1.sniffles.vcf
    ```

!!! Task
    Count how many variants were called:

    ```bash
    grep -vc "^#" sample_1.sniffles.vcf
    ```

!!! Question

    === "Question"

        What is the difference between the header lines and the variant lines in a VCF file?

    === "Answer"

        Header lines begin with `#` and describe the file format, metadata, and column names. Variant lines contain the actual variant records.

------------------------

# 9. Interpreting the structural variants

Now that you have a structural variant call set, start thinking about biological interpretation.

!!! Task
    Search the VCF for deletion calls:

    ```bash
    grep "SVTYPE=DEL" sample_1.sniffles.vcf | head
    ```

!!! Task
    If you have downloaded a GFF annotation file, use it together with the VCF to investigate whether any called deletions overlap genes of interest.


!!! Question

    === "Question"

        Why is it not enough to simply observe that Sniffles reported a deletion?

    === "Answer"

        Variant callers make predictions based on read evidence, but those predictions still need interpretation. You need to consider genomic context, read support, mapping quality, and whether the affected region overlaps biologically meaningful features.

!!! Question

    === "Question"

        What extra information would help you decide whether a structural variant call is likely to be real?

    === "Answer"

        Useful evidence includes read depth, the number of supporting reads, consistency across replicate samples, visual inspection in a genome browser, and whether the event is plausible relative to the local annotation and repeat content.



EXPAND THIS HERE BASED ON THE RAW DATA GENERATED (E.G) - SNIFFLES FILTERING BASED ON READ DEPTH REPORTED.

------------------------

# 10. Part 2: Turning the workflow into a bash script

Running commands manually is useful for learning, but it does not scale well. A script makes your workflow easier to rerun, easier to share, and easier to adapt when you want to analyse another sample or repeat the same workflow later.

In practice, a script does two important jobs:

* it records the exact commands you used, so you do not need to rely on memory or terminal history,
* it keeps repeated setup steps, file paths, and output names in one place, which reduces mistakes when you rerun the analysis.

The first version of the script below only automates the early parts of the pipeline. That is deliberate: it lets you check that your inputs, paths, and Conda environment are working before you extend the workflow to mapping and variant calling.

## 10.1 Create your first analysis script

!!! Task
    Return to your main project directory and create a script called `run_sv_analysis.sh`:

    ```bash
    cd ~/BIO726P_Teaching_Cluster
    nano run_sv_analysis.sh
    ```

    Add the following script:

    ```
    #!/usr/bin/env bash
    
    PROJECT_DIR="$HOME/BIO726P_Teaching_Cluster"
    INPUT_FASTQ="$PROJECT_DIR/input/sample_1.fastq.gz"
    REFERENCE="$PROJECT_DIR/references/GCF_000002765.6_GCA_000002765_genomic.fna"
    TMP_DIR="$PROJECT_DIR/tmp/script_run"
    RESULTS_DIR="$PROJECT_DIR/results"

    mkdir -p "$TMP_DIR" "$RESULTS_DIR"

    conda activate sv_nanopore

    NanoPlot --fastq "$INPUT_FASTQ" --outdir "$TMP_DIR/nanoplot_raw"

    chopper -q 10 -l 1000 < "$INPUT_FASTQ" | gzip > "$TMP_DIR/filtered_reads.fastq.gz"

    NanoPlot --fastq "$TMP_DIR/filtered_reads.fastq.gz" --outdir "$TMP_DIR/nanoplot_filtered"
    ```

    Inspect the commands in this file. What steps of your analysis pipeline is it running, and which pieces are still left out?

    The variable names at the top make the script easier to read and update:

    * `PROJECT_DIR` stores the main project path in one place.
    * `INPUT_FASTQ` and `REFERENCE` point to the data files used by the workflow.
    * `TMP_DIR` and `RESULTS_DIR` separate temporary working files from final outputs.

    The commands underneath then run two early-stage checks on the raw data:

    * `NanoPlot` on the original FASTQ file for an initial quality-control summary,
    * `chopper` to filter out short or low-quality reads,
    * `NanoPlot` again on the filtered reads so you can see how the dataset changed after filtering.

    In other words, this script covers the preprocessing and quality-control part of the workflow, but it does not yet map reads or call structural variants.

    Save the file, then make it executable and run it once to see the intermediate output:

    ```bash
    chmod +x run_sv_analysis.sh
    ./run_sv_analysis.sh
    ```

!!! Question

    === "Question"

        Now try to extend the script so it also carries out the mapping, sorting, indexing, and structural variant calling steps. What would the full version look like?

    === "Answer"

        ```
        #!/usr/bin/env bash
        set -euo pipefail

        PROJECT_DIR="$HOME/BIO726P_Teaching_Cluster"
        INPUT_FASTQ="$PROJECT_DIR/input/sample_1.fastq.gz"
        REFERENCE="$PROJECT_DIR/references/GCF_000002765.6_GCA_000002765_genomic.fna"
        TMP_DIR="$PROJECT_DIR/tmp/script_run"
        RESULTS_DIR="$PROJECT_DIR/results"

        mkdir -p "$TMP_DIR" "$RESULTS_DIR"

        conda activate sv_nanopore

        NanoPlot --fastq "$INPUT_FASTQ" --outdir "$TMP_DIR/nanoplot_raw"

        chopper -q 10 -l 1000 < "$INPUT_FASTQ" | gzip > "$TMP_DIR/filtered_reads.fastq.gz"

        NanoPlot --fastq "$TMP_DIR/filtered_reads.fastq.gz" --outdir "$TMP_DIR/nanoplot_filtered"

        minimap2 -ax map-ont "$REFERENCE" "$TMP_DIR/filtered_reads.fastq.gz" > "$TMP_DIR/sample_1.sam"

        samtools sort -O BAM "$TMP_DIR/sample_1.sam" > "$TMP_DIR/sample_1.sorted.bam"
        samtools index "$TMP_DIR/sample_1.sorted.bam"

        samtools flagstat "$TMP_DIR/sample_1.sorted.bam" > "$RESULTS_DIR/sample_1.flagstat.txt"

        sniffles --input "$TMP_DIR/sample_1.sorted.bam" --vcf "$RESULTS_DIR/sample_1.sniffles.vcf"
        ```
    You should see at least:

    * `sample_1.flagstat.txt`
    * `sample_1.sniffles.vcf`

------------------------

# 11. Troubleshooting and dependency issues 

Conda environments do not always solve perfectly on the first attempt, especially if package versions are constrained. 

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

# TO ADD IN OR MOVE!!

BONUS - Find Pf Nanopore samples from NCBI and run the analysis! - This is great bonus task to get them to do it! 

    In this session the FASTQ file is supplied for you. In a real project, data may come from public archives such as ENA, SRA, or institutional storage.


!!! Question

    === "Question"

        Why is an annotation file useful when interpreting structural variants?

    === "Answer"

        The annotation tells you where genes and other genomic features are located. This allows you to assess whether a structural variant overlaps a gene of interest, such as `dhfr`.

NEED TO EXPAND TO HAVE A DEPENDANCY CONFILCT TO CONDUCT SECOND ROUND OF ANALYSIS COMPARED TO SV PIPELINE - FIGURE THIS OUT! 

------------------------

# 12. Summary

In this practical you have:

* accessed a remote Linux environment,
* created a structured project directory,
* installed software with Conda,
* downloaded a reference genome and Nanopore data,
* run a structural variant workflow step by step,
* converted that workflow into a reusable bash script.

These are core skills that transfer directly to larger bioinformatics projects on HPC systems.

------------------------

# 13. Extension Questions & Tasks

!!! Question

    === "Question"

        If you wanted to make your script more general so that it could analyse many samples, how would you change it?

    === "Answer"

        You could accept the sample name and input FASTQ path as command-line arguments, loop over multiple input files, write logs for each sample, and parameterise settings such as quality thresholds and output directories.

        Have a go at implementing this and ask one of the Teaching Assistants to come and assess your work!


!!! Question

    === "Question"

        What are the limitations of analysing only one sample against one reference?

    === "Answer"

        You cannot easily distinguish sample-specific effects from general mapping artefacts, estimate how reproducible the calls are, or compare structural variation patterns across a population.

!!! Task 

    **Bonus**

    Try to source additional nanopore sequencing data for *Plasmodium falciparum*  from NCBI SRA (https://www.ncbi.nlm.nih.gov/sra) and analyse this! For example take a look at samples (ERX15224754)

!!! Task 

    **Bonus**
    
    Can you find any bioinformatics software which is good at visualising structural variants and available in Conda? If so try download it and take a look at the SV identified via your sniffles analysis!   