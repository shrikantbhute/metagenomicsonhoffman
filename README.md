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

Can see what modules are available via 
```bash
all_apps_via_modules
```
We will likely only need anaconda. However, every time you need anaconda, need to rerun module load.
```bash
module load anaconda3
```
Now, can follow instructions on Huttenhower Lab to download humann and metaphlann. Reposted below for convenience, from https://huttenhower.sph.harvard.edu/humann.
