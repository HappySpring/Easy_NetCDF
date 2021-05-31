# Easy Netcdf Toolbox
      
----
       
<mark>**More details can be found [here](./Documents_and_demo/Readme.md)**</mark>

## Introduction

This is a set of [matlab](https://www.mathworks.com) functions to make it easier for oceanographers to handle large sets of [NetCDF](https://www.unidata.ucar.edu/software/netcdf/) files. The functions are built on the low-level Matlab [NetCDF library package](https://www.mathworks.com/help/matlab/network-common-data-form.html?s_tid=CRUX_lftnav).

### highlighted Features

+ Load varialbes in a customed region across multiple files quickly.
+ Enhanced feature for downloadeding NetCDF files via OpenDAP.

### Features

+ load variables
  - Correct scales, offsets, missing values automatically 
  - Load time in matlab format (days since 0000-01-00 00:00:00)
  - Load a subset of a variable by specifying the longitude, latitude, time, etc. instead of indexes in a N-D array. 
  - Load variable from multiple files automatically
  - Load dimensional information from a cache file, which can speed up the codes significantly when it reads a large datasets from multiple files.

+ File operations
  - Copy with limits (compression)
  - Flexible Download with OpenDAP
    * support large datasets
    * Retry automatically after interruptions. 
  - Merge files by time
  - Merge files by time (save mean values)

+ write NetCDF files
  - Write simple NetCDF files quickly. (The support for writting NetCDF files is not the coral propose of this toolbox. Please use the  Matlab [NetCDF library package](https://www.mathworks.com/help/matlab/network-common-data-form.html?s_tid=CRUX_lftnav) for writting complex files.

### Know problems

+ Do not support groups. It should not be hard to add this. However, all files I use in my research come without groups. So there is not plan to add this feature.

-----------------------------------------------

### File Structure 

| Path                 | Notes                                                 |
| -------------------- | ----------------------------------------------------- |
| ./                   | Functions for current version                         |
| ./private            | Other functions called by this toolbox                |
| ./Documents_and_demo | some documents file and the netcdf files used in demo |
| ./Archive            | Some old codes, They shoud not be used.               |

#### Frequently used functions

+ `FUN_nc_varget_enhanced_region_2_multifile` : Read a subset of a variable from multiple files
+ `FUN_nc_varget_enhanced`                    : Read a variable from one file
+ `FUN_nc_varget_enhanced_region_2`           : Read a subset of a variable from one file
+ `FUN_nc_get_time_in_matlab_format`          : Read time variable into matlab unit (`days since 0000-01-00 00:00`)
+ `FUN_nc_OpenDAP_with_limit`                 : Download via OpenDAP


------------------------------------------------

### How to install this to matlab environment

You need to add this to the searching path of your Matlab. It can be done by two ways:

#### If you use a GUI version: 

Click "Home tab> Set Path". It will open a dialog for setting the path. Then, click "Add Folder...", add the root path of this package (the folder contains a lot of functions, including `FUN_nc_varget.m`), then click "Save" near the bottom of the dialog.  

#### If you use a command line environment

+ Method 1 (recommended):

  ```
  addpath('/path/to/Easy_netcdf/');
  savepath
  ```

+ Method 2: 
  Matlab will run `startup.m` during boot automatically if the file exists. Thus, you can add `addpath('/path/to/Easy_netcdf/');` to the `startup.m` file and make sure that the `startup.m` is put in existing searching path. This provide more flexibility.

----



