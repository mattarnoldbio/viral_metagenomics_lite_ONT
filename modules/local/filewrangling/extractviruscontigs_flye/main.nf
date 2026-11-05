process EXTRACTVIRUSCONTIGS_FLYE {
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pigz:2.3.4' :
        'biocontainers/pigz:2.3.4' }"

    conda "bioconda::pigz=2.3.4"
    input:
    tuple val(meta), path(contigs), path(virus_hits_csv)

    output:
    tuple val(meta), path("*_diamond_virus_hits.fa.gz"), path("*_diamond_virus_hits.fa"), emit: virus_contigs

    script:
    """

    contigs_file=$contigs
    uncompressed_contigs="\${contigs_file%.gz}"
    pigz -dc \$contigs_file > \$uncompressed_contigs

    awk -F',' 'NR > 1 { print \$2 }' $virus_hits_csv > virus_contig_ids.txt
    awk '
        FILENAME == ARGV[1] { wanted[\$1] = 1; next }
        /^>/ {
            header = substr(\$0, 2)
            split(header, fields, /[[:space:]]/)
            emit = fields[1] in wanted
            if (emit) print
            next
        }
        emit { print }
    ' virus_contig_ids.txt \$uncompressed_contigs > ${meta.id}_diamond_virus_hits.fa

    pigz -c ${meta.id}_diamond_virus_hits.fa > ${meta.id}_diamond_virus_hits.fa.gz

    """
}