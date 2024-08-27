# Metagenomics on Hoffman
Jacobs Lab: Run Metaphlann4 and Humann on the UCLA Supercomputer Hoffman2. Intended for first time setup.

This is applicable to anyone trying to scale metagenomic data preprocessing for many samples on a supercomputer. 
At UCLA, our HPC job scheduling system is the Univa Grid Engine, derived from Sun Grid Engine. Therefore, these commands carry over to other UGE job scheduling systems. 

Software versions used in this tutorial (Dec 2022)
- Metaphlan v4.0 
- Humann v3.6
- KneadData v0.10.0

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
To delete all jobs in queue:
```bash
qdel -u julianne
```
To transfer all files in a directory to your $SCRATCH directory in Hoffman:
```bash
scp -r .\JJ_pool1_S-23-0073_GAP506-380518546\ julianne@hoffman2.idre.ucla.edu:/u/scratch/j/julianne
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
Install HUMAnN 3.0 software with demo databases and Metaphlan 3.0. Also update all humann databases. Note path/to/database should be replaced with the directory to which you want to download databases. If ```conda install humann -c biobakery``` takes too long, it's a good idea to try ```pip install humann --no-binary :all:``` as suggested by Huttenhower Lab.

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

To merge metaphlan outputs (from Huttenhower Lab): 
```bash
merge_metaphlan_tables.py metaphlan_output*.txt > output/merged_abundance_table.txt
```

--------------------------------------
## Installing and running KneadData 


Anecdotally, I found that installation of package dependencies of kneaddata had a lot of issues, so I think it is safer to create a new environment separate from biobakery3 purely for kneaddata. 
```bash 
conda create --name kneaddata python=3.7
conda activate kneaddata
```

By default, installations are made in the $HOME directory. This is recommended. Anecdotally, I found kneaddata 0.12.0 does not work well for paired samples, instead thinking that all reads are unmatched between R1 and R2. Workaround solutions proposing to modify read headers by removing the space also did not resolve the issue.

```bash
pip install kneaddata==0.10.0
```

Alternatively, if the $HOME directory is full, download to SCRATCH. however, you will need to modify $PATH everytime you reestablish a new connection via ssh or you can permanently change $PATH via direct modification of a config file `.bash_profile` if you're using bash. if you're submitting job via `qsub` (versus running interactively) you probably want to modify `.bash_profile`, `.bashrc`, and `.condarc`.

```bash
pip install kneaddata -target /u/scratch/j/julianne
echo $PATH
export PATH=$PATH:/u/scratch/j/julianne/bin 
echo $PATH
```
Once you do that, you can check whether kneaddata has been installed properly by seeing whether `kneaddata` is a recognized command. 

Here are some errors you may receive:
- "Invalid or corrupt jar file" for Trimmomatic: 
![image](https://user-images.githubusercontent.com/62775127/208792025-9abd2d53-ea6a-4d36-a828-930021fc3c61.png)
Follow this solution (I got this from another user, https://forum.biobakery.org/t/kneaddata-installed-with-conda-is-not-available/4147)
```bash
cd ~/.conda/envs/kneaddata/lib/python3.10/site-packages/kneaddata/
nano config.py 
```
- "Unable to find trimmomatic. Please provide the full path"
![image](https://user-images.githubusercontent.com/62775127/208792482-c6febee7-808f-4e1e-acd7-a95654b940e2.png)
You will merely need to locate the filepath to trimmomatic, which is somewhere in $HOME:
```bash
find $HOME -name trimmomatic
```

Now, install the reference genomes that you will need for kneaddata (below is just for human genome):
```bash
mkdir kneaddata_databases
kneaddata_database --download human_genome bowtie2 kneaddata_databases
```
Run in an interactive session for a single pair of samples:
```bash
kneaddata --input1 CC42E_S279_L001_R1_001.fastq.gz --input2 CC42E_S279_L001_R2_001.fastq.gz --reference-db /u/scratch/j/julianne/kneaddata_databases --output CC42E_test_kneaddata --trimmomatic /u/home/j/julianne/.conda/pkgs/trimmomatic-0.39-hdfd78af_2/share/trimmomatic-0.39-2/
```

Run for a single pair of samples: 
```bash
qsub run_kneaddata.sh CC42E_S279_L001_R1_001.fastq.gz CC42E_S279_L001_R2_001.fastq.gz  
```

Run iteratively for many pairs of samples:
```bash
(kneaddata) -bash-4.2$ for f in *R1_001.fastq.gz; do name=$(basename $f R1_001.fastq.gz); qsub run_kneaddata.sh ${name}R1_001.fastq.gz ${name}R2_001.fastq.gz; done  
```

Move all kneaddata outputs to a new folders and remove all the intermediate files to save space:
```bash
mv *kneaddata* kneaddata_outputs
find . -type f -not -name '*data_paired_*' -print0 | xargs -0 -I {} rm -v {}
```

Concatenate paired kneaddata outputs into one fastq file for running Humann:
```bash
for f in *R1_001_kneaddata_paired_1.fastq; do name=$(basename $f R1_001_kneaddata_paired_1.fastq); cat ${name}R1_001_kneaddata_paired_1.fastq ${name}R1_001_kneaddata_paired_2.fastq > merged_${name}_kneaddata_paired.fastq; done
```

If the file size is large, concatenation can take longer. In this case, following code can be pasted in a *.sh file and submitted using qsub from the folder containg all kneaddata output folders.
```
find . -name "*R1_001_kneaddata_paired_1.fastq" | while read f; do
  dir=$(dirname $f)
  name=$(basename $f R1_001_kneaddata_paired_1.fastq)
  cat ${dir}/${name}R1_001_kneaddata_paired_1.fastq ${dir}/${name}R1_001_kneaddata_paired_2.fastq > merged_${name}_kneaddata_paired.fastq
done
```
---------
## Running Humann
Update to Metaphlan 4.0 if not already running 4.0 (check with `--version` parameter). This newer version should prevent getting the error "Warning: Unable to download https://www.dropbox.com/sh/7qze7m7g9fe2xjg/AAA4XDP85WHon_eHvztxkamTa/file_list.txt?dl=1. UnboundLocalError: local variable 'ls_f' referenced before assignment" and having to resort to finding workaround ways to download the file.

```bash
conda install -c bioconda metaphlan=4.0.0
```
Update to Humann 3.6 (very important- older version of humann are not compatible with metaphlan)
```bash
pip install humann --upgrade
```
If you receive this warning
"The scripts humann....are installed in '/u/home/j/julianne/.local/bin' which is not on PATH."
Modify the path variable as before if running interactively:
```bash
export PATH=$PATH:/u/home/j/julianne/.local/bin
```

Update `humann_config` file to the location of databases:
```bash
(humann) -bash-4.2$ humann_config --update database_folders nucleotide /u/scratch/j/julianne/humann_databases/chocophlan/
HUMAnN configuration file updated: database_folders : nucleotide = /u/scratch/j/julianne/humann_databases/chocophlan/
(humann) -bash-4.2$ humann_config --update database_folders protein /u/scratch/j/julianne/humann_databases/uniref/
HUMAnN configuration file updated: database_folders : protein = /u/scratch/j/julianne/humann_databases/uniref/
(humann) -bash-4.2$ humann_config --update database_folders utility_mapping /u/scratch/j/julianne/humann_databases/utility_mapping/
HUMAnN configuration file updated: database_folders : utility_mapping = /u/scratch/j/julianne/humann_databases/utility_mapping/
```

Run Humann on concatenated KneadData outputs: 
```bash
for file in *; do qsub ../../run_humann.sh $file; done
```
---------
## Helpful Commands

Move all files from various subdirectories to current directory:
```bash
find ./ -type f -print0 | xargs -0 mv -t ./
```
Find and delete empty directories from the current directory.
```
find . -empty -type d -delete
```
If jobs show "eqw" for some files and you need to move files starting alphabetically with some letter:
```bash
mv [XYZ]*.fastq.gz new_directory/
```
Move files containing filenames in txt file to a new folder
```bash
while IFS= read -r partial_filename; do mv *"$partial_filename"* rerun_humann; done < $SCRATCH/2023_001/rerun_humann.txt
```
Remove duplicates:
```bash
sort -u your_input_file.txt > no_duplicates_output_file.txt
```
Find items in txt file 2 that are not in txt file 1
```bash
grep -F -x -v -f file1.txt file2.txt > unique_filenames.txt
```
Filter out filenames containing R2
```bash
grep -v "_R2" filenames.txt > filtered_filenames.txt
```
Use cat and cut to modify filenames rapidly:
```bash
cat filenames.txt | cut -d'_' -f4-6 
```

Find all gene families, pathway abundance, and pathway coverage files in humann folder and copy them in a separate folders
```
find . -type f -name "*gene*" -exec cp {} genefamilies/ \;
find . -type f -name "*patha*" -exec cp {} pathabundance/ \;
find . -type f -name "*pathc*" -exec cp {} pathcoverage/ \;
```

For loop to clean-up the file names. Please change pathcoverage to genefamilies or pathabundance depending on the files you want to rename.
```
for file in merged_*_S*_L005__kneaddata_paired_pathcoverage.tsv; do
    newname=$(echo "$file" | sed 's/merged_//; s/_S[0-9]*_L005__kneaddata_paired_pathcoverage/_pathcoverage/')
    mv "$file" "$newname"
done

```

Remove everything before the first '_' from the file names

```
for file in *_*; do
    newname=$(echo $file | cut -d'_' -f2-)
    extension="${file##*.}"
    mv "$file" "$newname.$extension"
done
```

Remove everything after the second '_' from the file name

```
for file in *_*; do
    newname=$(echo $file | cut -d'_' -f1-2)
    extension="${file##*.}"
    mv "$file" "$newname.$extension"
done
```
