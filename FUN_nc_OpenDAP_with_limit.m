function FUN_nc_OpenDAP_with_limit( filename0, filename1, dim_limit_name, dim_limit_val, var_download, var_divided, divided_dim_str, Max_Count_per_group, varargin  )
% FUN_nc_OpenDAP_with_limit( filename0, filename1, dim_limit_name, dim_limit_val, var_download, var_divided, divided_dim_str, Max_Count_per_group  )
%
% This will download data by OpenDAP within a selected time-space range.
% *Notes*: Please be careful of the limits for time. The unit of time
% may change file by file
%
% This is modified from FUN_nc_copy_with_limit.m
%
% INPUT: 
%   filename0 : source of the netcdf file (OpenDAP URL here)
%   filename1 : Name of output netcdf file
%   dim_limit_name: which axises you want to set the limit
%   dim_limit_val: the limit of each axises
%   var_download: the variable you'd like to download. [var_download = [] will download all variables.] 
%   var_divided:  the varialbes need to be downloaded piece by piece in a specific dimension
%                 In many cases, OpenDAP will end up with no response if
%                 you try to donwloading too large data at once. A solution
%                 for this is to download data piece by piece
%   divided_dim_str: which dim you'd like to download piece by piece (e.g., 'time', or 'depth')
%       divided_dim_str = []  means all varialbes will be downloaded completely at once.
%   Max_Count_per_group: Max number of points in the divided dimension.
%
% Optional parameters:
% ** details see the "set optional parameters" in codes below **
%
%     |  Parameter                    | Default value | note           |
%     | ------------------------------|---------------|----------------|
%     |  dim_varname                  | dim_limit_name| Names of variables defining dimensions given in dim_limit_name |
%     |  time_var_name                |      []       | Name of the variable describing time |
%     |  is_auto_chunksize            |     false     |                |
%     |  compression_level           |       1       |                |
%     |  is_skip_blocks_with_errors   |     false     |                |
%     |  N_max_retry                  |      10       |                |
%     |  var_exclude                  |      []       |                |
%
% Output: None
%
%
% Notice: To recongnize the axis correctly, there must be one variable
% named as by the axis!

% ---------------------------------------------------------------------- %
% exampel: 
%
% filename0 = 'http://tds.hycom.org/thredds/dodsC/GLBu0.08/expt_19.1/2012';
% filename1 = 'HYCOM_test.nc';
% 
% lonlimit = [107 117];
% latlimit = [2 9];
% depthlimit = [-inf inf];
% timelimit  = [datenum(2012,1,1) datenum(2012,1,5)];
% 
% time = FUN_nc_varget(filename0,'time');
% time_unit = FUN_nc_attget(filename0,'time','units');
% [time0, unit_str, unit_to_day] = FUN_nc_get_time0_from_str( time_unit );
% 
% timelimit  = (timelimit - time0)/unit_to_day ;
% 
% FUN_nc_OpenDAP_with_limit( filename0, filename1, {'lon','lat','depth','time'}, {lonlimit, latlimit depthlimit timelimit}, [], [], 'time'  )
% 
% % Another example for 2D lon/lat cases is attached to the end.

% By L. Chi, V1.62 2022-07-27: fix a bug: Some old codes will create a large nan matrix before downloading a large dataset no matter whether  
%                                "divided_dim_str" is set or not. The nan matrix is may lead to an out-of-memory error and it is useless. 
%                                Related codes have been commented and will be removed in a later version. 
% By L. Chi, V1.61 2021-08-16: correct a typo ("compressiion_level" -> "compression_level")
% By L. Chi, V1.60 2021-07-28: Put all operations to source files in try-catch blocks to survive from internet/server errors. 
%
% By L. Chi, V1.50 2021-07-27: 
%                             + Switch to "FUN_nc_varget_sub_genStartCount_from_file" to prepare the subsets to be downloaded.  
%                                 This introduces more flexible ways to set limits at each dimension by a parameter "dim_varname", 
%                                 which is similar to the way it is used in "FUN_nc_varget_enhanced_region_2" and "FUN_nc_varget_enhanced_region_2_multifile"
%                                 This also introudces the support for the paramter "time_var_name".     
%                             + support excluding variables by a parameter "var_exclude". 
%
% By L. Chi, V1.41 2021-05-10: Update comments
% By L. Chi, V1.40 2021-05-04:
%                             1) A block will be written onto the disk immediately after it is downloaded. 
%                              In old version, the whole variable must be downloaded completely before writting to a disk
%                             2) Update comments
%                             3) make max-retry-number as a paramter, and set the default value to 10
%                             4) add 30 seconds pause after each failed try.
% By L. Chi, V1.31 2021-04-19: Update try-catch block. Add paramter "is_skip_blocks_with_errors"
% By L. Chi, V1.30 2021-02-17: Estimate chunksize by FUN_nc_internal_calc_chunk (parameter: `is_auto_chunksize`, default: `false`)
%                              Note: chunksize in the source will not be used.
% By L. Chi, V1.20 2020-08-06: Fix a bug in displaying slice range of divided variables
%                                   This will not affect results. 
% By L. Chi, V1.12 2020-01-23: Fix a bug: A variable may exist without a dimenion. 
%                                            This usually happens when the variable 
%                                            contains one value (like a 1x1 matrix). 
%                                            This is not expected and may cause 
%                                            error in previous codes. It is fixed from this version.
%
% By L. Chi, V1.20 2021-03-10: update default parameters
% By L. Chi, V1.12 2020-02-16: Add netcdf.sync after writting each slice of data.
% By L. Chi, V1.11 2019-12-23: Add retry.
% By L. Chi, V1.10 2019-12-21: The function can download N (N>=1) points in the "divided dimension" now. 
%                                 This value is given by Max_Count_per_group
% By L. Chi, V1.02 2017-02-16: fix a bug related to re def mode.
% By L. Chi, V1.01 2016-11-15: fix a bug when lon/lat is 2D.
% By L. Chi, V1.00 2016-11-14: initial version (L.Chi.Ocean@outlook.com)

%% 
% =========================================================================
% # Set defaults values for mandantory input parameters
% =========================================================================

% ## set default values ---------------------------------------------------

if ~exist('dim_limit_name','var')
    dim_limit_name = [];
end

if ~exist('dim_limit_val','var')
    dim_limit_val = [];
end


if ~exist('var_download','var')
    var_download = [];
end

if ~exist('var_divided','var')
    var_divided = [];
end

if ~exist('divided_dim_str','var')
    divided_dim_str = [];
end

if ~exist('Max_Count_per_group','var')
    Max_Count_per_group = inf;
end

%% 
% =========================================================================
% # set optional parameters
% =========================================================================

% + dim_varname [cell, optional] (default: dim_varname = dim_limit_name )
%           Variables associated with each dimension in `dim_limit_name`:
%           + by default, each axis is defined by a variable sharing the same name as the dimension. 
%           + "dim_varname{1} = nan" will force the dimension assicated with 
%             an vector defined as 1, 2, 3, ... Nx, where Nx is the length
%             of the dimension, ingnoring the variable shares the same name
%             with this dimension (if it exists)
%           + dim_varname can also caontain arrays to set the longitude,
%           latitude, time, etc, manually instead of reading them from the
%           netcdf file. E.g., dim_varname = { [-82:1/4:-55], [26:1/4:45]};

    [dim_varname, varargin] =  FUN_codetools_read_from_varargin( varargin, 'dim_varname', dim_limit_name, true );
    if isempty( dim_varname )
        dim_varname = dim_limit_name;
    end
    
% + time_var_name (default: [])
%           + variable defined by this will be loaded into time in matlab format (days since 0000-01-00)
%           + when time_var_name is defined properly, you can set a
%           timelimit like [datenum(2020,1,1), datenum(2020,12,31,23,59,59)] without considering the time units.
%           + This does not affect the output format. In the output file,
%           the time is still written in the unit as it is in the input file.

    [time_var_name, varargin] =  FUN_codetools_read_from_varargin( varargin, 'time_var_name', [], true );
    
% + is_auto_chunksize (default: false)
    % Should the function calculate the chunksize? [default: false]
    % The matlab default chunksize will be used if this is set to false. 
    % This function will not copy the chunksize from the source files now.
    [is_auto_chunksize, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_auto_chunksize', false, true );

% + compression_level (default: 1)
    % compresson_level (0: no compression) [default: 1 - minimal compression]
    [compression_level, varargin]=  FUN_codetools_read_from_varargin( varargin, 'compression_level', 1, true );
    % correct a type( "compressiion_level" -> "compression_level")
    % the following codes are added to work with the old versions using "compressiion_level"
    [tem, varargin]=  FUN_codetools_read_from_varargin( varargin, 'compressiion_level', [], true );
    if ~isempty(tem)
        compression_level = tem;
    end

% + is_skip_blocks_with_errors (default: false)
    % is_skip_blocks_with_errors = true: If a block fails more than 5 times,
    %                                      it will be skipped. 
    % is_skip_blocks_with_errors = false: If a block fails more than 5 times,
    %                                      the function ends with an error.
    [is_skip_blocks_with_errors, varargin]=  FUN_codetools_read_from_varargin( varargin, 'is_skip_blocks_with_errors', false, true );
    
% + N_max_retry (default: 10)
    % max number of re-try before sending errors (is_skip_blocks_with_errors==false) or skipping the current block (is_skip_blocks_with_errors==true)
    [N_max_retry, varargin] =  FUN_codetools_read_from_varargin( varargin, 'N_max_retry', 10, true );

% + var_exclude [cell, optional] (default: [])
    [var_exclude, varargin] =  FUN_codetools_read_from_varargin( varargin, 'var_exclude', [], true );
    
    if isstring(var_exclude) || ischar(var_exclude)
       var_exclude = {var_exclude}; 
    end
    
if ~isempty( varargin )
    error('Unkown parameters found!')
end

pause_seconds = 30; % sleep 30 seconds before resume from an error. 

%% Load the original data

% execute ncinfo and netcdf.open in try-catch blocks to avoid
% server/connection errors.

% info0 = ncinfo(filename0);
    f_ncinfo = @(x_filename)ncinfo( x_filename );
    info0 = FUN_codetool_retry( f_ncinfo, filename0, N_max_retry, pause_seconds );

% ncid0 = netcdf.open( filename0, 'NOWRITE' );
    f_nc_open_nw = @(x_filename)netcdf.open( x_filename, 'NOWRITE' );
    ncid0 = FUN_codetool_retry( f_nc_open_nw, filename0, N_max_retry, pause_seconds );

%% prepare dimensions

for ii = 1:length(info0.Dimensions)
    
    % decide wehter this dim should be loaded partly.
    dim_cmp_loc = strcmp( info0.Dimensions(ii).Name, dim_limit_name );

    if any( dim_cmp_loc )
        % load by part
        ij  = find(dim_cmp_loc);% for dim_limit_name & dim_limit_val
        
        dim_name_now = dim_limit_name{ij};
        
        % execute the following command in a try-catch block:
        %   dim_info_now = FUN_nc_varget_sub_genStartCount_from_file( filename0, [], dim_name_now, dim_limit_val{ij}, time_var_name, dim_varname{ij} );
        f_nc_genStartCount = @()FUN_nc_varget_sub_genStartCount_from_file( filename0, [], dim_name_now, dim_limit_val{ij}, time_var_name, dim_varname{ij} );
        dim_info_now = FUN_codetool_retry( f_nc_genStartCount, [], N_max_retry, pause_seconds );
        
        
        %var_str_now = dim_limit_name{ij};
        %varid_now = netcdf.inqVarID(ncid0, var_str_now ) ;
        %var_now = netcdf.getVar(ncid0, varid_now ) ;
        %[start, count, ind] = FUN_nc_varget_sub_genStartCount( var_now, dim_limit_val{ij} );
        
        info1.Dim(ii).Name        = dim_info_now.Name;
        %info1.Dim(ii).Length      = dim_info_now.count;
        info1.Dim(ii).MatInd      = ii;  % Location of this variable in the Dim Matrix
        info1.Dim(ii).originalVal = dim_info_now.originalVal;
        info1.Dim(ii).start       = dim_info_now.start;
        info1.Dim(ii).count       = dim_info_now.count;
        %info1.Dim(ii).ind        = ind;
        info1.Dim(ii).is_seleted  = true;
        %info1.Dim(ii).is_time     = dim_info_now.is_time; 

    else
        
        info1.Dim(ii).Name        = info0.Dimensions(ii).Name;
        %info1.Dim(ii).Length      = info0.Dimensions(ii).Length;
        info1.Dim(ii).MatInd      = ii;
        info1.Dim(ii).originalVal = [];
        info1.Dim(ii).start       = 0;
        info1.Dim(ii).count       = info0.Dimensions(ii).Length;
        %info1.Dim(ii).ind         = 1:info1.Dim(ii).Length ;
        info1.Dim(ii).is_seleted  = false;
        %info1.Dim(ii).is_time     = false;

    end
end

%% open new file and write dimensions
ncid1 = netcdf.create(filename1,'NETCDF4');

for ii = 1:length( info1.Dim )
    dimID1(ii) = netcdf.defDim(ncid1, info1.Dim(ii).Name , info1.Dim(ii).count );
end

% set global ATT
for ii = 1:length(info0.Attributes)
    
    if strcmpi( info0.Attributes(ii).Name, '_NCProperties')
        % skip built-in properties that cannot be edited directly.
        continue
    end
    
    netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), info0.Attributes(ii).Name, info0.Attributes(ii).Value);
end

netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), 'Copy Source', filename0 );
netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), 'Copy Date', datestr(now) );
for ii = 1:length( dim_limit_name )
    netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), ['Copy Range-' num2str(ii)], [dim_limit_name{ii} ' ' num2str( dim_limit_val{ii} )] );
end
%% load/write variable
N_adding_var = 0; % This is the "N_adding_var" time a new varialbe is added to this file.

for iv = 1:length(info0.Variables)
    if isempty(var_download) || any( strcmp( info0.Variables(iv).Name, var_download ) ) || any( strcmp( info0.Variables(iv).Name, dim_limit_name ) ) 
        if any( strcmp( info0.Variables(iv).Name, var_exclude ) )
            % Skip this variable, it has been excluded.
            continue
        else
            %Pass
        end
    else
        % Skip this variable, it is not selected.
        continue
    end
    
   % Prepare for varialbes
    VarDim_now   = info0.Variables(iv).Dimensions;
    N_adding_var = N_adding_var + 1;
    
    if ~isempty( VarDim_now )
        % This is the regular case
        for id = 1:length( VarDim_now )
            VarDimIND_now(id) = FUN_struct_value_for_specific_name( info1.Dim, 'Name', VarDim_now(id).Name, 'MatInd' );
        end
        is_var_with_dim = true;
    else % VarDim_now is empty
        % A variable may exist without dimensions. This suggests that the variable contains one value [1 x 1]. 
        VarDimIND_now = [];
        is_var_with_dim = false;
    end
    
    start = [];
    count = [];
    strid = [];
    
    if is_var_with_dim
        for id = 1:length( VarDimIND_now )
            start = [start info1.Dim( VarDimIND_now(id) ).start];
            count = [count info1.Dim( VarDimIND_now(id) ).count];
            strid = [strid 1];%stride
        end
    else
        % A variable may exist without dimensions. This suggests that the variable contains one value [1 x 1]. 
        start = [0];
        count = [1];
        strid = [1];%stride
    end

    % Define Variable -----------------------------------------------------
    if N_adding_var > 1
        netcdf.reDef(ncid1)
    end
    
    if is_var_with_dim
        varID1 = netcdf.defVar( ncid1, ...
            info0.Variables(iv).Name, ...
            FUN_nc_defVar_datatypeconvert(info0.Variables(iv).Datatype), ...
            dimID1( VarDimIND_now ) );
    else
        varID1 = netcdf.defVar( ncid1, ...
            info0.Variables(iv).Name, ...
            FUN_nc_defVar_datatypeconvert(info0.Variables(iv).Datatype), ...
            [] );
    end
    
    % Setup compression
    netcdf.defVarDeflate( ncid1, varID1, true, true, compression_level );%compression level-1 basic
    
    % set chunk size (not necessary for non-dimensional var)
    if is_auto_chunksize && is_var_with_dim
        tmp_bytes_per_val = FUN_nc_internal_bytes_per_value( info0.Variables(iv).Datatype );
        tmp_chunksize = FUN_nc_internal_calc_chunk( count, tmp_bytes_per_val );
        netcdf.defVarChunking( ncid1, varID1, 'CHUNKED', tmp_chunksize );
    end
    
    % Add attribute -------------------------------------------------------
    for ii = 1:length(info0.Variables(iv).Attributes)
        if strcmp( info0.Variables(iv).Attributes(ii).Name, '_FillValue')
            % _FillValue can only be written by specific commends.
            netcdf.defVarFill( ncid1, varID1, false, info0.Variables(iv).Attributes(ii).Value ) 
        else
            netcdf.putAtt( ncid1, varID1, info0.Variables(iv).Attributes(ii).Name, info0.Variables(iv).Attributes(ii).Value);
        end
    end

    netcdf.endDef(ncid1)
    
    % Decided how to download this variable -------------------------------
    if any( strcmp(info0.Variables(iv).Name, dim_limit_name ) ) || isempty(divided_dim_str)
        is_load_all_at_once = 1; % This variable will be loaded once for all
    
    elseif ~isempty(var_divided) && ~any( strcmp(info0.Variables(iv).Name, var_divided) )
        is_load_all_at_once = 1; % This variable will be loaded once for all
        
    else 
        divided_dim = FUN_struct_find_field_ind( VarDim_now, 'Name', divided_dim_str );
        
        if isnan( divided_dim ) || count(divided_dim) ==  1 % nan means this dimension doesn't not exist in the current variable
            is_load_all_at_once = 1; % This variable will be loaded once for all
            
        elseif ~isempty(divided_dim_str) && ( any( strcmp(info0.Variables(iv).Name, var_divided )) || isempty(var_divided) )
            is_load_all_at_once = 0; % This variable will be loaded piece by piece
             
        else
            error('E10: unexpected condition!')
        end

    end
    
    % downloading varialbe ================================================
    % varID0 = netcdf.inqVarID( ncid0, info0.Variables(iv).Name );
    f_nc_inqVarID = @()netcdf.inqVarID( ncid0, info0.Variables(iv).Name );
    varID0 = FUN_codetool_retry( f_nc_inqVarID, [], N_max_retry, pause_seconds );
        
        
    if is_load_all_at_once == 1 % -----------------------------------------
        % The varialbe will be loaded completely at once 
        disp([datestr(now) ' downloading ' info0.Variables(iv).Name ])
        if is_var_with_dim
            %var_value = netcdf.getVar( ncid0, varID0, start, count, strid );
            f_nc_inqVarID_at_once = @()netcdf.getVar( ncid0, varID0, start, count, strid );
        else
            %var_value = netcdf.getVar( ncid0, varID0 );
            f_nc_inqVarID_at_once = @()netcdf.getVar( ncid0, varID0 );
        end
        var_value = FUN_codetool_retry( f_nc_inqVarID_at_once, [], N_max_retry, pause_seconds );
        
        % write data into the output file
        netcdf.putVar( ncid1, varID1, var_value);
        netcdf.sync( ncid1 ); % write buffer onto disk.
        
    elseif is_load_all_at_once == 0 % -------------------------------------
        % The data will be donwloaded peice by piece by piece according to the last dim. 

        disp([datestr(now) ' downloading ' info0.Variables(iv).Name ])
        %if all( size(count) == 1 ) % in case of count = 5 instead of [5 6 7 8]
        %    var_value = nan(count,1);
        %else
        %    var_value = nan(count);
        %end
        divided_dim = FUN_struct_find_field_ind( VarDim_now, 'Name', divided_dim_str );
        
        % make the divided_dim as the last dim.
        % [var_value, tem_ind_reverse] = FUN_dim_move_to_end(var_value, divided_dim );
        %tem_size  = size( var_value );
        %    % check
        %    if count(divided_dim) == tem_size(end) 
        %    else
        %       error('dimension error') 
        %    end
        % var_value = reshape( var_value, [], count(divided_dim) );
        
        
        % prepare for loading the index by groups
        % ### 1. generate count for each group 
        tem_Ng1 = floor( count(divided_dim) / Max_Count_per_group ); %
        tem_mod_val = mod( count(divided_dim), Max_Count_per_group );
        tem_Dcount_list = ones( 1, tem_Ng1 ) * Max_Count_per_group;
        if tem_mod_val > 0
            tem_Dcount_list = [ tem_Dcount_list, tem_mod_val ]; % Count value for each group
        end
        % ### 2. total number of groups
        tem_N_Dgroup = length( tem_Dcount_list );
        % ### 3. start index of each group
        tem_Dstart_list = start(divided_dim) + [ 0, cumsum( tem_Dcount_list(1:end-1) ) ]; % value of start for each group
        % ### 4. output id of each group
        tem_save_ind_bd = [0 cumsum(tem_Dcount_list)];
        %tem_save_ind_start = tem_save_ind_bd(1:end-1) + 1;
        %tem_save_ind_end   = tem_save_ind_bd(2:end);
        
        % ### load data 
        for ig = 1:tem_N_Dgroup
            
            % prepare [start count str] for each group
            tem_start = start;
            tem_count = count;
            tem_strid = strid;
            
            tem_start(divided_dim) = tem_Dstart_list(ig);
            tem_count(divided_dim) = tem_Dcount_list(ig);
            
            % disp
            disp([ datestr(now) '      ' VarDim_now(divided_dim).Name ': Block ' num2str(ig) ' of ' num2str(tem_N_Dgroup), ...
                                                                      ', Index ' num2str(tem_start(divided_dim)) ' - ' num2str(tem_start(divided_dim)+tem_count(divided_dim)-1) ' of ' num2str(start(divided_dim)) ' - ' num2str(start(divided_dim)+count(divided_dim)-1) ])
            % read data 
            count_err = 0;
            while count_err <= N_max_retry
                try
                    tem2 = netcdf.getVar( ncid0, varID0, tem_start, tem_count, tem_strid );
                    count_err = inf;
                catch err_log
                    fprintf('%s: %s\n',err_log.identifier, err_log.message);
                    count_err = count_err + 1;
                    pause(30) %retry after 30 seconds
                    disp(['Err, retry count: ' num2str( count_err )] );

                    if count_err == N_max_retry
                        if is_skip_blocks_with_errors
                            warning('prog:input', '%s: %s\n',err_log.identifier, err_log.message)
                            disp('Unexpected error. Retry exceeds max limit.. The error may occur in the server side. Those values will be skipped')
                            tem2 = nan( tem_count );
                        else 
                            error('prog:input','%s: %s\n',err_log.identifier, err_log.message)
                        end
                    end
                end
            end
            
            % write data into the output file
            tem_putvar_start = zeros(size(count));
            tem_putvar_count = count;
            
            tem_putvar_start(divided_dim) = tem_save_ind_bd(ig) ; %
            tem_putvar_count(divided_dim) = tem_save_ind_bd(ig+1) - tem_save_ind_bd(ig);
            
            netcdf.putVar( ncid1, varID1, tem_putvar_start, tem_putvar_count, tem2 );
            netcdf.sync( ncid1 ); % write buffer onto disk.

            clear tem2
        end

        clear tem_size tem_start tem_count tem_strid ig  
    else
        error('E09: unexpected condition!')
    end

    clear VarDim_now VarDimIND_now varID1 varID0 var_value
end

netcdf.close(ncid0);
netcdf.close(ncid1);

% END =====================================================================
% =========================================================================

%% Other Examples-1: 2D Lon/Lat example:\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

% % % % 
% % % % % Input file address
% % % % filename0 = 'http://tds.hycom.org/thredds/dodsC/GLBa0.08/expt_90.9/2013';
% % % % % output file address
% % % % filename1 = 'HYCOM_SCS_HL_2013_JanAug4.nc';
% % % % 
% % % % % lon/lat/depth/time limits
% % % % lonlimit = [107 117];
% % % % latlimit = [2 9];
% % % % depthlimit = [-inf inf];
% % % % timelimit  = [datenum(2013,1,1) datenum(2013,1,2)];
% % % % 
% % % % % get timelist in matlab unit
% % % % time_str = 'MT';
% % % % time = FUN_nc_varget(filename0, time_str);
% % % % time_unit = FUN_nc_attget(filename0, time_str, 'units' );
% % % % [time0, unit_str, unit_to_day] = FUN_nc_get_time0_from_str( time_unit );
% % % % timelimit  = (timelimit - time0)/unit_to_day ;
% % % % 
% % % % 
% % % % %% prepare for 2-D lon/lat ================================================
% % % % 
% % % % % loading data ------------------------------------------------------------
% % % %     x = FUN_nc_varget(filename0, 'X');
% % % %     y = FUN_nc_varget(filename0, 'Y');
% % % %     lon = FUN_nc_varget(filename0, 'Longitude');
% % % %     lat = FUN_nc_varget(filename0, 'Latitude');
% % % % 
% % % % % check dims --------------------------------------------------------------
% % % %     if length(x) == size(lon,1) && length(y) == size(lon,2)
% % % %     else
% % % %         error('E11')
% % % %     end
% % % % % find x/y limits ---------------------------------------------------------
% % % %     selected_loc = lon >= lonlimit(1) & lon <= lonlimit( 2 ) & lat >= latlimit(1) & lat <= latlimit( 2 ) ;
% % % %     x_loc = any( selected_loc, 2 );
% % % %     y_loc = any( selected_loc, 1 );
% % % % 
% % % %     x_load = x(x_loc);
% % % %     xlimit = [min(x_load) max(x_load) ];
% % % %     y_load = y(y_loc);
% % % %     ylimit = [min(y_load) max(y_load) ];
% % % % 
% % % % %% Download ===============================================================
% % % %     FUN_nc_OpenDAP_with_limit( filename0, filename1, {'x','y','depth',time_str}, {xlimit, ylimit depthlimit timelimit}, [], [], time_str  )

