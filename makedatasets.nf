nextflow.enable.dsl=2

params.outdir="./results"
params.rseed=1482
params.numgenomes=100

process getSummary {
    storeDir "/home/wojtek/datacache"
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    output:
        path "assembly_summary.txt", emit: summary
    script:
    """
    wget https://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/assembly_summary.txt
    """
}

process selectFiles {
    input:
        path summary
        val rseed
    output:
        path "filelist.txt", emit: filelist
    script:
    """
    python ${baseDir}/samplegenomes.py ${summary} filelist.txt genus ${rseed} ${params.numgenomes}
    """
}

process downloadFiles {
    storeDir "/home/wojtek/datacache"
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        path filelist
    output: 
        path "genomes", emit: genomedir
        path "genomes/*.gbff.gz", emit: genomes
    script:
    """
    wget -i ${filelist}
    """
}

process labelFiles {
    storeDir "/home/wojtek/datacache/labelled"
    publishDir "${params.outdir}/labelled", mode: "copy", overwrite: true
    input:
        path infile
    output:
        path "${infile}.labelled", emit: labelled
    script:
    """
    python ${baseDir}/labelGenome.py ${infile} ${infile}.labelled
    """
}

workflow {
    summary = getSummary()
    filelist = selectFiles(summary, params.rseed)
    genomes = downloadFiles(filelist).genomes
    labelFiles(genomes.flatten())
}