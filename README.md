# Puerto Rico Project LIDAR

R scripts are standalone snippets to do specific steps. The code in the 'functions' folder are useful functions.

## Future

Uses the `future` project for parallelization. Userful links:

https://search.r-project.org/CRAN/refmans/future/html/grapes-seed-grapes.html

https://cran.r-project.org/web/packages/future/vignettes/future-1-overview.html

Some `future` examples:

https://future.futureverse.org/articles/future-3-topologies.html#example-a-remote-compute-cluster

### Error I got from `future`:

MultisessionFuture (<none>) failed to receive results from cluster RichSOCKnode #2 (PID 2843940 on ‘localhost’). The reason reported was ‘error reading from connection’. Post-mortem diagnostic: Detected a non-exportable reference (‘externalptr’) in one of the globals (‘class_nsgnd’ of class ‘function’) used in the future expression. The total size of the 2 globals exported is 515.52 KiB. There are two globals: ‘ctg’ (505.73 KiB of class ‘S4’) and ‘class_nsgnd’ (9.80 KiB of class ‘function’)
In addition: Warning messages:
1: In serialize(x, connection = con, ascii = FALSE, xdr = FALSE, refhook = refhook) :
  'package:stats' may not be available when loading
2: In serialize(x, connection = con, ascii = FALSE, xdr = FALSE, refhook = refhook) :
  'package:stats' may not be available when loading

https://stackoverflow.com/questions/46186375/r-parallel-error-in-unserializenodecon-in-hpc

* Here, the comment might be helpful: "The error message itself - `Error in unserialize(node$con) : error reading from connection` suggests that one or more of the workers have died.""