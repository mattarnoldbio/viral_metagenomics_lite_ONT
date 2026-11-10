/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                                                    } from '../modules/nf-core/fastqc/main'
include { MULTIQC                                                   } from '../modules/nf-core/multiqc/main'
include { CAT_FASTQ                                                 } from '../modules/nf-core/cat/fastq/main'
include { FLYE                                                      } from '../modules/nf-core/flye/main'
include { MEDAKA                                                    } from '../modules/nf-core/medaka/main'
include { CONCATENATECONTIGFILES                                    } from '../modules/local/filewrangling/concatenatecontigfiles/main' 
include { SPLITBLASTRESULT                                          } from '../modules/local/filewrangling/splitblastresult/main' 
include { DIAMOND_BLASTX                                            } from '../modules/nf-core/diamond/blastx/main'
include { KRONA_KTIMPORTBLAST                                       } from '../modules/local/kronatools/importblast/main'
include { EXTRACT_KRONA_TAXONOMY                                    } from '../modules/local/extractkronataxonomy/main'
include { CONCATENATECSVS as CONCATENATECSVS_BLASTX                 } from '../modules/local/filewrangling/concatenatecsvs/main'
include { CONCATENATECSVS as CONCATENATECSVS_BLASTX_NON             } from '../modules/local/filewrangling/concatenatecsvs/main'
include { EXTRACTVIRUSCONTIGS_FLYE                                  } from '../modules/local/filewrangling/extractviruscontigs_flye/main'
include { FILTERHITDATA                                             } from '../modules/local/filewrangling/filterhitdata/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_viral_metagenomics_lite_ont_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow VIRAL_METAGENOMICS_LITE_ONT {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:
        def ch_versions = channel.empty()
        def ch_multiqc_files = channel.empty()

        ch_samplesheet
            .map { meta, files -> [ meta, files ] }
            .branch { meta, files ->
                multiple: files.size() > 1
                single:   true
            }
            .set { ch_branched }

        
        // ch_branched.view()

        CAT_FASTQ( ch_branched.multiple )

        ch_merged = CAT_FASTQ.out.reads.mix(
            ch_branched.single.map { meta, files -> [ meta, files[0] ] }
            )

        FLYE( ch_merged, "--nano-raw")

        FLYE.out.fasta
               .multiMap { meta, contigs ->
                    meta: meta
                    contigs: [ [id: meta.id], contigs ]
                    contigs_: contigs
                }
                .set { ch_contigs }

        

        // ch_meta_long = ch_contigs.meta.collect()
        ch_contigs_long = ch_contigs.contigs_.collect()

        //
        // MODULE: Concatenate contigs using a local module
        CONCATENATECONTIGFILES(ch_contigs_long, "")

        ch_all_contigs = CONCATENATECONTIGFILES.out.map{ all_contigs -> 
            def meta = [id: "all_contigs"]
            tuple (meta, all_contigs)
        }
    
        ch_diamond_db = channel.fromPath("${params.diamond_db}*", checkIfExists: true)
                            .collect()
                            .map { db_files -> tuple([id: "blast_db"], db_files) }


        //
        // MODULE: Search contigs against reference DB with Diamond BLASTX
        DIAMOND_BLASTX(ch_all_contigs, ch_diamond_db ,'txt', '')




        ch_blast_results = DIAMOND_BLASTX.out.txt
                            .flatMap{
                                _meta, results ->
                                    results.splitCsv(sep: "\t")
                                        .collect { row ->
                                                def sample_id = row[0].split('\\|')[0]   // parse "sample" out of "sample|contig"
                                                tuple(sample_id, row)
                                                }
                            }
                            .groupTuple()
                            .map { sample_id, blast_results ->
                                    def meta = [id: sample_id, db: "diamond"]
                                tuple(meta, blast_results)
                                    }
    
        // MODULE: Split BLAST results into individual files for each sample
        SPLITBLASTRESULT(ch_blast_results)
        ch_split_blastx_results = SPLITBLASTRESULT.out
        // ch_split_blastx_results.view()

        //
        // MODULE: Make Krona plots to show taxonomic breakdown of each sample's BLAST results
        KRONA_KTIMPORTBLAST(ch_split_blastx_results, params.krona_db)

        ch_contigs_taxonomy = ch_contigs.contigs
            .map { meta, contigs -> tuple(meta.id, contigs) }
            .join(
                KRONA_KTIMPORTBLAST.out.html.map { meta, html, metadata_dir -> tuple(meta.id, meta, html, metadata_dir) }
            )
            .map { _id, contigs, meta, html, metadata_dir -> tuple(meta, contigs, html, metadata_dir) }
        //if legacy :
        //TODO: Add a parameter to choose between legacy and new taxonomy extraction
        //TODO: Add a parameter to choose between database and score filter for Krona taxonomy extraction

        // MODULE: Extract virus hits from Krona taxonomy results
        EXTRACT_KRONA_TAXONOMY(ch_contigs_taxonomy, "diamond", 10)

        EXTRACT_KRONA_TAXONOMY.out.virus_hits
            .set{ ch_virus_hits }

        EXTRACT_KRONA_TAXONOMY.out.virus_hits
                            .map { _meta, _contigs, virus_hits ->
                                virus_hits
                            }
                            .collect()
                            .set { ch_all_virus_hits }

        // MODULE: Concatenate .csv files from EXTRACT_KRONA_TAXONOMY_BLASTX to create a single .csv file for virus hits
        CONCATENATECSVS_BLASTX(ch_all_virus_hits, "diamond", "all")
            .csv
            .set{ ch_all_virus_hits_diamond }

        // MODULE: Extract virus contigs from the original contigs file based on the virus hits .csv file
        EXTRACTVIRUSCONTIGS_FLYE(ch_virus_hits)
        
        EXTRACTVIRUSCONTIGS_FLYE.out.virus_contigs
            .set{ ch_all_virus_contigs }

        ch_all_virus_contigs_uncompressed = ch_all_virus_contigs
            .map { result -> tuple(result[0], result[2]) }

        ch_medaka = ch_all_virus_contigs_uncompressed
            .map { result -> tuple(result[0].id, result[0], result[1]) }
            .join(
                ch_merged.map { result -> tuple(result[0].id, result[1]) }
            )
            .map { result -> tuple(result[1], result[3], result[2]) }

        MEDAKA(ch_medaka)

        MEDAKA.out.assembly
            .set{ ch_all_virus_assemblies }


        // Collate and save software versions
        //
        def topic_versions = channel.topic("versions")
            .distinct()
            .branch { entry ->
                versions_file: entry instanceof Path
                versions_tuple: true
            }

        def topic_versions_string = topic_versions.versions_tuple
            .map { process, tool, version ->
                [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
            }
            .groupTuple(by:0)
            .map { process, tool_versions ->
                tool_versions.unique().sort()
                "${process}:\n${tool_versions.join('\n')}"
            }

        def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
            .mix(topic_versions_string)
            .collectFile(
                storeDir: "${outdir}/pipeline_info",
                name:  'viral_metagenomics_lite_software_'  + 'mqc_'  + 'versions.yml',
                sort: true,
                newLine: true
            )

        //
        // MODULE: MultiQC
        //
        ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
        def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
        def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
        ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        def ch_multiqc_custom_methods_description = multiqc_methods_description
            ? file(multiqc_methods_description, checkIfExists: true)
            : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
        def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
        ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
        MULTIQC(
            ch_multiqc_files.flatten().collect().map { files ->
                [
                    [id: 'viral_metagenomics_lite'],
                    files,
                    multiqc_config
                        ? file(multiqc_config, checkIfExists: true)
                        : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                    multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                    [],
                    [],
                ]
            }
        )


    emit:
        ch_samplesheet
        multiqc_report = MULTIQC.out.report
        multiqc_data = MULTIQC.out.data
        multiqc_plots = MULTIQC.out.plots
        assembly_fasta = FLYE.out.fasta
        flye_details = FLYE.out.gfa
            .mix(FLYE.out.gv)
            .mix(FLYE.out.txt)
            .mix(FLYE.out.log)
            .mix(FLYE.out.json)
        diamond_results = DIAMOND_BLASTX.out.txt
        krona_reports = KRONA_KTIMPORTBLAST.out.html
        viral_hits_by_sample = EXTRACT_KRONA_TAXONOMY.out.virus_hits
            .map { meta, _contigs, hits -> tuple(meta, hits) }
        viral_hits = ch_all_virus_hits_diamond
        viral_contigs = ch_all_virus_contigs
            .map { result -> tuple(result[0], result[1]) }
        medaka_assembly = ch_all_virus_assemblies

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
