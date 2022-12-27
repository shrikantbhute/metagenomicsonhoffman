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
#$ -pe shared 20
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
conda activate kneaddata

## substitute the command to run your code
## in the two lines below:
kneaddata --input $1 --input $2 --reference-db /u/scratch/j/julianne/kneaddata_databases --output ${1:0:10}_kneaddata --trimmomatic /u/home/j/julianne/.conda/pkgs/trimmomatic-0.39-hdfd78af_2/share/trimmomatic-0.39-2/ -p 20 -t 20 --remove-intermediate-output  

# echo job info on joblog:
echo "Job $JOB_ID ended on:   " `hostname -s`
echo "Job $JOB_ID ended on:   " `date `
echo " "
#### submit_job.sh STOP ####

