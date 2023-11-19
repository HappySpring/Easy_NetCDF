function filedim = FUN_nc_varget_sub_genStartCount_from_presaved_data_v2( pregen_info, varname, dim_name, dim_limit )
% var_dim = FUN_nc_varget_sub_genStartCount_from_presaved_data_v2( fn, dim_name, dim_limit, time_var_name, dim_varname )
% This is called by FUN_nc_varget_enhanced_region_2_multifile
% -------------------------------------------------------------------------
% INPUT:
%      filename  [char]: name of the NetCDF file (e.g., 'temp.nc')
%      varname   [char]: name of the variable (e.g., {'sst','ssh'})
%           + varname = []  :  This function will return dimensions listed in dim_name.
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
% -------------------------------------------------------------------------
% v2.00 by L. Chi  updated to be compatible with format v2 created by 'FUN_nc_gen_presaved_netcdf_info_v2'
% V1.01 by L. Chi. Fix a bug
%                  The function may return error unexpectedly when both 
%                  both "dim_name" and "dim_limit" are empty
% V1.00 by L. Chi. This is extracted from "FUN_nc_varget_enhanced_region_2.m"
% (L.Chi.Ocean@outlook.com)


%% ## Set default value

if ischar( dim_name )
    dim_name = {dim_name};   
end

if ~isempty(dim_limit) && ~iscell( dim_limit )
    dim_limit   = {dim_limit};
end

if length( dim_name ) == length( dim_limit )
    %PASS
else
    error('Each dim_name must be assocated with one dim_limit'); 
end

%% ## prepare dimensions

% ### Open NetCDF

    var_ind = FUN_struct_find_field_ind( pregen_info.var, 'Name', varname );
    
    if length( var_ind ) ~= 1
        error('Error in variable name');
    end
    
    if ~isempty( varname )
        var_dim_ind = pregen_info.var(var_ind).Dim_ind;
    else
        for ii = 1:length( dim_name )
            var_dim_ind(ii) = find( strcmpi( {pregen_info.file(1).dim(:).name}, dim_name{ii} ) );
        end
    end

% ### Set limit for each dimension
for jj = 1:length( pregen_info.file )
    
    var_dim = struct;
    
for ii = 1:length( var_dim_ind )
    
    tmp_ind = var_dim_ind(ii);
    
    if pregen_info.dim(tmp_ind).is_dim_merged
        var_dim(ii).Name   = pregen_info.file(jj).dim(tmp_ind).name   ;
        var_dim(ii).Length = pregen_info.file(jj).dim(tmp_ind).length ;
        var_dim(ii).varname= pregen_info.file(jj).dim(tmp_ind).varname;
        var_dim(ii).is_time= pregen_info.file(jj).dim(tmp_ind).is_time;
        dim_val_now = pregen_info.file(jj).dim.value;
    
    else
        var_dim(ii).Name   = pregen_info.dim(tmp_ind).name   ;
        var_dim(ii).Length = pregen_info.dim(tmp_ind).length ;
        var_dim(ii).varname= pregen_info.dim(tmp_ind).varname;
        var_dim(ii).is_time= pregen_info.dim(tmp_ind).is_time;
        dim_val_now        = pregen_info.dim(tmp_ind).value  ;
    end

    var_dim(ii).originalVal = dim_val_now;
    
    % ### apply the loading limits
    dim_limit_ind = find( strcmp(  var_dim(ii).Name, dim_name ) );
    
    if ~isempty( dim_limit_ind )
        
        [start, count, tem_loc] = FUN_nc_varget_sub_genStartCount( dim_val_now, dim_limit{dim_limit_ind} );
        
        var_dim(ii).start       = start;
        var_dim(ii).count       = count;
        var_dim(ii).value       = dim_val_now(tem_loc);
        var_dim(ii).value_name  = var_dim(ii).varname; % value_name is dim_varname_now if it existed, otherwise, value_name is the name of the dimension.
        
        if isempty( var_dim(ii).value_name )
           var_dim(ii).value_name = var_dim(ii).Name;
        end
        
    else

        var_dim(ii).start       = 0;
        var_dim(ii).count       = var_dim(ii).Length;
        
        var_dim(ii).value       = dim_val_now;
        var_dim(ii).value_name  = var_dim(ii).Name ; %
    end
    
end

    filedim(jj).var_dim = var_dim;

end
