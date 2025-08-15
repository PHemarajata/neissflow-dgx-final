# Gubbins Two-Sample Fix

## Problem Identified
Gubbins fails when there are only 2 samples in the analysis because:

1. **Phylogenetic analysis requires minimum 3 taxa** for meaningful tree construction
2. **Recombination detection** needs multiple sequences to identify recombinant regions
3. **RAxML** (used by Gubbins) requires at least 3 sequences to build trees
4. **Bootstrap analysis** is meaningless with fewer than 3 sequences

## Root Cause
- Gubbins is designed for population-level analysis with multiple isolates
- Two samples provide insufficient data for:
  - Phylogenetic tree construction
  - Recombination detection
  - Statistical confidence measures
  - Meaningful evolutionary analysis

## Solution Applied

### 1. Updated Gubbins Module (`modules/local/gubbins.nf`)
Added sample count check and graceful handling:

```bash
# Check number of sequences in alignment
num_sequences=$(grep -c "^>" $clean_full_aln)

if [ $num_sequences -lt 3 ]; then
    # Create dummy output files with appropriate content
    # Handle 2-sample case with simple star tree
else
    # Normal Gubbins execution for 3+ sequences
fi
```

### 2. Updated RAxML Module (`modules/local/raxml.nf`)
Added similar protection for RAxML:

```bash
# Check if phylip file has sufficient sequences
if [ $(head -1 $phylip | awk '{print $1}') -ge 3 ]; then
    # Normal RAxML execution
else
    # Create dummy RAxML output files
fi
```

## What the Fix Does

### For 2 Samples:
- ✅ **Creates valid output files** - Pipeline continues without crashing
- ✅ **Generates simple star tree** - `(sample1:0.0,sample2:0.0);`
- ✅ **Maintains file formats** - All expected outputs are created
- ✅ **Provides clear warnings** - Logs explain the limitation
- ✅ **Preserves original alignment** - Copies input to filtered output

### For 1 Sample:
- ✅ **Creates empty output files** - Prevents pipeline failure
- ✅ **Logs appropriate warnings** - Explains why analysis is skipped
- ✅ **Maintains pipeline flow** - Downstream processes can continue

### For 3+ Samples:
- ✅ **Normal operation** - Full Gubbins and RAxML analysis
- ✅ **No performance impact** - Standard phylogenetic analysis
- ✅ **All features available** - Recombination detection, bootstrapping, etc.

## Output Files Created for <3 Samples

### Gubbins Outputs:
- `*.filtered_polymorphic_sites.phylip` - Minimal phylip format
- `*.filtered_polymorphic_sites.fasta` - Copy of original alignment
- `*.recombination_predictions.gff` - Empty GFF file
- `*.recombination_predictions.embl` - Empty EMBL file
- `*.branch_base_reconstruction.embl` - Empty EMBL file
- `*.summary_of_snp_distribution.vcf` - Minimal VCF header
- `*.final_tree.tre` - Simple star tree for 2 samples
- `*.node_labelled.final_tree.tre` - Simple star tree for 2 samples
- `*.per_branch_statistics.csv` - Empty CSV with headers

### RAxML Outputs:
- `RAxML_bipartitions.*` - Simple tree or empty
- `RAxML_bipartitionsBranchLabels.*` - Simple tree or empty
- `RAxML_bootstrap.*` - Empty file
- `RAxML_bestTree.*` - Simple tree or empty
- `RAxML_info.*` - Information about dummy run

## Benefits
- ✅ **Pipeline robustness** - No more crashes with small datasets
- ✅ **Clear communication** - Users understand limitations
- ✅ **Maintains compatibility** - All downstream processes work
- ✅ **Preserves data** - Original alignments are retained
- ✅ **Graceful degradation** - Provides what analysis is possible

## Limitations for <3 Samples
- ❌ **No recombination detection** - Insufficient data
- ❌ **No meaningful phylogeny** - Trees are trivial
- ❌ **No bootstrap support** - Statistical measures unavailable
- ❌ **No evolutionary insights** - Population analysis requires more samples

## Recommendations
- **For 2 samples**: Consider pairwise SNP analysis instead
- **For population studies**: Collect at least 10-20 samples
- **For outbreak investigation**: Minimum 5-10 related isolates
- **For phylogenetic analysis**: 3+ samples required

## Testing
To test the fix with 2 samples:
```bash
nextflow run main.nf -profile test,singularity --input two_sample_sheet.csv
```

The pipeline will now complete successfully with appropriate warnings in the logs.

## Files Modified
- ✅ `modules/local/gubbins.nf` - Added sample count check and dummy file creation
- ✅ `modules/local/raxml.nf` - Added protection against insufficient sequences

The fix maintains the original pipeline structure while providing robust handling of edge cases.