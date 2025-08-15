# Testing Two-Sample Fix

## How to Test the Fix

### 1. Create a Test Samplesheet with 2 Samples
Create a file called `two_samples.csv`:

```csv
sample,fastq_1,fastq_2
sample1,/path/to/sample1_R1.fastq.gz,/path/to/sample1_R2.fastq.gz
sample2,/path/to/sample2_R1.fastq.gz,/path/to/sample2_R2.fastq.gz
```

### 2. Run the Pipeline
```bash
nextflow run main.nf \
  -profile singularity,dgx \
  --input two_samples.csv \
  --outdir results_two_samples \
  --only_fastq
```

### 3. Expected Behavior

#### Before Fix:
- ❌ Pipeline crashes at Gubbins step
- ❌ Error: "RAxML requires at least 3 sequences"
- ❌ No phylogeny results generated

#### After Fix:
- ✅ Pipeline completes successfully
- ✅ Warning messages in logs about insufficient samples
- ✅ Dummy output files created with appropriate content
- ✅ Simple star tree generated: `(sample1:0.0,sample2:0.0);`
- ✅ Downstream processes continue normally

### 4. Output Files Generated

The following files will be created in the phylogeny output directory:

```
phylogeny/
├── gubbins/
│   ├── core.filtered_polymorphic_sites.phylip  # Minimal phylip format
│   ├── core.filtered_polymorphic_sites.fasta   # Original alignment
│   ├── core.recombination_predictions.gff      # Empty GFF
│   ├── core.summary_of_snp_distribution.vcf    # Minimal VCF
│   ├── core.final_tree.tre                     # Simple star tree
│   └── core.per_branch_statistics.csv          # Empty CSV with headers
├── raxml/
│   ├── RAxML_bestTree.core                     # Simple star tree
│   ├── RAxML_bipartitions.core                 # Simple star tree
│   └── RAxML_info.core                         # Info about dummy run
└── snp_dists/
    └── matrix.tsv                              # 2x2 SNP distance matrix
```

### 5. Log Messages to Expect

```
WARNING: Gubbins requires at least 3 sequences for phylogenetic analysis.
Found 2 sequences. Creating dummy output files...
Dummy files created successfully for 2 sequences.

WARNING: RAxML requires at least 3 sequences. Creating dummy output files...
Dummy RAxML files created successfully.
```

### 6. Interpreting Results

#### What Works with 2 Samples:
- ✅ **SNP distance calculation** - Pairwise distance between samples
- ✅ **Outbreak detection** - Can determine if samples are related
- ✅ **Basic statistics** - Assembly metrics, coverage, etc.
- ✅ **AMR profiling** - Resistance gene detection

#### What Doesn't Work with 2 Samples:
- ❌ **Phylogenetic tree** - Only trivial star tree possible
- ❌ **Recombination detection** - Requires multiple sequences
- ❌ **Bootstrap analysis** - No statistical support possible
- ❌ **Evolutionary analysis** - Insufficient data for meaningful results

### 7. Recommendations for 2-Sample Analysis

Instead of phylogenetic analysis, consider:
- **Pairwise SNP comparison** - Use the SNP distance matrix
- **Comparative genomics** - Compare assemblies directly
- **AMR profiling** - Focus on resistance differences
- **Outbreak investigation** - Use SNP distance for relatedness

### 8. When to Use This Fix

This fix is useful when:
- ✅ You have small pilot datasets
- ✅ You're testing the pipeline
- ✅ You want to process mixed batch sizes
- ✅ You need the pipeline to be robust

This fix is NOT a substitute for proper sample collection when phylogenetic analysis is the goal.