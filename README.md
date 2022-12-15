# Metagenomics on Hoffman
Jacobs Lab: Run Humann and Metaphlann on the UCLA supercomputer

Connect to Hoffman Cluster
```bash
ssh julianne@hoffman2.idre.ucla.edu
```
You are now connected to the login node. Now, you can open an interactive session via qrsh. Freeloaders (campus users) are limited to jobs or interactive jobs that run for maximum of 24 hours. However, we can expand computational resources via appending the parameters to qrsh (interactive) or qsh (batch job) and also run command by command rather than large workflows.

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
---
## Setting up the Environment for Metagenomics
Work in SCRATCH, because there is 2TB available per user (working in $HOME, there is only 40GB available). However, files in $SCRATCH are deleted after 14 days. Files in $HOME live forever. 
```bash
cd $SCRATCH
``` 
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
Install HUMAnN 3.0 software with demo databases and Metaphlann 3.0:

```bash
    conda install humann -c biobakery
```

