function [ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname, varargin )
% [ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname )
% 
% [ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2_multifile( presaved_info, varname, dim_name, dim_limit )
%
%
% Advanced nc file loader
% time_var_name is optional
%
% -------------------------------------------------------------------------
% INPUT:
%      filelist  [struct array]: name and folder of the NetCDF file
%                 filelist must include 2 attributes, name and folder. For   
%                 each element of filelist (e.g. the ith one), the full path
%                 will be generated by fullfile( filelist(ith).folder, filelist(ith).name)
%                                
%                 [cell array]: It can also be a cell array contain paths of files,
%                    or a char matrix, each raw of which contains one path.
%                   
%                 [structure]: It can also be a structure generated by 
%                    "FUN_nc_gen_presaved_netcdf_info.m". This is
%                    recommanded if you need to read hundreds of files
%                    frequently.
%
%      varname   [char]: name of the variable
%
%      dim_limit_str   [cell]: name of dimensions, like {'lon','lat'}
%               
%      dim_limit_limit [cell]: limit of dimensions, like {[-85 -55], [30 45]}
% 
%      merge_dim_name [string]: name of the dimension in which the variables 
%                 from different files will be concatenated. If merge_dim_name is
%                 empty, the variable will be concatenated after its last
%                 dimension.
%
%                 + Example 1: if you want to read gridded daily
%                   temperature given in [lon, lat, depth, time] from a set of
%                   files, and each file contains temperature in one day,
%                   the merge_dim_name should be 'time'. 
%
%                 + Example 2: if you want to read gridded daily temperature given in
%                   [lon, lat, depth], in which time is not given
%                   explicitly in each file, you can leave merge_dim_name
%                   empty.
%
%      time_var_name [char, optional]: name of the time axis
%           + variable defined by this will be loaded into time in matlab format (days since 0000-01-00)
%           + This is helpful for setting timelimit in a easy way, avoiding
%             calculating the timelimit from units in netcdf files.
%             For example, to read data between 02/15/2000 00:00 and
%             02/16/2000 00:00 from a netcdf file, which includes a time variable "ob_time" 
%             in units of "days since 2000-00-00 00:00", you need to set 
%             timelimit as [46 47] when time_var_name is empty. However, you
%             should set timelimit as [datenum(2000,2,15),
%             datenum(2000,2,16)] if the tiem_var_name is set to "ob_time".
%
%      dim_varname   [cell, optional]: name of the variable defining the axis at each dimension.
%           + by default, each axis is defined by a variable sharing the same name as the dimension. 
%           + "dim_varname{1} = nan" indicates that the axis is not defined
%                not defined by any variable in file. It will be defined 
%                as 1, 2, 3, ... Nx, where Nx is the length of the dimension.
% Optional parameters:
%      path_relative_to: (default: empty)
%             This must be provided if the relative path is used to generated 
%               the input variable "filelist" by "FUN_nc_gen_presaved_netcdf_info.m"
%      is_quiet_mode_on: (default: false)
%             If the quiet mode is on, filenames will not be printed to the
%             screen.
%
% OUTPUT:
%      out_dim  : dimension info (e.g., longitude, latitude, if applicable)
%      data     : data extracted from the given netcdf file.  
% -------------------------------------------------------------------------
% Example: 
%
% filelist       = dir('Demo_*.nc');
% varname        = 'sst';
% dim_name       = { 'lon', 'y', 'time' }; % In the demo files, the meridional dimension is named as "y".
% dim_limit      = { [-110 -20],  [15 70], [datenum(2001,12,1) datenum(2003,11,30)] };
% merge_dim_name = 'time'; % merge data in "time" dimension.
% time_var_name  = 'time'; % convert values in "time" to matlab units (days since 0000-01-00 00:00).
% dim_varname    = {'lon','lat','time'}; % This is to force the function to read values for the meridional dimension from the variable "lat".
% 
% [ out_dim, data ] = FUN_nc_varget_enhanced_region_2_multifile( filelist, varname, dim_name, dim_limit, merge_dim_name, time_var_name, dim_varname );
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

% V2.11 by L. Chi
%          + Add quiet mode
% V2.10 by L. Chi
%          + Call "FUN_nc_varget_enhanced_region_2" to read variables which 
%            are not assoicated to the dimension to be merged.
%          + Support dimensionless variables.
%
% V2.06 by L. Chi
%          Update the example.
% V2.05 by L. Chi
%          convert `dim_name` and `dim_limit` into cells if the input values are not given in cells
%          update comments
% V2.04 by L. Chi
%          fix a bug: In old versions, time will not be converted to
%          the matlab format if the input variable "time_var_name" was
%          been provided be not listed in "dim_name".
% 
% V2.03 by L. Chi
%          add defalut values for dim_name and dim_limit
%
% V2.02 by L. Chi
%          update default definition.
%
% V2.01 by L. Chi
%          Support char matrix as input filelist
%
% V2.00 By L. Chi
%          Support getting dimensional info from pre-saved file structures          
%          The presaved array can be generated by "FUN_nc_gen_presaved_netcdf_info"           
%
% V1.21 By L. Chi
%          fix a bug
%
%          `data_out = nan(size1);`  is replaced by `data_out = nan( [size1, 1] );`
%          to avoid errors when size1 is an 1x1 matrix.
%
% V1.20 By L. Chi,
%          dimension can be given in random order. 
%          Add "dim_varname"
% V1.10 By L. Chi
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%% 
% =========================================================================
% ## input data parser
% =========================================================================

% ### Set default value ---------------------------------------------------

if ~exist( 'dim_name', 'var' ) % this only works when is_load_presaved_info == false
    dim_name = [];
end


if ~exist( 'dim_limit', 'var' ) % this only works when is_load_presaved_info == false
    dim_limit = [];
end

if ~exist( 'merge_dim_name', 'var' ) 
    merge_dim_name = [];
end

if ~exist( 'time_var_name', 'var' ) 
    time_var_name = [];
end

if ~exist( 'dim_varname', 'var' ) || isempty( dim_varname ) % this only works when is_load_presaved_info == false
    dim_varname = dim_name;
end

[path_relative_to, varargin] = FUN_codetools_read_from_varargin( varargin, 'path_relative_to', []    );
[is_quiet_mode_on, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_quiet_mode_on', false );
[is_log_compact_on, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_log_compact_on', false ); % do not print skipped files on the screen.

if ~isempty( varargin )
    builtin('disp', varargin);
    error( 'Unknown parameters!');
end


if is_quiet_mode_on
    disp=@(x)1;
else
    disp=@(x)builtin('disp',x);
end

% ### convert dim_name and dim_limit to cell (if they are not yet) --------

% + `dim_name` must be a cell.
if ischar( dim_name )
    if size( dim_name, 1) == 1
        dim_name = { dim_name };
    else
        error('E31!')
    end
end

% + `dim_limit` must be a cell.
if iscell(dim_limit) || isempty( dim_limit )
    %PASS
elseif all( isnumeric( dim_limit ) )
    if size( dim_limit, 1) == 1 && size( dim_limit, 2) == 2
        dim_limit = { dim_limit };
    else
        error('E32!')
    end
else
    error('E33!')
end

%% ### get list of netCDF files and determine the running mode

if isstruct( filelist ) && isfield( filelist, 'var' ) && isfield( filelist, 'file' )
    % load data from pre-saved data.
    % This can save some time to load dimensional data from each file. It is 
    % very useful for reading a subset from a large number of files. 
    is_load_presaved_info = true;
    presaved_info = filelist;
    filepath_list = {presaved_info.file.path};
    
    % check variable for time
    if ( ~isempty( time_var_name ) && ~strcmpi( time_var_name, presaved_info.merge_dim.name) ) ||(  exist( 'dim_varname', 'var' ) && ~isequal( dim_varname, dim_name ) ) % dim_varname is set to dim_name by default
        error(' time_var_name & dim_varname should be defined when the pre-saved .mat file is generated! They cannot be defined here!')
    end
    
    % check name of the dimension to be merged
    if ~exist('merge_dim_name','var') || isempty( merge_dim_name )
       merge_dim_name = presaved_info.merge_dim.name; 
       
    elseif isequal( merge_dim_name, presaved_info.merge_dim.name )
        % PASS
    else
        error( 'The given merge_dim_name does not match the presaved merge_dim_name!');
    end
    
    % check relative path.
    if isfield( presaved_info, 'param' ) && presaved_info.param.is_relative_path == true
        if ~isempty( path_relative_to )
            filepath_list = strcat( path_relative_to, filepath_list );
        else
            error('Cannot found the paramter "path_relative_to"');
        end
        
    elseif ~isempty( path_relative_to )
        error('Input paramter "path_relative_to" is useless since absolute paths are used in the pre-saved cache');
    end
        
    
    
else
    
    is_load_presaved_info = false;
    
    % generate filepath_list from the input filelsit.
    if iscell( filelist )
        filepath_list = filelist ;

    elseif ischar( filelist )
        filepath_list = mat2cell( filelist, ones(size(filelist,1),1), size(filelist,2) );
        
    elseif isfield( filelist, 'folder' )
        filepath_list = fullfile( { filelist(:).folder }, { filelist(:).name } );

    elseif isfield( filelist, 'name' )
        filepath_list = { filelist(:).name };
    else
        error('Unknown input format for filelist');
    end

end


%% 
% =========================================================================
% ## prepare dimensions
% =========================================================================

% ### get start/count for all dimensions ---------------------------------- 
% use the first file as the template

if is_load_presaved_info == true
    tmp_presaved_info = presaved_info ;
    tmp_presaved_info.file = tmp_presaved_info.file(1);
    var_dim0 = FUN_nc_varget_sub_genStartCount_from_presaved_data( tmp_presaved_info, varname, dim_name, dim_limit );
    var_dim0 = var_dim0.var_dim;
else
    fn = filepath_list{1};
    var_dim0 = FUN_nc_varget_sub_genStartCount_from_file( fn, varname, dim_name, dim_limit, time_var_name, dim_varname );
end

N_dim = length( var_dim0 );

% ### get merged variable info for all files ------------------------------

if ~isempty( merge_dim_name )
    % ---------------------------------------------------------------------
    % find the ind of merged dimension in the requested variable
    ind_merged_dim = find( strcmpi( {var_dim0.Name}, merge_dim_name ) );
    
    if ~isempty( ind_merged_dim )
        % The current variable is associated to the dimension to be merged.
        
        % find the limit and properties of the merged dimension.
        ind_merged_dim_in_limit = find( strcmpi( dim_name, merge_dim_name ) );
        if isempty( ind_merged_dim_in_limit )
            dim_limit_for_merged_var = [-inf inf];
            dim_varname_for_merged_var = [];
        else
            dim_limit_for_merged_var = dim_limit( ind_merged_dim_in_limit );
            dim_varname_for_merged_var = dim_varname{ ind_merged_dim_in_limit };
        end

        % get dimension info
        if is_load_presaved_info == true
            var_dim_merged = FUN_nc_varget_sub_genStartCount_from_presaved_data( presaved_info, [], merge_dim_name, dim_limit_for_merged_var );
            var_dim_merged = [ var_dim_merged(:).var_dim ];

            for ii = 1:length( var_dim_merged )
                var_dim_merged(ii).value = var_dim_merged(ii).value(:)';
            end
        else
            for ii = 1:length( filepath_list )
                fn = filepath_list{ii};
                var_dim_merged(ii)       = FUN_nc_varget_sub_genStartCount_from_file( fn, [], merge_dim_name, dim_limit_for_merged_var, time_var_name, dim_varname_for_merged_var );
                var_dim_merged(ii).value = var_dim_merged(ii).value(:)';
            end
        end

        if isnan( dim_varname_for_merged_var ) % The axis at the merged dimension is not given in the file.
            var_dim_merged(ii).value  = ii * 100 + [1:var_dim_merged(ii).count] * 99 / var_dim_merged(ii).count ;
        end

        ind_in_output = nan( length( filepath_list ), 2 );
        ind_in_output(1,1) = 1;
        ind_in_output(1,2) = var_dim_merged(1).count;

        for ii = 2:length( var_dim_merged ) 
            ind_in_output(ii,1) = ind_in_output(ii-1,2) + 1;
            ind_in_output(ii,2) = ind_in_output(ii,1) +  var_dim_merged(ii).count - 1;
        end

        Nm = ind_in_output(end, 2); % length in the merged dim.
        
    else % ----------------------------------------------------------------
        % The current variable is **not** associated to the dimension to be merged.
        % Please note that dimensionless variable will also ends here.
        
        fn = filepath_list{1};
        fprintf('The dimension to be mereged, [%s], does not exist in the specified variable [%s] \n', merge_dim_name, varname)
        fprintf('The variable [%s] will be read from the first input file:\n', varname)
        fprintf('%s\n',fn);

        [ out_dim, data_out ] = FUN_nc_varget_enhanced_region_2( fn, varname, dim_name, dim_limit, time_var_name, dim_varname );

        return % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    end
    
else % --------------------------------------------------------------------
    % The input parameter "merge_dim_name" is set to empty;
    % This indicates that the dimension to be merged is not included in the
    % netcdf file explictly. 
    % For example, a netcdf file contains monthly mean SST may have
    % dimensions "lon", "lat" without "time". To read a set of files like
    % this, you may want to set merge_dim_name=[] to reach here. 
    
    ind_merged_dim = length(var_dim0) + 1;
    
    for ii = 1:length( filepath_list ) 
        var_dim_merged(ii).value  = ii;
        var_dim_merged(ii).count  = 1;
        
        ind_in_output(ii,1)       = ii;
        ind_in_output(ii,2)       = ii;
    end
    
    Nm = ind_in_output(end, 2); % length in the merged dim.
    N_dim = N_dim + 1;
    
end


%%
% =========================================================================
% ## load data
% =========================================================================
if length( var_dim0 ) == 1 && isempty( var_dim0.Name )
    % Dimensionless variables ---------------------------------------------
    
    size1 = [ 1, Nm ];
    data_out = nan( [size1, 1] ); % an additional dimension is added to avoid errors when size1 is 1x1.

    for ii = 1:length( filepath_list )
        
        fn = filepath_list{ii};

        disp(['Loading ' fn]);
        tem = FUN_nc_varget_enhanced( fn, varname );

        data_out(:, ind_in_output(ii,1):ind_in_output(ii,2))  =  tem;
    end
    
else
    % varialbes with dimensions -------------------------------------------
    
    size1 =  [var_dim0.count] ;
    size1(ind_merged_dim) = Nm;
    data_out = nan( [size1, 1] );    % an additional dimension is added to avoid errors when size1 is 1x1.
    
    nc_start = [ var_dim0(:).start ];
    nc_count = [ var_dim0(:).count ];
    nc_strid = ones(size(nc_start));
    
    if ind_merged_dim ~= N_dim
        warning('Please use with caution. This has not been fully tested yet!')
        data_out =  FUN_exchage_dim( data_out, ind_merged_dim, N_dim );
        nc_start =  FUN_exchage_dim( data_out, ind_merged_dim, N_dim );
        nc_count =  FUN_exchage_dim( data_out, ind_merged_dim, N_dim );
    end
    
    Nx = prod( size1(1:end-1) );
    data_out = reshape( data_out, Nx, Nm );
    
    for ii = 1:length( filepath_list )
        
        fn = filepath_list{ii};
        
        if ~isempty( merge_dim_name )
            if var_dim_merged(ii).count == 0
                if is_log_compact_on == false
                disp(['Skip ' fn]);
                end
                continue
            else
                disp(['Loading ' fn]);
            end

            nc_start(end) = var_dim_merged(ii).start;
            nc_count(end) = var_dim_merged(ii).count;

            tem = FUN_nc_varget_enhanced_region( fn, varname, nc_start, nc_count, nc_strid );
        else
            disp(['Loading ' fn]);
            tem = FUN_nc_varget_enhanced_region( fn, varname, nc_start, nc_count, nc_strid );
        end
        
        if ind_merged_dim ~= N_dim
            tem =  FUN_exchage_dim( tem, ind_merged_dim, N_dim );
        end
        
        data_out(:, ind_in_output(ii,1):ind_in_output(ii,2))  = reshape( tem, Nx, var_dim_merged(ii).count );
    end
end 
%%
% =========================================================================
% ## output
% =========================================================================

% ### collect dimensions

if length( var_dim0 ) == 1 && isempty( var_dim0.Name )
    % dimensionless variable
    out_dim = [];
else
    %diemsional variable
    for ii = 1:length(var_dim0)
        out_dim.(var_dim0(ii).value_name) = var_dim0(ii).value;
    end
end

if ~isempty( merge_dim_name )
    out_dim.(var_dim0(ind_merged_dim).value_name) = [ var_dim_merged.value ];
else
    out_dim.merged_dim = [ var_dim_merged.value ];
end

% ### make sure that the value is ascending in the `merged dimension`.
if ~isempty( merge_dim_name )
    [out_dim.(var_dim0(ind_merged_dim).value_name), sort_ind ] = sort( out_dim.(var_dim0(ind_merged_dim).value_name), 'ascend');
    data_out = data_out(:,sort_ind);
end

% ### reshape data into the right size.
data_out = reshape( data_out, [size1, 1] );
if ind_merged_dim ~= N_dim
    data_out =  FUN_exchage_dim( data_out, ind_merged_dim, N_dim );
end
