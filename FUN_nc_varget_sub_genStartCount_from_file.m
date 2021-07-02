function var_dim = FUN_nc_varget_sub_genStartCount_from_file( filename, varname, dim_name, dim_limit, time_var_name, dim_varname )
% var_dim = FUN_nc_varget_sub_genStartCount_from_file( filename, varname, dim_name, dim_limit, time_var_name, dim_varname )
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
% -------------------------------------------------------------------------
% OUTPUT:
%      out_dim  : dimension info (e.g., longitude, latitude, if applicable)
% -------------------------------------------------------------------------
% V1.01 by L. Chi. Return empty structure if no dimension is associated to
%                  the inquiry variable.
% V1.00 by L. Chi.  This is extracted from "FUN_nc_varget_enhanced_region_2.m"
% (L.Chi.Ocean@outlook.com)


%% ## Set default value
if ~exist( 'dim_varname', 'var' ) || isempty( dim_varname );
    dim_varname = dim_name;
end

if ischar( dim_name )
    dim_name = {dim_name};
    
    if ~iscell( dim_limit )
       dim_limit   = {dim_limit};
    end
    
    if ~iscell( dim_varname )
       dim_varname = {dim_varname}; 
    end
end

%% ## prepare dimensions

% ### Open NetCDF
    ncid = netcdf.open( filename, 'NOWRITE');
    
    if ~isempty( varname )
        % if varname is given, list all dimensions related to this variable.
        varid = netcdf.inqVarID( ncid, varname );
        [~, ~, var_dim_id, ~ ] = netcdf.inqVar(ncid,varid);
    else
        % if varname is empty, list dimensions specified by dim_name.
        for ii = 1:length( dim_name )
            var_dim_id(ii)  = netcdf.inqDimID( ncid, dim_name{ii} );
        end
    end
    
% ### Set limit for each dimension
for ii = 1:length( var_dim_id )
    
    % ### dimensions of the selected variable
    [ tem_dimname, tem_dimlen ]  = netcdf.inqDim( ncid, var_dim_id(ii) );
    
    var_dim(ii).Name        = tem_dimname;
    var_dim(ii).Length      = tem_dimlen;
    
    % ### apply the loading limits
    dim_ind = find( strcmp(  var_dim(ii).Name, dim_name ) );
    
    if ~isempty( dim_ind )
        
        % #### load axis at the current dimension. 
        dim_name_now    = var_dim(ii).Name ;
        dim_varname_now = dim_varname{ dim_ind };
        
        % #### apply limit
        if exist('time_var_name','var') && ~isempty( time_var_name ) &&  strcmp( dim_name_now, time_var_name )
            % The axis is time (with the attribute "units" like " days since 2000-01-01 00:00:00")
            dim_val_now = FUN_nc_get_time_in_matlab_format( filename, dim_varname_now ) ;
            var_dim(ii).is_time     = true;
        else
            % The axis is not time.
            if isnan( dim_varname_now )
                % The definition of the axis is not included in the netCDF.
                dim_val_now = 1 : var_dim(ii).Length;
                var_dim(ii).value_name  = var_dim(ii).Name ; % value_name is dim_varname_now if it existed, otherwise, value_name is the name of the dimension.
            else
                dim_val_now = FUN_nc_varget_enhanced( filename, dim_varname_now ) ;
                var_dim(ii).value_name  = dim_varname_now ; % value_name is dim_varname_now if it existed, otherwise, value_name is the name of the dimension.
            end
            var_dim(ii).is_time     = false;
        end
        
        [start, count, tem_loc] = FUN_nc_varget_sub_genStartCount( dim_val_now, dim_limit{dim_ind} );
        
        var_dim(ii).originalVal = dim_val_now;
        var_dim(ii).start       = start;
        var_dim(ii).count       = count;
        var_dim(ii).varname     = dim_name_now;
        var_dim(ii).value       = dim_val_now(tem_loc);
        var_dim(ii).value_name  = dim_varname_now; %
    else
        
        if exist('time_var_name','var') && ~isempty( time_var_name ) &&  strcmp( var_dim(ii).Name, time_var_name )
            % The axis is time (with the attribute "units" like " days since 2000-01-01 00:00:00")
            var_dim(ii).originalVal = FUN_nc_get_time_in_matlab_format( filename, var_dim(ii).Name ) ;
            var_dim(ii).is_time     = true;
            var_dim(ii).value       = var_dim(ii).originalVal;
            
        elseif FUN_nc_exist_var( filename, var_dim(ii).Name )
            var_dim(ii).originalVal = FUN_nc_varget_enhanced( filename, var_dim(ii).Name ) ;
            var_dim(ii).value       = var_dim(ii).originalVal;
            var_dim(ii).is_time     = false;
        else
            var_dim(ii).originalVal = [];
            var_dim(ii).value       = nan(1,var_dim(ii).Length);
            var_dim(ii).is_time     = false;
        end
        
        var_dim(ii).start       = 0;
        var_dim(ii).count       = var_dim(ii).Length;
        var_dim(ii).varname     = [];
        var_dim(ii).value_name  = var_dim(ii).Name ; %
    end
    
end

% For dimensionless variables.
if isempty( var_dim_id )
    var_dim.Name        = [];
    var_dim.Length      = nan;
    var_dim.originalVal = [];
    var_dim.start       = [];
    var_dim.count       = [];
    var_dim.varname     = [];
    var_dim.value       = [];
    var_dim.value_name  = [];
end


    netcdf.close( ncid );