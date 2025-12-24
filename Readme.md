# Easy NetCDF Toolbox

 ## 1. Introduction

 This repository contains [MATLAB](https://www.mathworks.com) functions to simplify working with many [NetCDF](https://www.unidata.ucar.edu/software/netcdf/) files, primarily for oceanographic and geoscience use cases. The code is built on MATLAB's low-level NetCDF functions (see MATLAB's NetCDF documentation).

 ### Highlighted features

 - Load variables from a custom region across multiple files quickly.
 - Robust OpenDAP downloader with block-by-block transfer and automatic retry.

 ### New features (recent additions)

 - Enhanced multi-file region loader: `FUN_nc_varget_enhanced_region_2_multifile` — read subsets across many files and concatenate along a specified dimension.
 - Robust OpenDAP download: `FUN_nc_OpenDAP_with_limit` — supports chunked downloads and automatic retry on interruptions.
 - Easy NetCDF writers: `FUN_nc_easywrite*` family — quick helpers to create and write simple NetCDF files.
 - Time utilities: `FUN_nc_get_time_in_matlab_format` and related helpers to convert NetCDF time units to MATLAB datenum.
 - Presaved metadata/cache support: `FUN_nc_gen_presaved_netcdf_info*` — speeds up repeated reads from large file collections.
 - Merge and aggregation helpers: `FUN_nc_merge`, `FUN_nc_merge_save_mean` for combining datasets by time and computing means.

 ### Features

 - Load variables
   - Apply scale and offset and replace missing values automatically.
   - Convert time to MATLAB datenum format when requested.
   - Load subsets by longitude/latitude/time boundaries and from multiple files.
   - Load subsets by combining lon/lat/time boundaries and incontinuous indices from multiple files. [great for unconstructed grids]
   - Save/load dimension information to/from a cache file to improve performance when reading many files.

 - File operations
   - Extract a subset of a NetCDF file into a new file.
   - Download NetCDF files via OpenDAP with support for large datasets and automatic retry.
   - Merge files by time and compute means across merged files.

 - Write NetCDF files
   - Quick helpers to create and write simple NetCDF files (`FUN_nc_easywrite_*`). For complex NetCDF writing, prefer MATLAB's NetCDF library.

 ### Known issues

 - This toolbox does not support NetCDF groups. There is no plan to add group support in the near future.

 -----------------------------------------------

 ### File structure

 | Path                 | Notes                                                 |
 | -------------------- | ----------------------------------------------------- |
 | ./                   | Functions for the current version                     |
 | ./private            | Private helper functions used by the toolbox (invisible to other functions outside of this toolbox)                 |
 | ./Documents_and_demo | Demo files and documentation                           |
 | ./Archive            | Older code; not recommended for normal use             |

 #### Frequently used functions

 - `FUN_nc_varget_enhanced_region_2_multifile` : Read a subset of a variable from multiple files (recommended)
 - `FUN_nc_varget_enhanced`                    : Read a variable from one file with scale/offset/missing-value handling
 - `FUN_nc_varget_enhanced_region_2`           : Read a subset of a variable from one file by named dimensions
 - `FUN_nc_get_time_in_matlab_format`          : Convert NetCDF time variable to MATLAB datenum
 - `FUN_nc_OpenDAP_with_limit`                 : Robust OpenDAP downloader with chunking and retry

 ------------------------------------------------

 ### How to add this package to the MATLAB path

 Add the toolbox root folder to MATLAB's search path. Do not add `private`, `Documents_and_demo`, or `Archive` to the path.

 #### GUI (MATLAB Desktop)

Click "Home tab> Set Path". It will open a dialog for setting the path. Then, click "Add Folder...", add the root path of this package (the folder contains a lot of functions, including `FUN_nc_varget.m`), then click "Save" near the bottom of the dialog.  

 #### Command line

 - Method 1 (recommended):

 ```matlab
 addpath('/path/to/Easy_NetCDF');
 savepath
 ```

 - Method 2:
  MATLAB runs `startup.m` (if it exists in the search path) automatically during startup. Thus, adding an `addpath` call to `startup.m` also works.

 ----
## 2. Read data from NetCDF file(s)

Several functions in this package were written for this purpose, all of which (except `FUN_nc_varget`) can be replaced by `FUN_nc_varget_enhanced_region_2_multifile`.



***[New]*** You can load all variables from a single NetCDF file by this

```matlab
data =  FUN_nc_load_all_variables( fn );
```

, where `fn` is the name of the NetCDF file.  

or  

```matlab
data =  FUN_nc_load_all_variables( fn, 'time_var_name', var_time );
```

which will convert the time variable (`var_time`) to MATLAB unit (days since 0000-01-00 00:00) according to its `units` property. 



### 2.1 Read a variable from one NetCDF file

#### 2.1.1 Read data in its original type and values

 **`data = FUN_nc_varget( filename, varname );`**

+ `offset` will not be applied

+ `scale` will not be applied

+ `missing values` will not be replaced with NaN.

+ Loaded data will keep its original type as in the NetCDF file.

##### INPUT

+ filename: path to a specific NetCDF file     
+ varname : name of the variable to be read     

##### OUTPUT

+ data: values read from the NetCDF file. 

##### Example

```matlab
data = FUN_nc_varget( 'Demo_SST_2001.nc', 'sst');
```

#### 2.1.2  Apply scales, add_offsets and _FillValues to the raw data

 **`data = FUN_nc_varget_enhanced( filename, varname );`**

This is the recommended command for loading one variable from one file.

+ `offset` will be applied
+ `scale` will be applied
+ `missing values` will be replaced with NaN
+ Data will be converted to `double`.

##### INPUT

+ filename: path to a specific NetCDF file     
+ varname : name of the variable to be read     

##### OUTPUT

+ data: values read from the NetCDF file. 

##### Example

```matlab
data = FUN_nc_varget_enhanced( 'Demo_SST_2001.nc', 'sst');  
```

### 2.2 Read a subset of a variable from one NetCDF file

#### 2.2.1 Specify the subset boundary by [start, count stride];

 **`data = FUN_nc_varget_enhanced_region( filename, varname, start, count, stride);`**    

+ Read a part of the domain.
+ `offset` will be applied
+ `scale` will be applied
+ `missing values` will be replaced with NaN
+ Loaded data will be converted to `double`

##### INPUT

+ filename: path to a specific NetCDF file     

+ varname : name of the variable to be read     

+ start, count, stride: same as [this document for `netcdf.getVar`](https://www.mathworks.com/help/matlab/ref/netcdf.getvar.html)
  
  ##### OUTPUT

+ data: values read from the NetCDF file. 

##### example

```matlab
% parameters
fn = 'Demo_SST_2001.nc';
lonlimit = [-110 -20];
latlimit = [15 70];

% read lon/lat
lon = FUN_nc_varget_enhanced( fn, 'lon' );
lat = FUN_nc_varget_enhanced( fn, 'lat' );

% calculate [start, count] from range for lon/lat.
[x_start, x_count, xloc] = FUN_nc_varget_sub_genStartCount( lon, lonlimit );
[y_start, y_count, yloc] = FUN_nc_varget_sub_genStartCount( lat, latlimit );

nc_start = [ x_start, y_start, 0 ] % the third value is for time. 
nc_count = [ x_count, y_count, 1 ] 
nc_stride= [1, 1, 1];

% load data
data = FUN_nc_varget_enhanced_region( fn, 'sst', nc_start, nc_count, nc_stride);
```

#### 2.2.2 Specify the subset boundary by longitude, latitude, ...

 **`[ out_dim, data ] = FUN_nc_varget_enhanced_region_2( filename, varname, dim_name, dim_limit, [time_var_name], [dim_varname] );`**    

 **This can also be done by "FUN_nc_varget_enhanced_region_2_multifile.m".**

+ Load a part of the domain.
+ `offset` will be applied.
+ `scale` will be applied.
+ `missing values` will be replaced with NaN.
+ Loaded data will be converted to `double`.

##### INPUT

+ filename  [char]: name of the NetCDF file (e.g., 'temp.nc')       

+ varname   [char]: name of the variable (e.g., 'sst' or 'ssh')    

+ dim_name  [cell]: name of dimensions related to the variable specified above, like {'lon'}, {'lon','lat'}, {'lon', 'lat', 'depth, 'time'}. Dimensions with custom limits must be listed here. Other dimensions are optional.

+ dim_limit [cell]: limits of dimensions in a cell. (e.g., {[-85 -55 ], [-inf inf]}). Please provide limits in the same order as they are listed in `dim_name`.

+ time_var_name [char, optional]: name of the variable for time.    
  
  - **If this is not empty, the limit for time in `dim_limit` can be given in a "MATLAB units" (days since 0000-01-00 00:00) or created by `datenum`.**
  - If this is not empty, the time in `out_dim` will be given in "MATLAB units" (days since 0000-01-00 00:00).

+ dim_varname   [cell, optional]: name of the variable defining the axis at each dimension.    
  
  - by default, each axis is defined by a variable sharing the same name. For example, the axis `lon` should be accompanied by a variable named `lon`. In such a case, the `dim_varname` should be left empty.
  
  - If the axis is defined by a variable with a different name, the name of the variable should be specified manually here. For example, the meridional dimension in 'Demo_SST_2001.nc' is named "y". However, the latitude is defined by a variable `lat`. In such a situation: 
    
    ```matlab
     fn = 'Demo_SST_2001.nc'
     dim_name={'lon','y'}; 
     dim_limit = { [-110 -20],  [15 70]}; 
     time_var_name='time';
     dim_varname={'lon','lat'}
     varname='sst'
     [ out_dim, data ] = FUN_nc_varget_enhanced_region_2( fn, 'sst', dim_name, dim_limit, time_var_name, dim_varname );
    ```
    
    - "`dim_varname{1} = nan` indicates that the axis is not defined by any variable in the file. Thus, it will be defined as 1, 2, 3, ... Nx, where Nx is the length of the dimension.    

##### OUTPUT

+ out_dim  : dimension info (e.g., longitude, latitude, if applicable)    
+ data     : data extracted from the given NetCDF file.     
  + When `time_var_name ` is not empty, the corresponding variable in `out_dim` is converted to the same format as `datenum`. However, this unit conversion will never be applied to the output variable `data`. If you want to read the time variable itself, please use `FUN_nc_get_time_in_matlab_format`.

##### example 1: Read May 2001 SST between 110W-20W, 15N-70N

```matlab
fn            = 'Demo_SST_2001.nc';
dim_name      = {'lon','y', 'time'}; 
dim_limit     = { [-110 -20],  [15 70], [datenum(2001,5,1) datenum(2001,5,31)] }; 
time_var_name = 'time';
dim_varname   = {'lon','lat','time'};
varname       = 'sst';
[ out_dim, data ] = FUN_nc_varget_enhanced_region_2( fn, 'sst', dim_name, dim_limit, time_var_name, dim_varname );

% Plot
%FUN_MAP_pcolor_lonlat_quick( lon, lat, data(:,:,1)');
pcolor( out_dim.lon, out_dim.lat, data' );
cbar = colorbar;
shading interp
title(datestr(out_dim.time))
```

##### example 2: Read SST between 180W-180E, 0N-50N in the second month of 2001

`dim_varname{2}` is set to nan to read the second record in time. 

```matlab
fn            = 'Demo_SST_2001.nc';
dim_name      = { 'y' 'time'}; 
dim_limit     = { [0 50],  [2,2] }; 
time_var_name = [];
dim_varname   = {'lat', nan}; 
varname       = 'sst';
[ out_dim, data ] = FUN_nc_varget_enhanced_region_2( fn, 'sst', dim_name, dim_limit, time_var_name, dim_varname );

% Plot
pcolor( out_dim.lon, out_dim.lat, data' );
cbar = colorbar;
shading interp
axis equal
%title(datestr(out_dim.time))
```

### 2.3 <mark>**Read a variable from multiple NetCDF files**</mark>

 **`[ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname );`**    

+ Load a variable across several files.
+ Load a part of the domain.
+ `offset` will be applied.
+ `scale` will be applied.
+ `missing values` will be replaced with NaN.
+ Loaded data will be converted to `double`.

##### INPUT:

     filelist  [struct array]: name and folder of the NetCDF file
                filelist must include two attributes: `name` and `folder`. For   
                each element of filelist (e.g. the ith one), the full path
                will be generated by fullfile( filelist(ith).folder, filelist(ith).name)
    
                It can also be a cell array contain paths of files,
                   or a char matrix, each row of which contains one path.
    
     varname   [char]: name of the variable
    
     dim_limit_str   [cell]: name of dimensions, like {'lon','lat'}. Dimensions with custom limits must be listed here. Other dimensions are optional.
    
     dim_limit_limit [cell]: limits of dimensions, like {[-85 -55], [30 45]}.
    
     merge_dim_name [string]: name of the dimension in which the variables 
                from different files will be concatenated. If merge_dim_name is
                empty, the variable will be concatenated after its last
                dimension.
    
                + Example 1: if you want to read gridded daily
                  temperature given in [lon, lat, depth, time] from a set of
                  files, and each file contains temperature in one day,
                  the merge_dim_name should be 'time'. 
    
                + Example 2: if you want to read gridded daily temperature given in
                  [lon, lat, depth], in which time is not given
                  explicitly in each file, you can leave merge_dim_name
                  empty.
    
     time_var_name [char, optional]: name of the time axis
          + variable defined by this will be loaded into time in "MATLAB units" (days since 0000-01-00)
          + This is helpful for setting timelimit in a easy way, avoiding
            calculating the timelimit from units in NetCDF files.
            For example, to read data between 02/15/2000 00:00 and
            02/16/2000 00:00 from a NetCDF file, which includes a time variable "ob_time" 
            in units of "days since 2000-00-00 00:00", you need to set 
            timelimit as [46 47] when time_var_name is empty. However, you
            should set timelimit as [datenum(2000,2,15),
            datenum(2000,2,16)] if the tiem_var_name is set to "ob_time".
    
    dim_varname   [cell, optional]: name of the variable defining the axis at each dimension.
          + by default, each axis is defined by a variable sharing the same name as the dimension. 
          + "`dim_varname{1} = nan` indicates that the axis is not defined by any variable in file. It will be defined 
               as 1, 2, 3, ... Nx, where Nx is the length of the dimension.

##### OUTPUT:

     out_dim  : dimension info (e.g., longitude, latitude, if applicable)
     data     : data extracted from the given NetCDF file.  

##### Example 1: Read SST from Dec 2001 to May 2003

```matlab
filelist       = dir('Demo_*.nc');
varname        = 'sst';
dim_name       = { 'time' };
dim_limit      = { [datenum(2001,12,1) datenum(2003,5,31)] };
merge_dim_name = 'time';
time_var_name  = 'time';
dim_varname = [];

[ out_dim, data ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname );
```

**Note:** filelist can also be a cell like this

```matlab
filelist = {    'Demo_SST_2001.nc'
    'Demo_SST_2002.nc'
    'Demo_SST_2003.nc'
    'Demo_SST_2004.nc'
    'Demo_SST_2005.nc'
    'Demo_SST_2006.nc'
    'Demo_SST_2007.nc'
    'Demo_SST_2008.nc'
    'Demo_SST_2009.nc'
    'Demo_SST_2010.nc'};
```

or char array like this

```
filelist = ['Demo_SST_2001.nc'
            'Demo_SST_2002.nc'
            'Demo_SST_2003.nc'
            'Demo_SST_2004.nc'
            'Demo_SST_2005.nc'
            'Demo_SST_2006.nc'
            'Demo_SST_2007.nc'
            'Demo_SST_2008.nc'
            'Demo_SST_2009.nc'
            'Demo_SST_2010.nc'];
```

##### Example 2: Read SST from Dec 2001 to Nov 2003 in Northwest Atlantic

```matlab
filelist       = dir('Demo_*.nc');
varname        = 'sst';
dim_name       = { 'lon', 'y', 'time' }; % In the demo files, the meridional dimension is named as "y".
dim_limit      = { [-110 -20],  [15 70], [datenum(2001,12,1) datenum(2003,11,30)] };
merge_dim_name = 'time'; % merge data in "time" dimension.
time_var_name  = 'time'; % convert values in "time" to MATLAB units (days since 0000-01-00 00:00).
dim_varname    = {'lon','lat','time'}; % This is to force the function to read values for the meridional dimension from the variable "lat".

[ out_dim, data ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname );
```

### 2.4 Read a subset from hundreds of files quickly

> **Notes: **  ==`FUN_nc_gen_presaved_netcdf_info` is replaced by `FUN_nc_gen_presaved_netcdf_info_v2` introduced in v1.50-beta.== The new version saves the dimensional information in a new format ('v2'), dropping a lot of unnecessary information. The output .mat file is 10 times smaller than the previous one, with better performance, and related functions have been updated to support the new format.  



It might be slow to read a subset of data from hundreds of files by provide a list of all files for `FUN_nc_varget_enhanced_region_2_multifile`. The function needs to open every single file for some dimensional information. To speed up this command, an alternative is to read and save the dimensional information beforehand. Then, providing the pre-saved information to `FUN_nc_varget_enhanced_region_2_multifile`. 

The dimensional information can be generated by `FUN_nc_gen_presaved_netcdf_info` and an example is shown below:

```matlab
%% generate info -----------------------------------------------------------

    filelist       = dir('Demo_*.nc');
    merge_dim_name = 'time'; % merge data in "time" dimension.
    dim_name       = { 'lon', 'y', 'time' }; % In the demo files, the meridional dimension is named as "y".
    dim_varname    = {'lon','lat','time'}; % This is to force the function to read values for the meridional dimension from the variable "lat". 
    time_var_name  = 'time'; % convert values in "time" to MATLAB units (days since 0000-01-00 00:00). This is optional

    output_file_path = 'Presaved_info_demo.mat';

    % Please note that **absolute** file paths are saved in the generated file. If you moved the data, you need to run this again
    pregen_info = FUN_nc_gen_presaved_netcdf_info_v2( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path );

%% read data --------------------------------------------------------------
    varname        = 'sst';
    dim_name       = { 'time' };
    dim_limit      = { [datenum(2001,12,1) datenum(2003,5,31)] };
    merge_dim_name = 'time';

    presaved_info = load(output_file_path);
    presaved_info = presaved_info.pregen_info;

    [ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2_multifile( presaved_info, varname, dim_name, dim_limit);
```

## 3. Download files and merge files

### <mark>3.1 Download NetCDF files via OpenDAP (`FUN_nc_OpenDAP_with_limit`)</mark>

**`FUN_nc_OpenDAP_with_limit( filename0, filename1, dim_limit_var, dim_limit_val, var_download, var_divided, divided_dim_str, Max_Count_per_group, ...  )`**

+ Supports large datasets.
+ Retries automatically after interruptions.
+ Downloads data piece by piece.
+ Downloads a subset of the original file.

##### INPUT:

     filename0     : source of the NetCDF file (OpenDAP URL here)    
     filename1     : Name of output NetCDF file    
     dim_limit_var : which axes you want to set the limit    
     dim_limit_val : the limit of each axis    
     var_download  : the variable you'd like to download. [var_download = [] will download all variables.]    
    
     var_divided   : the variables that need to be downloaded piece by piece in a specific dimension. In many cases, OpenDAP may not respond if you try to download too much data at once. A solution for this is to download data piece by piece 
    
    divided_dim_str: which dimension you'd like to download piece by piece (e.g., 'time', or 'depth'). divided_dim_str = []  means all variables will be downloaded completely at once.   
    
     Max_Count_per_group: Max number of points in the divided dimension.   

##### Optional parameters:

| Parameter                  | Default value  | note                                                           |
| -------------------------- | -------------- | -------------------------------------------------------------- |
| dim_varname                | dim_limit_name | Names of variables defining dimensions given in dim_limit_name |
| time_var_name              | []             | Name of the variable describing time                           |
| is_auto_chunksize          | false          | Calculate chunk size by a function in this package (beta)      |
| compression_level          | 1              |                                                                |
| is_skip_blocks_with_errors | false          |                                                                |
| N_max_retry                | 10             |                                                                |
| var_exclude                | []             |                                                                |

##### Output

    N/A

 Notice: To recognize the axis correctly, there must be one variable named the same as the axis. Assigning a variable to a specific axis is not yet supported. 

##### Example 1: download a subset of HYCOM data from its OpenDAP server

```matlab
% HYCOM dataset at an OpenDAP server
filename0 = 'http://tds.hycom.org/thredds/dodsC/GLBu0.08/expt_19.1/2012';

% output filename
filename1 = 'HYCOM_test2.nc';

% calculate time limits
 timelimit  = [datenum(2012,1,1) datenum(2012,1,3)];

 time = FUN_nc_varget(filename0,'time');
 time_unit = FUN_nc_attget(filename0,'time','units');
 [time0, unit_str, unit_to_day] = FUN_nc_get_time0_from_str( time_unit );

 timelimit  = (timelimit - time0)/unit_to_day ;

% set limits
 lonlimit = [-76 -70 ];
 latlimit = [32 39];
 depthlimit = [0 100];

 dim_limit_var = {'lon','lat','depth','time'};
 dim_limit_val = {lonlimit, latlimit depthlimit timelimit};

% variable to be downloaded
 var_download = {'water_temp','lon','lat','depth','time'}; % empty indicates downloading all variables

% Variables that should be downloaded block by block
 var_divided  = {'water_temp'};

% which dim you'd like to download block by block (e.g., 'time', or 'depth')
divided_dim_str = 'depth'

% max size of each "piece"
Max_Count_per_group = 5;

 FUN_nc_OpenDAP_with_limit( filename0, filename1, dim_limit_var, dim_limit_val, var_download, var_divided, divided_dim_str, Max_Count_per_group  )
```

##### Example 2: A new template

```matlab
% HYCOM dataset at an OpenDAP server
opendapURL = 'http://tds.hycom.org/thredds/dodsC/GLBu0.08/expt_19.1/2012';

% output filename
filename_out = 'HYCOM_test1.nc';

% calculate time limits
 timelimit  = [datenum(2012,1,1) datenum(2012,1,3)];
 time_varname = 'time'; %Tell the code which variable contains time

% set limits
 lonlimit   = [-76 -70 ];
 latlimit   = [32 39];
 depthlimit = [0 100];

 dim_limit_var = {'lon',   'lat',    'depth',    'time' };
 dim_limit_val = {lonlimit, latlimit, depthlimit, timelimit};

% variable to be downloaded
 var_download = {'water_temp','lon','lat','depth','time'}; % empty indicates downloading all variables

% Variables that should be downloaded block by block
 var_divided  = var_download;
 

% which dim you'd like to download block by block (e.g., 'time', or 'depth')
divided_dim_str = 'depth';

% max size of each "piece"
N_divided_rec_per_group = 2;

 FUN_nc_OpenDAP_with_limit( opendapURL, filename_out, dim_limit_var, dim_limit_val, var_download, var_divided, divided_dim_str, N_divided_rec_per_group, 'time_var_name', time_varname);
```



### 3.2 Merge multiple NetCDF files in time (`FUN_nc_merge`)

`FUN_nc_merge( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode )`

##### INPUT:

     input_dir: The folder in which all input NetCDF files given by `filelist` are located.
     filelist : the list of files which will be merged. This should be generated by the MATLAB built-in command `dir`.      
                This function will merge the NetCDF files following the order given in this variable. Please make sure this variable has been sorted properly.
     output_fn : Name of output NetCDF file
     merge_dim_name : name of the dimension in which all variables will be merged.
     compatibility_mode: 
                compatibility_mode = 1: write netCDF in 'CLOBBER'; Compression would be disabled.
                compatibility_mode = 0: write netCDF in 'NETCDF4'.

##### Output:

N/A

**Note** 

+ To recognize the axis correctly, there must be one variable named as by the axis!
+ Variables without the dimension `merge_dim_name` will be copied from the first file given in the variable filelist
+ The time in the merged file may not be correct if the time units vary between files.

#### Example

```matlab
% input_dir: path for the folder containing the files
    input_dir = '.';
% filelist
    filelist  = dir(fullfile(input_dir,'Merge_Demo*.nc'));
% output filename
    output_fn = 'Merged_Output.nc';

% name of the demension to be merged.
merge_dim_name = 'time';

% compatibility_mode:
%     compatibility_mode = 1: write netCDF in 'CLOBBER'; Compression would be disabled.
%     compatibility_mode = 0: write netCDF in 'NETCDF4'.
compatibility_mode = 0;

strvcat( filelist(:).name )

FUN_nc_merge( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode )
```

### 3.3 FUN_nc_merge_save_mean

FUN_nc_merge_save_mean( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode, list_var_excluded )

```matlab
% input_dir: path for the folder containing the files
    input_dir = '.';
% filelist
    filelist  = dir(fullfile(input_dir,'Merge_Demo*.nc'));
% Output filename
    output_fn = 'Merged_Output_mean.nc';

% Name of the demension to be merged.
    merge_dim_name = 'time';

% compatibility_mode:
%     compatibility_mode = 1: write netCDF in 'CLOBBER';
%     compatibility_mode = 0: write netCDF in 'NETCDF4';
    compatibility_mode = 0;

% Variable should not be included in the output file.
    list_var_excluded = [];

% Execute
FUN_nc_merge_save_mean( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode, list_var_excluded );
```

## 4. Write NetCDF Files

### 4.1 `FUN_nc_easywrite_enhanced`

FUN_nc_easywrite_enhanced( filename, dim_name, dim_length, varname, dimNum_of_var, data, global_str_att )

##### INPUT

     filename [char]: name of the output NetCDF file (e.g., 'test.nc')
     dim_name [cell]: names of dimensions (e.g., {'lon','lat'}
     dim_length [array]: length of each dimension (e.g., [ 360, 180 ] )
     varname [cell]: names of variables (e.g., {'lon','lat','sst','ssh'}
     dimNum_of_var [cell]: dimensional ID for each variable (e.g., `{ 1, 2, [1,2],[1,2]}`). A value of 1 indicates the first dimension in `dim_name`, 2 indicates the second, and so on.
     data [cell]: values for each variable (e.g., {lon,lat,sst,ssh})
     global_str_att: global attribute

### Optional paramaters

| Parameter                  | Default value  | note                                                           |
| -------------------------- | -------------- | -------------------------------------------------------------- |
| dim_varname                | dim_limit_name | Names of variables defining dimensions given in dim_limit_name |
| time_var_name              | []             | Name of the variable describing time                           |
| is_auto_chunksize          | false          |                                                                |
| compressiion_level         | 1              |                                                                |
| is_skip_blocks_with_errors | false          |                                                                |
| N_max_retry                | 10             |                                                                |
| var_exclude                | []             |                                                                |

##### OUTPUT

     N/A

```matlab
% ---- generate random data ----
lon  = [-75:-55] ;
lat  = [26 : 55] ;
depth= [0:5:100] ;

temp  = rand( length(lon), length(lat), length(depth) );

%%  ---- write nctCDF ----
filename      = 'Test_random_values.nc';
dim_name      = {'lon','lat','depth'};
dim_length    = [length(lon), length(lat), length(depth)];

varname       = {'temp', 'lon','lat','depth'};
dimNum_of_var = {[1,2,3], 1,     2,     3   };
data          = { temp, lon, lat, depth };
global_att    = 'This is a test.';

FUN_nc_easywrite_enhanced( filename, dim_name, dim_length, varname, dimNum_of_var, data, global_att )

%    FUN_nc_easywrite_enhanced('temp.nc',...
%                       {'Node','Cell','time'},[1000 2000 500],...
%                       {'node_lon','node_lat','lon_cell','lat_cell','sst'},{1,1,2,2,[1 3]},...
%                       {lon_node,lat_node,lon_cell,lat_cell,sst},'This is an example');
```

*[`ncwriteschema`](https://www.mathworks.com/help/matlab/ref/ncwriteschema.html) would be a better choice to write a more complex NetCDF file from structures.

### 4.2 Other functions for writting a NetCDF file

+ `FUN_nc_easywrite_add_var`: add a variable to an existing NetCDF file
+ `FUN_nc_easywrite_add_att`: add an attribute to an existing variable in an existing NetCDF file.
+ `FUN_nc_easywrite`: write one variable into a new NetCDF file. 
+ `FUN_nc_easywrite_write_var`: replace values of an existing variable in an existing NetCDF file.

----

<mark>**Output of some examples above can be found [here](./Documents_and_demo/Readme.md)**</mark>