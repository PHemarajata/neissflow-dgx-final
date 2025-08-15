#!/bin/bash -ue
# Fix Numba caching issue - must be set before ANY gubbins command
export NUMBA_DISABLE_JIT=1
export NUMBA_CACHE_DIR=/tmp/numba_cache

file=core.clean.full.aln
name=${file%%.clean.full.aln}

# Check number of sequences in alignment
num_sequences=$(grep -c "^>" core.clean.full.aln)

if [ $num_sequences -lt 3 ]; then
    echo "WARNING: Gubbins requires at least 3 sequences for phylogenetic analysis."
    echo "Found $num_sequences sequences. Creating dummy output files..."

    # Create dummy output files to satisfy pipeline requirements
    touch ${name}.filtered_polymorphic_sites.phylip
    touch ${name}.filtered_polymorphic_sites.fasta
    touch ${name}.recombination_predictions.gff
    touch ${name}.recombination_predictions.embl
    touch ${name}.branch_base_reconstruction.embl
    touch ${name}.summary_of_snp_distribution.vcf
    touch ${name}.final_tree.tre
    touch ${name}.node_labelled.final_tree.tre
    touch ${name}.per_branch_statistics.csv

    # Create minimal phylip file with original sequences
    echo "$num_sequences 0" > ${name}.filtered_polymorphic_sites.phylip

    # Create minimal fasta file with original sequences  
    cp core.clean.full.aln ${name}.filtered_polymorphic_sites.fasta

    # Create empty GFF file
    echo "##gff-version 3" > ${name}.recombination_predictions.gff

    # Create minimal VCF file
    echo "##fileformat=VCFv4.2" > ${name}.summary_of_snp_distribution.vcf
    echo "#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO" >> ${name}.summary_of_snp_distribution.vcf

    # Create minimal tree file (star tree for 2 samples)
    if [ $num_sequences -eq 2 ]; then
        sample1=$(grep "^>" core.clean.full.aln | head -1 | sed 's/>//')
        sample2=$(grep "^>" core.clean.full.aln | tail -1 | sed 's/>//')
        echo "($sample1:0.0,$sample2:0.0);" > ${name}.final_tree.tre
        echo "($sample1:0.0,$sample2:0.0);" > ${name}.node_labelled.final_tree.tre
    else
        echo "();" > ${name}.final_tree.tre
        echo "();" > ${name}.node_labelled.final_tree.tre
    fi

    # Create empty CSV file with header
    echo "Node,Taxa,SNP_count,Bases_in_recombinations,Bases_in_recombinations_per_base_of_original_alignment,Bases_not_in_recombinations,Bases_not_in_recombinations_per_base_of_original_alignment" > ${name}.per_branch_statistics.csv

    echo "Dummy files created successfully for $num_sequences sequences."
else
    # Normal Gubbins execution for 3+ sequences
    run_gubbins.py -c 12 -i 25 -u -p $name -t raxml core.clean.full.aln
fi

cat <<-END_VERSIONS > versions.yml
"NFCORE_NEISSFLOW:NEISSFLOW:PHYLOGENY:GUBBINS":
    gubbins: $(run_gubbins.py --version 2>&1)
END_VERSIONS
