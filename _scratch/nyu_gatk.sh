# NOTE assume that all the files are from ILLUMINA data


bwa mem \
-K 100000000 \
-Y \
-R '@RG\tID:ERR751355\tLB:ERR751355\tPL:ILLUMINA\tPM:HISEQ\tSM:ERR751355' \
NC000962_3.fasta \
ERR751355_R1.p.fastq.gz \
ERR751355_R2.p.fastq.gz \
> ERR751355.sam



gatk --java-options "-Xms12G" MarkDuplicatesSpark \
        -I ERR751355.sam \
        -M ERR751355_dedup_metrics.txt \
        -O ERR751355.dedup.sort.bam 





picard CollectAlignmentSummaryMetrics \
        - R NC000962_3.fasta \
        - I ERR751355.dedup.sort.bam \
        - O ERR751355_alignment_metrics.txt


picard CollectInsertSizeMetrics \
        - INPUT ERR751355.dedup.sort.bam \
        - OUTPUT ERR751355_insert_metrics.txt \
        - HISTOGRAM_FILE ERR751355_insert_size_histogram.pdf

samtools depth -a ERR751355.dedup.sort.bam > ERR751355_depth_out.txt


gatk HaplotypeCaller \
        -R NC000962_3.fasta \
        -I ERR751355.dedup.sort.bam \
        -O ERR751355.g.vcf \
        -ERC GVCF


gatk SelectVariants \
		-R NC000962_3.fasta \
		-V ERR751355.vcf \
		--select-type-to-include INDEL \
		-O ERR751355.indels.vcf

gatk SelectVariants \
		-R NC000962_3.fasta \
		-V ERR751355.vcf \
		--select-type-to-include SNP \
		-O ERR751355.snps.vcf




gatk VariantFiltration \
        -R NC000962_3.fasta \
        -V ERR751355.snps.vcf \
        -O ERR751355.filter.snps.vcf \
        -filter-name "QD_filter" -filter "QD < 2.0" \
        -filter-name "FS_filter" -filter "FS > 60.0" \
        -filter-name "MQ_filter" -filter "MQ < 40.0" \
        -filter-name "SOR_filter" -filter "SOR > 4.0" \
        -filter-name "MQRankSum_filter" -filter "MQRankSum < -12.5" \
        -filter-name "ReadPosRankSum_filter" -filter "ReadPosRankSum < -8.0"



gatk VariantFiltration \
        -R NC000962_3.fasta \
        -V ERR751355.indels.vcf \
        -O ERR751355.filter.indels.vcf \
        -filter-name "QD_filter" -filter "QD < 2.0" \
        -filter-name "FS_filter" -filter "FS > 200.0" \
        -filter-name "SOR_filter" -filter "SOR > 10.0"


gatk SelectVariants \
        --exclude-filtered \
        -V ERR751355.filter.snps.vcf \
        -O ERR751355.bqsr.filter.snps.vcf


gatk SelectVariants \
        --exclude-filtered \
        -V ERR751355.filter.indels.vcf \
        -O ERR751355.bqsr.filter.indels.vcf


gatk BaseRecalibrator \
        -R NC000962_3.fasta \
        -I ERR751355.dedup.sort.bam \
        --known-sites ERR751355.bqsr.filter.snps.vcf \
        --known-sites ERR751355.bqsr.filter.indels.vcf \
        -O ERR751355.recal.table 



gatk ApplyBQSR \
        -R NC000962_3.fasta \
        -I ERR751355.dedup.sort.bam \
        -bqsr ERR751355.recal.table \
        -O ERR751355.recal.bam 


gatk BaseRecalibrator \
        -R NC000962_3.fasta \
        -I ERR751355.recal.bam \
        --known-sites ERR751355.bqsr.filter.snps.vcf \
        --known-sites ERR751355.bqsr.filter.indels.vcf \
        -O ERR751355.post.recal.table 


gatk AnalyzeCovariates \
        -before ERR751355.recal.table \
        -after ERR751355.post.recal.table \
        -plots ERR751355_recalibration_plots.pdf 



gatk HaplotypeCaller \
        -R NC000962_3.fasta \
        -I ERR751355.recal.bam \
        -O ERR751355.recal.g.vcf \
        -ERC GVCF



gatk SelectVariants \
        -R NC000962_3.fasta \
        -V ERR751355.recal.vcf \
        --select-type-to-include SNP \
        -O ERR751355.snps.recal.vcf

gatk SelectVariants \
        -R NC000962_3.fasta \
        -V ERR751355.recal.vcf \
        --select-type-to-include INDEL \
        -O ERR751355.indels.recal.vcf


gatk VariantFiltration \
		-R NC000962_3.fasta \
        -V ERR751355.snps.recal.vcf \
        -O ERR751355.snps.final.vcf \
        -filter-name "QD_filter" -filter "QD < 2.0" \
        -filter-name "FS_filter" -filter "FS > 60.0" \
        -filter-name "MQ_filter" -filter "MQ < 40.0" \
        -filter-name "SOR_filter" -filter "SOR > 4.0" \
        -filter-name "MQRankSum_filter" -filter "MQRankSum < -12.5" \
        -filter-name "ReadPosRankSum_filter" -filter "ReadPosRankSum < -8.0" 


gatk VariantFiltration \
		-R NC000962_3.fasta \
        -V ERR751355.indels.recal.vcf \
        -O ERR751355.indels.final.vcf \
        -filter-name "QD_filter" -filter "QD < 2.0" \
        -filter-name "FS_filter" -filter "FS > 200.0" \
        -filter-name "SOR_filter" -filter "SOR > 10.0" 

snpEff -v Mycobacterium_tuberculosis_h37rv \
        ERR751355.snps.final.vcf > ERR751355.ann.snps.final.vcf 