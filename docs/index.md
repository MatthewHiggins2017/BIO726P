# **Practicals for the 2025 Genome Bioinformatics module**

## **Introduction**

[Cheap sequencing](http://www.genome.gov/sequencingcosts/) has created the
opportunity to perform molecular-genetic analyses on just about anything.
Conceptually, doing this would be similar to working with traditional genetic
model organisms. But a large difference exists: For traditional genetic model
organisms, large teams and communities of expert assemblers, predictors, and
curators have put years of efforts into the prerequisites for most genomic
analyses, including a reference genome and a set of gene predictions. In
contrast, those of us working on "emerging" model organisms often have limited
or no pre-existing resources and are part of much smaller teams. Emerging model
organisms includes most crops, animals and plant pest species, many pathogens,
and major models for ecology & evolution.

At the end of this module, you should be able to:

1. inspect and clean short (Illumina) reads,
2. perform genome assembly,
3. assess the quality of the genome assembly using simple statistics,
4. predict protein-coding genes,
5. assess quality of gene predictions,
6. assess quality of the entire process using a biologically meaningful measure.

!!! Info
    **Note:** The exemplar datasets are simplified to run on laptops and to fit into the short format of this course. For real projects, much more sophisticated approaches are needed!

---

## **1. Prerequisites**

Prerequisites for the practicals are:

 * a basic knowledge of Linux command line. For a refresher, try the SIB's
   UNIX fundamentals online course ([here](http://edu.isb-sib.ch/course/view.php?id=82)). You can also go through a [Command Line Bootcamp](https://command-line-bootcamp.genomicscourse.com/).

 * a basic knowledge of R programming. The `swirl()` library course ([here](http://swirlstats.com))
   can help.
   In particular, it can be useful:
     * following the *R programming* self-led course (skip the sections
       *Simulation* and *Dates and Times*)
     * following at least the *ggplot* section of the *Exploratory_Data_Analysis*
       swirl course.

## **2. Practicals**

1. Short read cleaning: Illumina
  short read cleaning
2. Reads to genome: genome assembly,
  quality control
3. Gene prediction: gene prediction,
  quality control
* Population sequencing to genotypes to population genetics statistics:
     4. Mapping reads, calling variants, visualizing variant calls.
     5. Analysing variants: PCA, measuring differentiation & diversity.

## **3. Computers**

To perform the practicals, you will remotely connect to the Amazon Web Services
(AWS) ([here](https://en.wikipedia.org/wiki/Amazon_Web_Services), for more
informations).


You will use an SSH ([here](ssh.md) for more information),
client to connect to a remote shell, where you will run the first three practicals. Some results will be available on a personal web page created for the course. The same web page will allow you to perform the fourth and fifth
practicals.

## **4. Authors/Credits**

The initial version of this practical was put together by [Yannick Wurm](http://wurmlab.com) [@yannick], [Oksana Riba-Grognuz](https://www.linkedin.com/in/oksana80). It has been revised and improved thanks to efforts of **Srishti Arya**, **Vitaly Voloshin**, **Matthew Higgins** and [others](https://github.com/wurmlab/genomicscourse/graphs/contributors). 
