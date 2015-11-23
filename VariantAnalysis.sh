SAMPLEFILE=Source.info
REFERENCE=TAIR9
CPU=1
GATK=/opt/GATK/3.4.0/GenomeAnalysisTK.jar
PICARD=/opt/picard/1.81

#Specify the line number(s)
LINE=$PBS_ARRAYID
if [ ! $LINE ]; then
    LINE=$1
fi

if [ ! $LINE ]; then
    echo "Gimme a line!"
fi


#Specify the number of processors
if [ $PBS_NUM_PPN ]; then
    CPU=$PBS_NUM_PPN
fi

#Deal with the multiple files
ROW=`head -n $LINE $SAMPLEFILE | tail -n 1`
SAMPLE=`echo "$ROW" | awk '{print $1}'`
URL=`echo "$ROW" | awk '{print $2}'`

#Downlaod the file
if [ ! -f $SAMPLE.bam ]; then
    curl $URL > $SAMPLE.bam
fi

#Get stats on the alignment
if [ ! -d `$SAMPLE_stats` ]; then
    module load qualimap
    qualimap bamqc -bam $SAMPLE.bam --java-mem-size=$PBS_MEM -nt $PBS_NUM_PPN -outformat PDF
fi

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

#Realign for indels PT1
if [ ! -f $SAMPLE.intervals ]; then
    java -Xmx$16g -jar $GATK -T RealignerTargetCreator -R $REFERENCE.fa -I $SAMPLE.bam -o $SAMPLE.intervals
fi

#Realign for indels PT2
if [ ! -f $SAMPLE.realign.bam ]; then
    java -Xmx16g -jar $GATK -T IndelRealigner -R $REFERENCE.fa -I $SAMPLE.bam --targetIntervals $SAMPLE.intervals -o $SAMPLE.realign.bam -nct $PBS_NUM_PPN
fi

#Actually, finally call variants
if [ ! -f $SAMPLE.g.vcf ]; then
    java -Xmx16g -jar $GATK -T HaplotypeCaller -R $REFERENCE.fa -I $SAMPLE.bam -ERC GVCF -o $SAMPLE.g.vcf -nct $PBS_NUM_PPN
fi









