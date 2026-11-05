# Tiny ONT-style mock input

One sample folder with four 2,000-base, single-end FASTQ records: two overlapping fragments from a *Myotis lucifugus* genomic scaffold and two from bat coronavirus RaTG13. The records are reference-derived in-silico fragments, not observed ONT reads; `I` qualities are placeholders. This tiny fixture can exercise input parsing and avoid minimum-read-length rejection, but it does not provide enough coverage for meaningful assembly or biological analysis.

Sources:

- Bat host: *Myotis lucifugus* scaffold NW_005878822.1, RefSeq assembly GCF_000147115.1 (Myoluc2.0).
- Bat coronavirus: RaTG13, GenBank MN996532.2.

`samplesheet.csv` uses the `sample,fastq_dir` format. Its directory path is project-root-relative, so run from the repository root.
