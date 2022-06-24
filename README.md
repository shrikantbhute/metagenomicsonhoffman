# Metagenomics on Hoffman
Jacobs Lab: Run Humann and Metaphlann on the UCLA supercomputer

Connect to Hoffman Cluster
```bash
ssh julianne@hoffman2.idre.ucla.edu
```
You are now connected to the login node. Now, you can open an interactive session via qrsh. 

For example, to request 4 CPU core, a runtime of 8 hours, and 2GB of memory per core, issue:

```bash
qrsh -l h_rt=8:00:00,h_data=2G,h_vmem=8G -pe shared 4

qrsh -l h rt=2:00:00, h_data=20G
```
