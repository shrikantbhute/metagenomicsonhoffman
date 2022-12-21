# Metagenomics on Hoffman
Jacobs Lab: Run Metaphlann4 and Humann on the UCLA Supercomputer Hoffman2. 

This is applicable to anyone trying to scale metagenomic data preprocessing for many samples on a supercomputer. 
At UCLA, our HPC job scheduling system is the Univa Grid Engine, derived from Sun Grid Engine. Therefore, these commands carry over to other UGE job scheduling systems. 


---
## Basic supercomputer instructions for novices
This section is merely a quickstart guide and is not intended to be comprehensive.

Connect to Hoffman Cluster
```bash
ssh julianne@hoffman2.idre.ucla.edu
```
You are now connected to the login node. Now, you can open an interactive session via qrsh. *You must always run commands from a `qrsh` session to avoid consuming resources at the login node or you can be banned.* Freeloaders (campus users) are limited to jobs or interactive jobs that run for maximum of 24 hours. However, we can expand computational resources via appending the parameters to qrsh (interactive) or qsh (batch job) and also run command by command rather than large workflows.

```bash
qrsh -l h rt=2:00:00, h_data=20G
```
Most QIIME2 commands enable "multithreading", which uses multiple cores in a shared memory job. 
For example, to request 4 CPU core, a runtime of 8 hours, and 2GB of memory per core, issue:
Make sure hvmem= Cores* Memory, eg. 4*2 in the example below

```bash
qrsh -l h_rt=8:00:00,h_data=2G,h_vmem=8G -pe shared 4
```
Something that's extremely computationally intensive, we freeloaders can even request a whole node and all of its cores and memory. The wait time will be increased (need to wait for a node to be free).

```bash 
qrsh -l h_rt=24:00:00, exclusive 
```

Work in $SCRATCH, because there is 2TB available per user (working in $HOME, there is only 40GB available). However, files in $SCRATCH are deleted after 14 days. Files in $HOME live forever. `pwd` views absolute filepath of $SCRATCH.
```bash
cd $SCRATCH
pwd
```
To check how much storage you have left in $HOME: 
```bash
myquota
```
---
## Setting up the Environment for Metaphlann4 and Humann

From your local computer command line, transfer the folder containing raw FASTQ to your $SCRATCH dir via `scp`. 

```bash 
C:\Users\Jacobs Laboratory\Documents\JCYang\Shotgun_colon_cancer>scp -r Shotgun_colon_cancer julianne@hoffman2.idre.ucla.edu:/u/scratch/j/julianne 
```

Can see what modules are available via 
```bash
all_apps_via_modules
```
We will likely only need anaconda. However, every time you need anaconda, need to rerun module load.
```bash
module load anaconda3
```
Now, can follow instructions on Huttenhower Lab to download humann and metaphlann. Reposted below for convenience, from https://huttenhower.sph.harvard.edu/humann.

It's good practice to create a new environment for different pipelines, then install new packages for use within the pipeline after activating the environment.
Here, the environment is called `biobakery3`.

```bash
conda create --name biobakery3 python=3.7
conda activate biobakery3
```
```bash
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --add channels biobakery
```
Install HUMAnN 3.0 software with demo databases and Metaphlan 3.0. Also update all humann databases. Note path/to/database should be replaced with the directory to which you want to download databases.

```bash
    conda install humann -c biobakery
    humann_databases --download chocophlan full /path/to/databases --update-config yes
    humann_databases --download uniref uniref90_diamond /path/to/databases --update-config yes
    humann_databases --download utility_mapping full /path/to/databases --update-config yes
```

Update Metaphlan 3.0 to Metaphlan 4.0 (continue within the biobakery3 environment)
```bash
   conda install -c bioconda metaphlan
   metaphlan --version
```

Run Metaphlan for one "paired- end sample"
```bash
metaphlan CC42E_S279_L001_R1_001.fastq.gz, CC42E_S279_L001_R2_001.fastq.gz --bowtie2out metagenome.bowtie2.bz2 --nproc 5 --input_type fastq -o profiled_metagenome.txt
```

If you receive the error "Command ‘[‘bowtie2-build’, ‘–usage’]’ returned non-zero exit status"
you will need to install bowtie2 separately. Clone this repo. Submit the job to the HPC with the shell script `install_bowtie.sh`. This will need to run for about 3 hours.

```bash
qsub install_bowtie.sh
```

Check whether or not the job is running with the below command. Note state "r" means running, and "qw" is pending. if you don't see the job there, it has failed immediately and you will need to evaluate the error message by opening the joblog. Replace `julianne` with your own username. You can also watch the outputs folder update in realtime, by running `watch` on the output folder (mine is called `metaphlan_database`

```bash
qstat -u julianne
watch -n5 ls metaphlan_database/ -1lh
```
Write a script to run metaphlan based on pairs of samples, but submit a job for each sample. Script swarm_metaplan.sh has the following contents, based on NIH notes: https://hpc.nih.gov/apps/metaphlan.html

This script for paired-end samples is `run_metaphlan.sh`. For single samples, it is `run_metaphlan_single.sh`.

For a single pair of samples:
```bash
metaphlan CC42E_S279_L001_R1_001.fastq.gz,CC42E_S279_L001_R2_001.fastq.gz --bowtie2out metagenome.bowtie2.bz2 --nproc 4 --input_type fastq -o profiled_metagenome.txt --bowtie2db metaphlan_database --index mpa_vJan21_CHOCOPhlAnSGB_202103 
```
To submit a job for each pair of samples:
```bash
(biobakery3) [julianne@n1866 test_run]$ for f in *R1_001.fastq.gz; do name=$(basename $f R1_001.fastq.gz); qsub run_metaphlan.sh ${name}R1_001.fastq.gz ${name}R2_001.fastq.gz; done

```
--------------------------------------
## Installing and running KneadData 

By default, conda installs to the $HOME directory. 
If the $HOME directory is full, download to SCRATCH. however, you will need to modify $PATH everytime you reestablish a new connection via ssh or you can permanently change $PATH via direct modification of a config file `.bash_profile` if you're using bash. if you're submitting job via `qsub` (versus running interactively) you probably want to modify `.bash_profile`, `.bashrc`, and `.condarc`.

```bash
pip install kneaddata -target /u/scratch/j/julianne
echo $PATH
export PATH=$PATH:/u/scratch/j/julianne/bin 
echo $PATH
```

Run for a single pair of samples: 
```bash
qsub run_kneaddata.sh CC42E_S279_L001_R1_001.fastq.gz CC42E_S279_L001_R2_001.fastq.gz  
```
