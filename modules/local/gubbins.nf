process GUBBINS {
    label 'process_high'

    container "${ workflow.containerEngine in ['singularity','apptainer'] 
  ? 'docker://staphb/gubbins:3.3.5' 
  : 'staphb/gubbins:3.3.5' }"

    input:
    path(clean_full_aln)
    val max_itr

    output:
    path '*.filtered_polymorphic_sites.phylip', emit: phylip
    path '*.filtered_polymorphic_sites.fasta' , emit: fasta
    path '*.recombination_predictions.gff'    , emit: gff
    path '*.recombination_predictions.embl'   , emit: pred_embl
    path '*.branch_base_reconstruction.embl'  , emit: base_recon_embl
    path '*.summary_of_snp_distribution.vcf'  , emit: vcf 
    path '*.final_tree.tre'                   , emit: tre
    path '*.node_labelled.final_tree.tre'     , emit: node_tre
    //path '*.log'                              , emit: log
    path '*.per_branch_statistics.csv'        , emit: csv
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Fix Numba caching issue - must be set before ANY gubbins command
    export NUMBA_DISABLE_JIT=1
    export NUMBA_CACHE_DIR=/tmp/numba_cache
    
    file=$clean_full_aln
    name=\${file%%.clean.full.aln}
    
    # Check number of sequences in alignment
    num_sequences=\$(grep -c "^>" $clean_full_aln)
    
    if [ \$num_sequences -lt 3 ]; then
        echo "WARNING: Gubbins requires at least 3 sequences for phylogenetic analysis."
        echo "Found \$num_sequences sequences. Creating dummy output files..."
        
        # Create dummy output files to satisfy pipeline requirements
        touch \${name}.filtered_polymorphic_sites.phylip
        touch \${name}.filtered_polymorphic_sites.fasta
        touch \${name}.recombination_predictions.gff
        touch \${name}.recombination_predictions.embl
        touch \${name}.branch_base_reconstruction.embl
        touch \${name}.summary_of_snp_distribution.vcf
        touch \${name}.final_tree.tre
        touch \${name}.node_labelled.final_tree.tre
        touch \${name}.per_branch_statistics.csv
        
        # Create minimal phylip file with original sequences
        echo "\$num_sequences 0" > \${name}.filtered_polymorphic_sites.phylip
        
        # Create minimal fasta file with original sequences  
        cp $clean_full_aln \${name}.filtered_polymorphic_sites.fasta
        
        # Create empty GFF file
        echo "##gff-version 3" > \${name}.recombination_predictions.gff
        
        # Create minimal VCF file
        echo "##fileformat=VCFv4.2" > \${name}.summary_of_snp_distribution.vcf
        echo "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO" >> \${name}.summary_of_snp_distribution.vcf
        
        # Create minimal tree file (star tree for 2 samples)
        if [ \$num_sequences -eq 2 ]; then
            sample1=\$(grep "^>" $clean_full_aln | head -1 | sed 's/>//')
            sample2=\$(grep "^>" $clean_full_aln | tail -1 | sed 's/>//')
            echo "(\$sample1:0.0,\$sample2:0.0);" > \${name}.final_tree.tre
            echo "(\$sample1:0.0,\$sample2:0.0);" > \${name}.node_labelled.final_tree.tre
        else
            echo "();" > \${name}.final_tree.tre
            echo "();" > \${name}.node_labelled.final_tree.tre
        fi
        
        # Create empty CSV file with header
        echo "Node,Taxa,SNP_count,Bases_in_recombinations,Bases_in_recombinations_per_base_of_original_alignment,Bases_not_in_recombinations,Bases_not_in_recombinations_per_base_of_original_alignment" > \${name}.per_branch_statistics.csv
        
        echo "Dummy files created successfully for \$num_sequences sequences."
    else
        # Normal Gubbins execution for 3+ sequences
        run_gubbins.py -c ${task.cpus} -i $max_itr -u -p \$name -t raxml $clean_full_aln
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(run_gubbins.py --version 2>&1)
    END_VERSIONS

    """
}