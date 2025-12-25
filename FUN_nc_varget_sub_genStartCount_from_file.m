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
%           + "dim_varname{1} = nan" will force the dimension assicated with 
%             an vector defined as 1, 2, 3, ... Nx, where Nx is the length
%             of the dimension, ingnoring the variable shares the same name
%             with this dimension (if it exists)
%           + dim_varname can also caontain arrays to set the longitude,
%           latitude, time, etc, manually instead of reading them from the
%           netcdf file. E.g., dim_varname = { [-82:1/4:-55], [26:1/4:45]};
%           + if dim_varname = {'lon', [], 'lat'}, this function will try
%               to assign a dim_varname according to the dimension name if
%               such a variable exist, otherwise, the [] will be replaced
%               by nan.
%
% -------------------------------------------------------------------------
% OUTPUT:
%      out_dim  : dimension info (e.g., longitude, latitude, if applicable)
% -------------------------------------------------------------------------

% v1.20 by L. Chi, 2025-12-24
%                  updated to be compatible with new feature: read data from incontinuous index in dim_limit input.
% V1.03 by L. Chi. Fix a bug. The limit for time may not be applied
%                  properly when `time_var_name` is named differently from
%                  the dimension for time.
% V1.02 by L. Chi. `dim_varname` accepts manually set nuerical array as
%                  input.
% V1.01 by L. Chi. Return empty structure if no dimension is associated to
%                  the inquiry variable.
% V1.00 by L. Chi.  This is extracted from "FUN_nc_varget_enhanced_region_2.m"
% (L.Chi.Ocean@outlook.com)


%% ## Set default value
if ~exist( 'dim_varname', 'var' ) || isempty( dim_varname )
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
    
% ### find the dimension for time
    if exist('time_var_name','var') && ~isempty( time_var_name ) 
        time_var_id = netcdf.inqVarID(ncid,time_var_name);
        [~,~,time_dim_id,~] = netcdf.inqVar(ncid,time_var_id);
        if length(time_dim_id) > 1
           error('The variable for time cannot contain more than one dimension!'); 
        end
        time_dim_name = netcdf.inqDim(ncid,time_dim_id);
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
        
        % handle empty dim_varname_now
        % please note that if `dim_varname_now = []`, then `isnumeric( dim_varname_now )` returns true!
        if isempty(dim_varname_now)
            if FUN_nc_is_exist_variable(filename,var_dim(ii).Name)
                dim_varname_now = var_dim(ii).Name;
            else
                warning(['Cannot find a variable defining values for ' var_dim(ii).Name ', index based values will be adopted!' ])
                dim_varname_now = nan;
            end
        end
        
        if ischar( dim_varname_now )
            if FUN_nc_is_exist_variable( filename, dim_varname_now )
                % pass
            elseif length(dim_limit{dim_ind}) > 2
                %
                dim_varname_now = nan;
            else
                error
            end
        end


        % #### apply limit
        %if exist('time_var_name','var') && ~isempty( time_var_name ) && strcmp( dim_name_now, time_var_name )
        if exist('time_var_name','var') && ~isempty( time_var_name ) && strcmp( dim_name_now, time_dim_name ) 
            % The axis is time (with the attribute "units" like " days since 2000-01-01 00:00:00")
            dim_val_now = FUN_nc_get_time_in_matlab_format( filename, dim_varname_now ) ;
            var_dim(ii).value_name  = dim_varname_now; 
            var_dim(ii).is_time     = true;
            
        else
            % The axis is not time.
            if isnan( dim_varname_now )
                % The definition of the axis is not included in the netCDF.
                dim_val_now = 1 : var_dim(ii).Length;
                var_dim(ii).value_name  = var_dim(ii).Name ; % value_name is dim_varname_now if it existed, otherwise, value_name is the name of the dimension.

            elseif ischar( dim_varname_now ) % dim_varname_now is the name of a variable associated to this dimension
                dim_val_now = FUN_nc_varget_enhanced( filename, dim_varname_now ) ;
                var_dim(ii).value_name  = dim_varname_now ; % value_name is dim_varname_now if it existed, otherwise, value_name is the name of the dimension.
                
            elseif isnumeric( dim_varname_now ) % dim_varname_now contains a manually provded numerical matrx.
                if isvector(dim_varname_now) && length( dim_varname_now ) == var_dim(ii).Length
                    dim_val_now = dim_varname_now ;
                    var_dim(ii).value_name  = var_dim(ii).Name ; 
                else
                    error('The length of input dim_varname does not match the length of the assocated dimension!')
                end
                
            else
                error('Unexpected dim_varname!');
            end
            var_dim(ii).is_time     = false;
        end
        
        [start, count, tem_loc] = FUN_nc_varget_sub_genStartCount( dim_val_now, dim_limit{dim_ind} );
        % note: start = nan & count > 0 indicate unconstructed grid or unconstrained selection.

        var_dim(ii).originalVal = dim_val_now;
        var_dim(ii).start       = start;
        var_dim(ii).count       = count;
        var_dim(ii).varname     = dim_name_now;
        var_dim(ii).value       = dim_val_now(tem_loc);
        var_dim(ii).ind         = tem_loc; % indices (within this dimension) selected by the limit
        
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
        var_dim(ii).ind         = [];
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
    var_dim(ii).ind     = [];
end


    netcdf.close( ncid );