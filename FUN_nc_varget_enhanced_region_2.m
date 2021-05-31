function [ out_dim, data ] = FUN_nc_varget_enhanced_region_2( filename, varname, dim_name, dim_limit, time_var_name, dim_varname )
% [ out_dim, data ] = FUN_nc_varget_enhanced_region_2( filename, varname, dim_name, dim_limit, [time_var_name], [dim_varname] )
% Advanced nc file loader
% time_var_name is optional
%
% Please use "FUN_nc_varget_enhanced_region_2_multifile" to replace this one.
% 
% -------------------------------------------------------------------------
% INPUT:
%      filename  [char]: name of the NetCDF file (e.g., 'temp.nc')
%      varname   [char]: name of the variable (e.g., 'sst' or 'ssh')
%      dim_name  [cell]: name of dimensions, like {'lon','lat'}
%      dim_limit [cell]: limit of dimensions. (e.g., {[-85 -55 ], [-inf inf]})
% 
%      time_var_name [char, optional]: name of the time axis
%           + variable defined by this will be loaded into time in matlab format (days since 0000-01-00)
%      dim_varname   [cell, optional]: name of the variable defining the axis at each dimension.
%           + by default, each axis is defined by a variable sharing the same name as the dimension. 
%           + "dim_varname{1} = nan" indicates that the axis is not defined
%                not defined by any variable in file. It will be defined 
%                as 1, 2, 3, ... Nx, where Nx is the length of the dimension.
%
% OUTPUT:
%      out_dim  : dimension info (e.g., longitude, latitude, if applicable)
%      data     : data extracted from the given netcdf file.  
% -------------------------------------------------------------------------
% Example: 
%
%   filename     = 'I:\Data\ECCO2\data1_cube92_latlon_quart_90S_90N\SALT_monthly.nc\SALT.1440x720x50.199210.nc';
%   varname      = 'SALT';
%   dim_name      = { 'LONGITUDE_T', 'LATITUDE_T', 'DEPTH_T', 'TIME' };
%   dim_limit     = {[-100 -50]+360, [20 50 ],  [0 500] , [-inf inf] };
%   time_var_name= 'TIME';
%   dim_varname  = { 'LONGITUDE_T', 'LATITUDE_T', 'DEPTH_T', 'TIME' };
%   [ out_dim, data ] = FUN_nc_varget_enhanced_region_2( filename, varname, dim_name, dim_limit, time_var_name );
% 
% ---- results ----
% out_dim = 
% 
%   struct with fields:
% 
%     LONGITUDE_T: [200x1 double]
%      LATITUDE_T: [120x1 double]
%         DEPTH_T: [23x1 double]
%            TIME: 10
%
% whos data
%   Name        Size                  Bytes  Class     Attributes
% 
%   data      200x120x23            4416000  double 
% -------------------------------------------------------------------------

% V1.21 By L. Chi,
%          Edit formats. move dimensional check into an if block
%          (is_double_check)
% V1.20 By L. Chi, 
%          dimension can be given in random order. 
%          Add "dim_varname"
% V1.10 By L. Chi
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%% ## Set default value
    if ~exist( 'time_var_name', 'var' ) 
        time_var_name = [];
    end

    if ~exist( 'dim_varname', 'var' ) || isempty( dim_varname );
        dim_varname = dim_name;
    end

    is_double_check = true;
    
%% ## prepare dimensions

    var_dim = FUN_nc_varget_sub_genStartCount_from_file( filename, varname, dim_name, dim_limit, time_var_name, dim_varname );    
    
% ## Prepare variable -----------------------------------------------------

%% load data
    nc_start = [ var_dim(:).start ];
    nc_count = [ var_dim(:).count ];
    nc_strid = ones(size(nc_start));
    data = FUN_nc_varget_enhanced_region( filename, varname, nc_start, nc_count, nc_strid );
    
%% check dimension 
    if is_double_check
    for ii = 1:length(var_dim)

        if isempty( var_dim(ii).varname ) || all( isnan( var_dim(ii).value_name ) )
           % Skip
           continue 
        end

        if  var_dim(ii).is_time 
            dim_list_check = FUN_nc_get_time_in_matlab_format( filename, var_dim(ii).value_name,  var_dim(ii).start, var_dim(ii).count, 1 );
        else
            dim_list_check = FUN_nc_varget_enhanced_region(  filename, var_dim(ii).value_name,  var_dim(ii).start, var_dim(ii).count, 1 );
        end

        if all( dim_list_check == var_dim(ii).value )
        else
           error('Dimension doesn''t match!') 
        end
    end
    end

%% output
    for ii = 1:length(var_dim)
        if isnan( var_dim(ii).value_name )
            out_dim.(var_dim(ii).Name) = var_dim(ii).value;
        else
            out_dim.(var_dim(ii).value_name) = var_dim(ii).value;
        end
    end
