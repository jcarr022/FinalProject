#Analysis for Chromosome 4
GATK=/opt/GATK/3.4.0/GenomeAnalysisTK.jar
PICARD=/opt/picard/1.81
REFERENCE=TAIR10

SAMPLE=bur_Chr4


#Index the reference
if [ ! -f $REFERENCE.dict ]; then
module load samtools
java -jar $PICARD/CreateSequenceDictionary.jar R=$REFERENCE.fa O=$REFERENCE.dict
samtools faidx $REFERENCE.fa
fi

#index the BAM file
if [ ! -f $SAMPLE.bai ]; then
java -jar $PICARD/BuildBamIndex.jar I=$SAMPLE.bam
fi

#Actually, finally call variants
if [ ! -f $SAMPLE.g.vcf ]; then
java -Xmx32g -jar $GATK -T HaplotypeCaller -R $REFERENCE.fa -I $SAMPLE.bam -ERC GVCF -o $SAMPLE.g.vcf -nct $PBS_NUM_PPN -L Chr4
fi
