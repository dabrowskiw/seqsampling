nextflow.enable.dsl=2

params.outdir="./results"
params.rseed=1482
params.storeDir="/home/wojtek/datacache"

process getSummary {
    storeDir "${params.storeDir}"
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        val orgdata
    output:
        tuple path("${orgdata[0]}.txt"), val(orgdata)
    script:
    """
    wget https://ftp.ncbi.nlm.nih.gov/genomes/refseq/${orgdata[0]}/assembly_summary.txt
    mv assembly_summary.txt ${orgdata[0]}.txt
    """
}

process selectFiles {
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        tuple path(summary), val(orgdata)
        val rseed
    output:
        tuple path("${orgdata[0]}_filelist.txt"), val("${orgdata[0]}")
    script:
    """
    python ${baseDir}/samplegenomes.py ${summary} ${orgdata[0]}_filelist.txt genus ${rseed} ${orgdata[1]}
    """
}

process downloadFile {
    storeDir "${params.storeDir}"
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        tuple val(url), val(orgtype)
    output: 
        tuple path("genomes/${orgtype}/${file(url.trim()).getName()}"), val(orgtype)
    script:
    """
    mkdir -p genomes/${orgtype}
    cd genomes/${orgtype}
    wget ${url}
    """
}

process labelFile {
    storeDir "${params.storeDir}"
    publishDir "${params.outdir}/labelled", mode: "copy", overwrite: true
    input:
        tuple path(infile), val(orgtype)
    output:
        path "${orgtype}/${infile}.labelled", emit: labelled
        tuple path("${orgtype}/${infile}.stats"), val(orgtype), emit: stats
    script:
    """
    mkdir ${orgtype}
    python ${baseDir}/labelGenome.py ${infile} ${orgtype}/${infile}.labelled ${orgtype}/${infile}.stats
    """
}

process collectStats {
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        path fullstatfile
    output:
        path "${fullstatfile}_combined.txt"
    script:
    """
    python ${baseDir}/combinestats.py ${fullstatfile} ${fullstatfile}_combined.txt
    """
}

workflow {
    summary = getSummary(Channel.of(["viral", 3], ["bacteria", 2]))
    filelist = selectFiles(summary, params.rseed)
    df = downloadFile(filelist.splitText())
    stats = labelFile(df).stats.collectFile() { item -> ["${item[1]}_stats", item[0] ] }
    collectStats(stats)
}