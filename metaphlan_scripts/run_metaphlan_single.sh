#### submit_job.sh START ####
#!/bin/bash
#$ -cwd
# error = Merged with joblog
#$ -o joblog.$JOB_ID
#$ -j y
## Edit the line below as needed:
#$ -l h_rt=24:00:00,h_data=4G
## Modify the parallel environment
## and the number of cores as needed:
#$ -pe shared 10
# Email address to notify
#$ -M jcyang1617@g.ucla.edu
# Notify when
#$ -m bea

# echo job info on joblog:
echo "Job $JOB_ID started on:   " `hostname -s`
echo "Job $JOB_ID started on:   " `date `
echo " "

# load the job environment:
. /u/local/Modules/default/init/modules.sh
## Edit the line below as needed:
module load anaconda3
conda activate humann

## substitute the command to run your code
## in the two lines below:
metaphlan $1 --bowtie2out ${1%.*}_metagenome.bowtie2.bz2 --nproc 10 --input_type fastq -o ${1%.*}_profiled_metagenome.txt --bowtie2db metaphlan_database --index mpa_vJan21_CHOCOPhlAnSGB_202103

# echo job info on joblog:
echo "Job $JOB_ID ended on:   " `hostname -s`
echo "Job $JOB_ID ended on:   " `date `
echo " "
#### submit_job.sh STOP ####

