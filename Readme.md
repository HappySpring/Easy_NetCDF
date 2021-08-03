# Easy Netcdf Toolbox


## 1. Introduction

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
  - Extract a subset of a NetCDF file into a separate one.
  - Flexible Download via OpenDAP
    * support large datasets, variable can be downloaded block by block
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

----

## 2. Read data from netcdf file(s)

Several functions in this package were written for this purpose, all of which, except `FUN_nc_varget`, can be replaced by `FUN_nc_varget_enhanced_region_2_multifile`.

### 2.1 Read a variable from one NetCDF file



#### 2.1.1 Read data in its original type and values

 **`data = FUN_nc_varget( filename, varname );`**

+ `off_set` will not be applied

+ `scale` will not be applied

+ `missing values` will not be replaced by NaN.

+ Loaded data will keep its original type as in the netcdf file.


##### INPUT
+ filename: path to a specific netcdf file     
+ varname : name of the variable to be read     

##### OUTPUT
+ data: values read from the netcdf file. 

##### Example

```matlab
data = FUN_nc_varget( 'Demo_SST_2001.nc', 'sst');
```



#### 2.1.2  Apply scales, add_offsets and _FillValues to the raw data

 **`data = FUN_nc_varget_enhanced( filename, varname );`**

This is the recommended command for loading one variable from one file.

+ `off_set` will be applied
+ `scale` will be applied
+ `missing values` will be replaced by nan
+ Data will be converted to `double`.

##### INPUT
+ filename: path to a specific netcdf file     
+ varname : name of the variable to be read     

##### OUTPUT
+ data: values read from the netcdf file. 

##### Example

```matlab
data = FUN_nc_varget_enhanced( 'Demo_SST_2001.nc', 'sst');  
```



### 2.2 Read a subset of a variable from one netcdf file

#### 2.2.1 Specify the subset boundary by [start, count stride];

 **`data = FUN_nc_varget_enhanced_region( filename, varname, start, count, stride);`**    

+ Read a part of the domain.
+ `off_set` will be applied
+ `scale` will be applied
+ `missing values` will be replaced by nan
+ Loaded data will be converted to `double`

##### INPUT
+ filename: path to a specific netcdf file     
+ varname : name of the variable to be read     
+ start, count, stride: same as [this document for `netcdf.getVar`](https://www.mathworks.com/help/matlab/ref/netcdf.getvar.html)
##### OUTPUT
+ data: values read from the netcdf file. 

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
+ `off_set` will be applied.
+ `scale` will be applied.
+ `missing values` will be replaced by nan.
+ Loaded data will be converted to `double`.

##### INPUT
+ filename  [char]: name of the NetCDF file (e.g., 'temp.nc')       
+ varname   [char]: name of the variable (e.g., 'sst' or 'ssh')    
+ dim_name  [cell]: name of dimensions related to the variable spcified above, like {'lon'}, {'lon','lat'}, {'lon', 'lat', 'depth, 'time'}. Dimensions with customed limits must be listed here here. Other dimensions are optional.
+ dim_limit [cell]: limits of dimensions in a cell. (e.g., {[-85 -55 ], [-inf inf]}). Please provide limits in the same order as they are listed in `dim_name`.
+ time_var_name [char, optional]: name of the variable for time.    
  - **If this is not empty, the limit for time in `dim_limit` can be given in a "matlab units" (days since 0000-01-00 00:00) or created by `datenum`.**
  - If this is not empty, the time in `out_dim` will be given in "matlab units" (days since 0000-01-00 00:00).

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
  
   - "dim_varname{1} = nan" indicates that the axis is not defined by any variables in file. Thus, it will be defined as 1, 2, 3, ... Nx, where Nx is the length of the dimension.    

##### OUTPUT
+ out_dim  : dimension info (e.g., longitude, latitude, if applicable)    
+ data     : data extracted from the given netcdf file.     

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




### 2.3 <mark>**Read a variable from multiple Netcdf files**</mark>

 **`[ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname );`**    

+ Load a variable across several files.
+ Load a part of the domain.
+ `off_set` will be applied.
+ `scale` will be applied.
+ `missing values` will be replaced by nan.
+ Loaded data will be converted to `double`.

##### INPUT:
     filelist  [struct array]: name and folder of the NetCDF file
                filelist must include 2 attributes, name and folder. For   
                each element of filelist (e.g. the ith one), the full path
                will be generated by fullfile( filelist(ith).folder, filelist(ith).name)
                               
                It can also be a cell array contain paths of files,
                   or a char matrix, each raw of which contains one path.
    
     varname   [char]: name of the variable
    
     dim_limit_str   [cell]: name of dimensions, like {'lon','lat'}. Dimensions with customed limits must be listed here here. Other dimensions are optional.
              
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
          + variable defined by this will be loaded into time in "matlab units" (days since 0000-01-00)
          + This is helpful for setting timelimit in a easy way, avoiding
            calculating the timelimit from units in netcdf files.
            For example, to read data between 02/15/2000 00:00 and
            02/16/2000 00:00 from a netcdf file, which includes a time variable "ob_time" 
            in units of "days since 2000-00-00 00:00", you need to set 
            timelimit as [46 47] when time_var_name is empty. However, you
            should set timelimit as [datenum(2000,2,15),
            datenum(2000,2,16)] if the tiem_var_name is set to "ob_time".
    
     dim_varname   [cell, optional]: name of the variable defining the axis at each dimension.
          + by default, each axis is defined by a variable sharing the same name as the dimension. 
          + "dim_varname{1} = nan" indicates that the axis is not defined
               not defined by any variable in file. It will be defined 
               as 1, 2, 3, ... Nx, where Nx is the length of the dimension.

##### OUTPUT:
     out_dim  : dimension info (e.g., longitude, latitude, if applicable)
     data     : data extracted from the given netcdf file.  



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
time_var_name  = 'time'; % convert values in "time" to matlab units (days since 0000-01-00 00:00).
dim_varname    = {'lon','lat','time'}; % This is to force the function to read values for the meridional dimension from the variable "lat".

[ out_dim, data ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname );
```

### 2.4 Read a subset from hundreds of files

It might be slow to read a subset of data from hundreds of files by provide a list of all files for `FUN_nc_varget_enhanced_region_2_multifile`. It needs to open every single file for some dimensional information. To speed up this command, an alternative way is to read and save the dimensional information at the very beginning. Then, providing the pre-saved information to `FUN_nc_varget_enhanced_region_2_multifile`. 

The dimensional information can be generated by `FUN_nc_gen_presaved_netcdf_info` and an example is shown below:

```matlab
%% generate info -----------------------------------------------------------

    filelist       = dir('Demo_*.nc');
    merge_dim_name = 'time'; % merge data in "time" dimension.
    dim_name       = { 'lon', 'y', 'time' }; % In the demo files, the meridional dimension is named as "y".
    dim_varname    = {'lon','lat','time'}; % This is to force the function to read values for the meridional dimension from the variable "lat". 
    time_var_name  = 'time'; % convert values in "time" to matlab units (days since 0000-01-00 00:00). This is optional

    output_file_path = 'Presaved_info_demo.mat';

    % Please note that **absolute** file paths are saved in the generated file. If you moved the data, you need to run this again
    pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path );

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

+ support large dataset.
+ Retry automatically after interruptions.
+ Download data piece by piece.
+ Download a subset of the original file.

##### INPUT: 
     filename0 : source of the netcdf file (OpenDAP URL here)    
     filename1 : Name of output netcdf file    
     dim_limit_var: which axises you want to set the limit    
     dim_limit_val: the limit of each axises    
     var_download: the variable you'd like to download. [var_download = [] will download all variables.]     
     var_divided:  the varialbes need to be downloaded piece by piece in a specific dimension. In many cases, OpenDAP will end up with no response if you try to donwloading too large data at once. A solution for this is to download data piece by piece divided_dim_str: which dim you'd like to download piece by piece (e.g., 'time', or 'depth')    
     divided_dim0 = []  means all varialbes will be downloaded completely at once.   
     Max_Count_per_group: Max number of points in the divided dimension.   

 Optional parameters:

| Parameter                  | Default value  | note                                                         |
| -------------------------- | -------------- | ------------------------------------------------------------ |
| dim_varname                | dim_limit_name | Names of variables defining dimensions given in dim_limit_name |
| time_var_name              | []             | Name of the variable describing time                         |
| is_auto_chunksize          | flase          |                                                              |
| compressiion_level         | 1              |                                                              |
| is_skip_blocks_with_errors | false          |                                                              |
| N_max_retry                | 10             |                                                              |
| var_exclude                | []             |                                                              |

##### Output
    N/A


 Notice: To recongnize the axis correctly, there must be one variable
 named as by the axis! Assign a variable to a specific axis is not supported yet. 


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


### 3.2 Merge multiple netCDF files in time (`FUN_nc_merge`)

`FUN_nc_merge( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode )`


##### INPUT: 
     input_dir: The folder in which all input netcdf given by "filelist" is located
     filelist : the list of files which will be merged. This should be generated by matlab built-in command: `dir`.      
                This function will merge the netcdf files following the order given in this variable. Please make sure this variable has been resorted properly.
     output_fn : Name of output netcdf file
     merge_dim_name : name of the dimension in which all varialbes will be merged.
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


## 4. Write Netcdf Files

### 4.1 `FUN_nc_easywrite_enhanced`
FUN_nc_easywrite_enhanced( filename, dim_name, dim_length, varname, dimNum_of_var, data, global_str_att )

##### INPUT
     filename [char]: name of the output netcdf file (e.g., 'test.nc')
     dim_name [cell]: names of dimensions (e.g., {'lon','lat'}
     dim_length [array]: length of each dimension (e.g., [ 360, 180 ] )
     varname [cell]: names of variables (e.g., {'lon','lat','sst','ssh'}
     dimNum_of_var [cell]: dimensional ID for each variable { 1, 2, [1,2],[1,2]} ). Value "1" indciate the first dimension in `dim_name`. value 2 indicate the second dimension in `dim_name`.
     data [cell]: values for each variable (e.g., {lon,lat,sst,ssh})
     global_str_att: global attribute

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

### 4.2 Other functions for writting a netcdf file

+ `FUN_nc_easywrite_add_var`: add a variable to an existing netcdf file
+ `FUN_nc_easywrite_add_att`: add an attribute to an existing variable in an existing netcdf file.
+ `FUN_nc_easywrite`: write one variable into a new netcdf file. 
+ `FUN_nc_easywrite_write_var`: replace values of an existing variable in an existing netcdf file.



----

<mark>**Output of some examples above can be found [here](./Documents_and_demo/Readme.md)**</mark>
