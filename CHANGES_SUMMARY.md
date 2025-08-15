# Changes Made to neissflow

## 1. Added DGX Profile for Local Execution with Singularity

Added a new `dgx` profile in `nextflow.config` that:
- Uses local executor for running on a single machine
- Enables Singularity containers
- Sets appropriate resource limits for DGX A100 station:
  - Max CPUs: 120 (leaving 8 CPUs for system overhead)
  - Max Memory: 480GB (leaving 32GB for system overhead)
  - Process-specific resource allocations with retry scaling
- Optimized executor settings for local execution

### Usage:
```bash
nextflow run main.nf -profile dgx,singularity --input samplesheet.csv --outdir results
```

## 2. Fixed Awk Version Parsing Bug

Updated awk version parsing in all affected modules to handle:
- Capital letters in version strings
- Colons in version strings  
- Commas in version strings

### Files Modified:
- `modules/local/check_fastqs.nf`
- `modules/local/cluster_coloring.nf`
- `modules/local/stats/coverage.nf`
- `modules/local/qc_check/qc_check.nf`
- `modules/local/phylogeny_qc.nf`
- `modules/local/merge_single_amr.nf`
- `modules/local/merge_amr.nf`
- `modules/local/merge/merge.nf`
- `modules/local/mash/combine_mash_reports.nf`
- `modules/local/make_guide.nf`
- `modules/local/fastp/combine_reports.nf`

### Change Details:
**Before:**
```bash
Awk: \$(awk --version 2>&1 | sed -n 1p | sed 's/GNU Awk //')
```

**After:**
```bash
Awk: \$(awk --version 2>&1 | sed -n 1p | sed 's/.*Awk[[:space:]]*//' | sed 's/[[:space:]].*//')
```

The new version parsing:
1. Matches any text before "Awk" followed by optional whitespace
2. Extracts the version number after "Awk"
3. Stops at the first whitespace character
4. Handles special characters robustly using POSIX character classes

## 3. Updated Global Resource Limits

Updated the global maximum resource limits in `nextflow.config`:
- `max_memory`: Increased from 256.GB to 480.GB
- `max_cpus`: Increased from 16 to 120
- `max_time`: Kept at 240.h

These changes ensure the pipeline can fully utilize the DGX A100 station resources while maintaining system stability.