library(rslurm)

# parallelization 
slurmparam <- data.frame(lasflight=farms21)

flightmetadf <- slurm_apply(f=classlas, params=slurmparam,
                            lasfolder=laspath21, class.params=pmfparam,
                            nodes = 4, cpus_per_node = 16)