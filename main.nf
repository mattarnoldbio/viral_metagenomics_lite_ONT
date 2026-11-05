#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    mattarnoldbio/viral_metagenomics_lite_ont
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/mattarnoldbio/viral_metagenomics_lite_ont
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { VIRAL_METAGENOMICS_LITE_ONT  } from './workflows/viral_metagenomics_lite_ont'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_viral_metagenomics_lite_ont_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_viral_metagenomics_lite_ont_pipeline'
include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_viral_metagenomics_lite_ont_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TODO nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
params.fasta = getGenomeAttribute('fasta')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:

    //
    // WORKFLOW: Run pipeline
    //
    VIRAL_METAGENOMICS_LITE_ONT (
        samplesheet,
        params.multiqc_config,
        params.multiqc_logo,
        params.multiqc_methods_description,
        params.outdir,
    )
    emit:
    multiqc_report = VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_report // channel: /path/to/multiqc_report.html
    assembly_fasta = VIRAL_METAGENOMICS_LITE_ONT.out.assembly_fasta // channel: /path/to/assembly.fasta
    multiqc_data = VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_data
    multiqc_plots = VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_plots
    flye_details = VIRAL_METAGENOMICS_LITE_ONT.out.flye_details
    diamond_results = VIRAL_METAGENOMICS_LITE_ONT.out.diamond_results
    krona_reports = VIRAL_METAGENOMICS_LITE_ONT.out.krona_reports
    viral_hits_by_sample = VIRAL_METAGENOMICS_LITE_ONT.out.viral_hits_by_sample
    viral_hits = VIRAL_METAGENOMICS_LITE_ONT.out.viral_hits
    viral_contigs = VIRAL_METAGENOMICS_LITE_ONT.out.viral_contigs
    medaka_assembly = VIRAL_METAGENOMICS_LITE_ONT.out.medaka_assembly
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input,
        params.help,
        params.help_full,
        params.show_hidden
    )

    //
    // WORKFLOW: Run main workflow
    //
    MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT (
        PIPELINE_INITIALISATION.out.samplesheet
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_report,
    )

    publish:
    multiqc_report = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_report // channel: /path/to/multiqc_report.html
    assembly_fasta = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.assembly_fasta // channel: /path/to/assembly.fasta
    multiqc_data = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_data
    multiqc_plots = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.multiqc_plots
    flye_details = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.flye_details
    diamond_results = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.diamond_results
    krona_reports = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.krona_reports
    viral_hits_by_sample = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.viral_hits_by_sample
    viral_hits = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.viral_hits
    viral_contigs = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.viral_contigs
    medaka_assembly = MATTARNOLDBIO_VIRAL_METAGENOMICS_LITE_ONT.out.medaka_assembly
}

output {
    assembly_fasta {
        path 'assemblies/flye'
    }
    flye_details {
        path 'assemblies/flye/details'
    }
    viral_contigs {
        path 'assemblies/viral_contigs'
    }
    medaka_assembly {
        path 'assemblies/medaka'
    }
    diamond_results {
        path 'alignments/diamond'
    }
    krona_reports {
        path 'taxonomy/krona'
    }
    viral_hits_by_sample {
        path 'taxonomy/viral_hits/by_sample'
    }
    viral_hits {
        path 'taxonomy/viral_hits'
    }
    multiqc_report {
        path 'quality_control/multiqc'
    }
    multiqc_data {
        path 'quality_control/multiqc'
    }
    multiqc_plots {
        path 'quality_control/multiqc'
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
