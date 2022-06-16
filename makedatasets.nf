nextflow.enable.dsl=2

params.outdir="./results"
params.rseed=1482
//params.numgenomes=100
params.numgenomes=3
params.storeDir="/home/wojtek/datacache"

process getSummary {
    storeDir "${params.storeDir}"
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        val orgtype
    output:
        tuple path("${orgtype}.txt"), val(orgtype)
    script:
    """
    wget https://ftp.ncbi.nlm.nih.gov/genomes/refseq/${orgtype}/assembly_summary.txt
    mv assembly_summary.txt ${orgtype}.txt
    """
}

process selectFiles {
    input:
        tuple path(summary), val(orgtype)
        val rseed
    output:
        path "${orgtype}_filelist.txt", emit: filelist
        val orgtype, emit: orgtype
    script:
    """
    python ${baseDir}/samplegenomes.py ${summary} ${orgtype}_filelist.txt genus ${rseed} ${params.numgenomes}
    """
}

process downloadFile {
    storeDir "${params.storeDir}"
    publishDir "${params.outdir}", mode: "copy", overwrite: true
    input:
        tuple val(url), val(orgtype)
    output: 
        tuple path("${orgtype}_genomes/${file(url.trim()).getName()}"), val(orgtype)
    script:
    """
    mkdir ${orgtype}_genomes
    cd ${orgtype}_genomes
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
    summary = getSummary(Channel.of("viral", "bacteria"))
//    summary = getSummary(Channel.of("viral"))
    filelist = selectFiles(summary, params.rseed)
    df = downloadFile(filelist.filelist.splitText().combine(filelist.orgtype))
    df.view()
    stats = labelFile(df).stats.collectFile() { item -> ["${item[1]}_stats", item[0] ] }
    collectStats(stats)
}