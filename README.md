# Metagenomics on Hoffman
Jacobs Lab: Run kraken and bracken on the UCLA supercomputer


For example, to request 4 CPU core, a runtime of 8 hours, and 2GB of memory per core, issue:

```bash
qrsh -l h_rt=8:00:00,h_data=2G,h_vmem=8G -pe shared 4
```
