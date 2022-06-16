Pipeline for downloading RefSeq assemblies and labeling the bases in the sequences based on whether they are in ORFs or not.

## Dependencies

The pipeline only needs:

* nextflow >= 20
* python3
* wget

## Usage

The pipeline can be run using:

```bash
nextflow run makedatasets.nf
```

Optional parameters are:

* -outdir: Output directory for results, default: `./results`
* -cachedir: Cache directory for downloaded files, default: `./cache`
* -rseed: Random seed (for choosing genomes to download), default: 1482

In addition, the organism types and maximum numbers of genomes to download for each organism are defined in the first line of the worflow in `makedatasets.nf`:

```groovy
    summary = getSummary(Channel.of(["viral", 20000], ["bacteria", 2000], ["vertebrate_mammalian", 100]))
```

Here, each tuple consists of the name of an organism type (which has to be a subdirectory name in [https://ftp.ncbi.nlm.nih.gov/genomes/refseq/](https://ftp.ncbi.nlm.nih.gov/genomes/refseq/)) and the maximum number of genomes to download for that organism type.

Only one genome will be downloaded per genus. If several genomes are available for a genus, one will be chosen at random (reproducibly, using `-rseed`).

## Output

The pipeline will create three subfolders in the output directory:

* genomes: Will contain a subfolder for each organism type into which the selected genomes are downloaded (in genbank format)
* labelled: Will contain a subfolder for each organism type with the labelled genomes (in a FASTQ-like format, see below)
* filelists: Will contain the intermediate filelist for each organism type: The assembly_summary.txt downloaded from https://ftp.ncbi.nlm.nih.gov/genomes/refseq/organismtype and a list of genomes selected for downloading and labeling

Additionally, the output directory will contain a _stats_combined.txt file for each organism type which lists the number of bases labelled in every category.

## Labeling

Each base is labeled based on whether it:

* Is within an ORF (forward strand)
* Is within an ORF (reverse strand)
* Is within an ORF that encodes a hypothetical protein

This information is stored in a bitmask:

| Bit number | Meaning      |
|------------|--------------|
|          1 | Forward CDS  |
|          2 | Reverse CDS  |
|          3 | Hypothetical |

Examples:

* 100 (dec. 4): Base is in a forward CDS
* 011 (dec. 3): Base is in reverse CDS, marked as hypothetical
* 110 (dec. 6): Base is in both forward and reverse CDS
* 000: Base is not in a CDS at all
* 001: Base is not in a CDS, but marked as hypothetical -> This should never happen.

The labeled sequences are saved in a [FASTQ](https://en.wikipedia.org/wiki/FASTQ_format)-like format, where the labels are saved instead of qualities. To that end, 33 is added to the bitmask for each base and the resulting number is used as the ASCII code for the quality string.