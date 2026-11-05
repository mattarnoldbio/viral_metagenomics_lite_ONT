# mattarnoldbio/viral_metagenomics_lite_ont: Output

## Introduction

This document describes the output produced by the pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Output layout

All paths below are relative to the run's output directory (`--outdir`).

| Directory | Contents |
| --- | --- |
| `assemblies/flye/` | Per-sample Flye draft assemblies (`*.assembly.fasta.gz`). |
| `assemblies/flye/details/` | Flye assembly graphs, assembly information, logs, and parameters. |
| `assemblies/viral_contigs/` | FASTA sequences for contigs identified as viral. |
| `assemblies/medaka/` | Medaka consensus assemblies generated from viral contigs and the original reads. |
| `alignments/diamond/` | Tabular DIAMOND BLASTX search results. |
| `taxonomy/krona/` | Krona HTML reports and their accompanying assets. |
| `taxonomy/viral_hits/by_sample/` | Viral-hit CSV files for individual samples. |
| `taxonomy/viral_hits/` | Combined viral-hit CSV. |
| `quality_control/multiqc/` | MultiQC HTML report, parsed data, and plots. |
| `pipeline_info/` | Pipeline version metadata and other run information written by Nextflow. |

The Flye assembly is the draft assembly used for annotation. The Medaka output is a separate consensus assembly of the extracted viral contigs, polished using the original reads.
