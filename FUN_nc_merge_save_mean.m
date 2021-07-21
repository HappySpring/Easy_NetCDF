function FUN_nc_merge_save_mean( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode, list_var_excluded, min_num_valid, varargin )
% This will murge a list of netcdf files within a specific time-space
% range.
%
% -------------------------------------------------------------------------
% INPUT: 
%   input_dir: The folder in which all input netcdf given by "filelist" is
%              located. If it is not empty, the path given here will be used
%              as a prefix (by fullfile) to the paths given in filelist.
%
%   filelist : the list of files which will be merged.
%              It could be an array of cells, in which one cell contains one path,
%              or an array of strings in which one row contains one one path, 
%              or an array of strcutures like what returned by the built-in command "dir".
%
%   output_fn [string]: Name of output netcdf file
%   merge_dim_name [cell]: name of the dimension in which all varialbes will be
%               merged.(Variables without dimension "merge_dim_name" will be copied from the first file given in filelist)
%
%   compatibility_mode [logical]: This is for some old version of matlab.
%               compatibility_mode on will also disable compression.
%
%   list_var_excluded [cell]: This is a cell listing the name of variables which
%               should not be included in output files.
%
%   min_num_valid [1x1], (optional): Minimal number of valid (non-nan) values required to 
%               calculate the mean value. The mean value at locations with 
%               less than this number of valid values will be set to nan in 
%               the output file.
%               **Please note that even if "var_valid_value_counted" is not empty,  
%               the "min_num_valid" will be applied to all variables indepently 
%               
%
%   [additonal parameters]: plase refer to the code section "set default value"
% -------------------------------------------------------------------------
% Output:
%      
%        None
%
% -------------------------------------------------------------------------
% Note: To recongnize the axis correctly, there must be one variable
% named as by the axis!
% -------------------------------------------------------------------------
% exampel: 
%
%   input_dir    = '.';
% 
%   file_marker = 'jz08_0*.nc';
%   filelist = dir( fullfile( input_dir, file_marker ) ); % the order is controlled by this. No additional resort will be applied.
% 
%   merge_dim_name = 'time';
% 
%   output_fn = 'Merged_for_offline_test1234.nc'; % output filename
%   compatibility_mode = 1; %compatibility mode: old netcdf format will be
%           used if this is 1, otherwise, NETCDF4 will be used.
%   FUN_nc_merge(  input_dir, filelist, output_fn, 'time',  compatibility_mode);
%
% =========================================================================

% V1.21 2021-07-20 By L. Chi: support more styles of filelist. It could be
%                             cells, structures (by dir) or an string array
%                             now.
% V1.20 2020-10-08 by L. Chi: Add input variable "min_num_valid"
% V1.11 2018-05-20 by L. Chi: error => warning for E51
% V1.10 2018-05-18 by L. Chi: Add list_var_excluded
% V1.00 2017-09-25 by L. Chi: initial version (L.Chi.Ocean@outlook.com)
%% set default value
if ~exist('list_var_excluded','var') 
    list_var_excluded = [];
end

if ~exist('min_num_valid','var') || isempty( min_num_valid );
    min_num_valid = 0;
end

% this is the output variable name which contains the number of valid data
varname_save_valid_count = FUN_codetools_read_from_varargin( varargin, 'varname_save_valid_count', [], false );

% This is the variable in the input files the valid number of which is counted in "varname_save_valid_count"
var_valid_value_counted = FUN_codetools_read_from_varargin( varargin, 'var_valid_value_counted', [], false );

if xor( isempty(varname_save_valid_count), isempty(var_valid_value_counted) )
   error(['"var_valid_value_counted" and "var_valid_value_counted" must be provided at the same time']) 
end



%% set filelist

if iscell( filelist )
    filepath_list = filelist ;
    if ~isempty( input_dir )
        filepath_list = fullfile( input_dir, filepath_list ) ;
    end
    
elseif ischar( filelist )
    filepath_list = mat2cell( filelist, ones(size(filelist,1),1), size(filelist,2) );
    if ~isempty( input_dir )
        filepath_list = fullfile( input_dir, filepath_list ) ;
    end
    
elseif isfield( filelist, 'folder' ) && isempty( input_dir )
    filepath_list = fullfile( { filelist(:).folder }, { filelist(:).name } );
    
elseif isfield( filelist, 'name' )
    filepath_list = { filelist(:).name };
    if ~isempty( input_dir )
        filepath_list = fullfile( input_dir, filepath_list ) ;
    end
    
else
    error('Unknown input format for filelist');
end
    
%% search all files to determine the information of the merged dimensiona.
MV.all = [];  % information of the merged dimension
MV.ind_start = nan( length( filepath_list ) );
MV.ind_end   = nan( length( filepath_list ) );

for ii = 1:length( filepath_list )
   tem = FUN_nc_varget( filepath_list{ii}, merge_dim_name ); 
   MV.all = [ MV.all ; tem(:) ];
   
   if ii == 1
       MV.ind_start(ii) = 1;
       MV.ind_end(ii)   = length( tem );
   else
       MV.ind_start(ii) = MV.ind_end(ii-1)+1;
       MV.ind_end(ii)   = MV.ind_start(ii) + length( tem ) - 1;
   end
   
   clear tem
end
   clear ii
   
   % the total length of the merged dimension.
   MV.N = length( MV.all );
   
%% check: the values of the merged variable should increase monoically.
% if length( MV.all ) == length( unique( MV.all ) )
%     % Pass: No repeated values exist
% else
%     error('E51: repeated values detected in the selected merging variable!') 
% end

if all( diff( MV.all ) > 0 )
    % Pass: monotonic variable
else
    warning('[warning] E51: the merged variable must increase monoically!')
end

%% Load dimensional information from the sample file
sample_fn = filepath_list{1};

info0 = ncinfo(sample_fn);
ncid0 = netcdf.open( sample_fn, 'NOWRITE' );


% delete variables without any values -------------------------------------
delete_var = [];
for iv = 1:length( info0.Variables );
   if isempty( info0.Variables(iv).Dimensions )
        delete_var = [delete_var iv];
   end
end
    clear iv
    
for ii = 1:length( delete_var ) 
    if ii == 1
        disp('****The following variables will not be included in the merged file****');
    end
    disp( ['This variable will not be included <= ' info0.Variables(delete_var(ii)).Name] );
end
    clear ii
info0.Variables( delete_var ) = [];
clear delete_var
%% prepare dimensions

for ii = 1:length(info0.Dimensions)
    
    % decide wehter this dim should be loaded partly.
    dim_cmp_loc = strcmp( info0.Dimensions(ii).Name, merge_dim_name );
    
    if any( dim_cmp_loc )
        % load by part
        
        var_str_now = merge_dim_name;
        varid_now = netcdf.inqVarID(ncid0, var_str_now ) ;
        var_now = netcdf.getVar(ncid0, varid_now ) ;
                
        info1.Dim(ii).Name        = var_str_now;
        info1.Dim(ii).Length      = 1; %MV.N;
        info1.Dim(ii).MatInd      = ii;  % Location of this variable in the Dim Matrix
        info1.Dim(ii).originalVal = MV.all;
        info1.Dim(ii).start       = 0;
        info1.Dim(ii).count       = 1; %MV.N;
        %info1.Dim(ii).ind         = ind;
        info1.Dim(ii).is_seleted  = true;
        info1.Dim(ii).is_unlimit  = info0.Dimensions(ii).Unlimited;
    else
        
        info1.Dim(ii).Name        = info0.Dimensions(ii).Name;
        info1.Dim(ii).Length      = info0.Dimensions(ii).Length;
        info1.Dim(ii).MatInd      = ii;
        info1.Dim(ii).originalVal = [];
        info1.Dim(ii).start       = 0;
        info1.Dim(ii).count       = info1.Dim(ii).Length;
        %info1.Dim(ii).ind         = 1:info1.Dim(ii).Length ;
        info1.Dim(ii).is_seleted  = false;
        info1.Dim(ii).is_unlimit  = info0.Dimensions(ii).Unlimited;
    end
end

netcdf.close( ncid0 );
%% open new file and write dimensions
if compatibility_mode == 1
    ncid1 = netcdf.create( output_fn, 'CLOBBER' );
else
    ncid1 = netcdf.create( output_fn, 'NETCDF4' );
end

for ii = 1:length( info1.Dim )
%     if Dim(ii).<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    if info1.Dim(ii).is_unlimit 
        %define a dimension with fixed length
        dimID1(ii) = netcdf.defDim(ncid1, info1.Dim(ii).Name, netcdf.getConstant('NC_UNLIMITED') );
    else
        %define a dimension with a fixed length
        dimID1(ii) = netcdf.defDim(ncid1, info1.Dim(ii).Name , info1.Dim(ii).Length );
    end
end
    clear ii
    
% set global ATT
for ii = 1:length(info0.Attributes)
    netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), info0.Attributes(ii).Name, info0.Attributes(ii).Value);
end
    clear ii
    
netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), 'Sample Source', sample_fn );
netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), 'Merge Date', datestr(now) );

netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), ['Merged in this dimension'], merge_dim_name );

% for ii = 1:length( merge_dim_name )
%     netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), ['Copy Range-' num2str(ii)], [dim_limit_var{ii} ' ' num2str( dim_limit_val{ii} )] );
% end

netcdf.endDef(ncid1) % exit define mode.

%% load/write variable
for iv = 1:length(info0.Variables)
    disp(['---------- Merging variable ' info0.Variables(iv).Name ' ----------'])
    
    if ismember( info0.Variables(iv).Name, list_var_excluded )
       disp(['[skipped] The variable ' info0.Variables(iv).Name ' will be skipped because it is listed in the excluded list' ])
       continue
    end
    
   % Prepare for varialbes
    VarDim_now = info0.Variables(iv).Dimensions;    
    for id = 1:length( VarDim_now )
        VarDimIND_now(id) = FUN_struct_value_for_specific_name( info1.Dim, 'Name', VarDim_now(id).Name, 'MatInd' );
    end
        clear id 
        
    is_merge = false;
    merge_dim = nan;
    for id = 1:length( VarDimIND_now )
        if info1.Dim( VarDimIND_now(id) ).is_seleted 
            is_merge = true;
            merge_dim = id;
        end
    end
        clear id 
        
    % Define Variable -----------------------------------------------------
    netcdf.reDef(ncid1) % start define mode.
    
    if is_merge
        disp('For the variables which will be averaged, their types are forced to be double!')
        data_type_now = FUN_nc_defVar_datatypeconvert('double');
    else
        data_type_now =FUN_nc_defVar_datatypeconvert(info0.Variables(iv).Datatype);
    end
    
    varID1 = netcdf.defVar( ncid1, ...
        info0.Variables(iv).Name, ...
        data_type_now, ...
        dimID1( VarDimIND_now ) );
    
    if compatibility_mode == 1
        % This is not supported by NETCDF older than version 4.
        % netcdf.defVarDeflate( ncid1, varID1, true, true, 0 );%compression level-1 basic
    else
        netcdf.defVarDeflate( ncid1, varID1, true, true, 1 );%compression level-1 basic
    end
    
    
    % define the variable containing the number of valid data used for average.
    if ~isempty( varname_save_valid_count ) && strcmpi( var_valid_value_counted, info0.Variables(iv).Name )
        
        varID_count_valid = netcdf.defVar( ncid1, ...
            varname_save_valid_count, ...
            data_type_now, ...
            dimID1( VarDimIND_now ) );
        
        if compatibility_mode == 1
            % This is not supported by NETCDF older than version 4.
            % netcdf.defVarDeflate( ncid1, varID1, true, true, 0 );%compression level-1 basic
        else
            netcdf.defVarDeflate( ncid1, varID_count_valid, true, true, 1 );%compression level-1 basic
        end
    end

    
    % Add attribute ----------------------------
    for ii = 1:length(info0.Variables(iv).Attributes)
        if is_merge
            % For merged variable, the _FillValue/scale_factor and offset
            % will be ignored. All data will be saved in type "double".
            if strcmp( info0.Variables(iv).Attributes(ii).Name, '_FillValue') ...
                    || strcmp( info0.Variables(iv).Attributes(ii).Name, 'FillValue') ...
                    || strcmp( info0.Variables(iv).Attributes(ii).Name, 'missing_value') ...
                    || strcmp( info0.Variables(iv).Attributes(ii).Name, 'scale_factor') ...
                    || strcmp( info0.Variables(iv).Attributes(ii).Name, 'add_offset') 
                disp('[Notice] All Attributes related to FillValue/scale_factor/add_offset will be ignored for the merged variable')
                
            else
                netcdf.putAtt( ncid1, varID1, info0.Variables(iv).Attributes(ii).Name, info0.Variables(iv).Attributes(ii).Value);
            end
            
        else % All other variables ----------------------------------------
            
            if strcmp( info0.Variables(iv).Attributes(ii).Name, '_FillValue')
                % _FillValue can only be written by specific commends.
                netcdf.defVarFill( ncid1, varID1, false, info0.Variables(iv).Attributes(ii).Value ) 
            else
                netcdf.putAtt( ncid1, varID1, info0.Variables(iv).Attributes(ii).Name, info0.Variables(iv).Attributes(ii).Value);
            end
        end
    end
        clear ii
        
    netcdf.endDef(ncid1)

    % write varialbe ------------------------------------------------------
    if is_merge
        
        start = [];
        count = [];
        strid = [];
        for jj = 1:length( VarDimIND_now )
            start = [start info1.Dim( VarDimIND_now(jj) ).start];
            count = [count info1.Dim( VarDimIND_now(jj) ).count];
            strid = [strid 1];%stride
        end
        
        
        for ii = 1:length( filepath_list )
            
            %start( merge_dim ) = MV.ind_start(ii) - 1;
            %count( merge_dim ) = MV.ind_end(ii) - MV.ind_start(ii) + 1;
            
            disp(['Loading from ' filepath_list{ii} ])
            
            var_value{ii} = FUN_nc_varget_enhanced(  filepath_list{ii},  info0.Variables(iv).Name  );
            
            %ncid2 = netcdf.open( filepath_list{ii}, 'NOWRITE' );
            %
            %varID2 = netcdf.inqVarID( ncid2, info0.Variables(iv).Name );
            %var_value{ii} = netcdf.getVar( ncid2, varID2 );
            
            %netcdf.close( ncid2 );
            
        end
        
        
        % calculate mean --------------
        var_value = cat( merge_dim, var_value{:} );
        
        % count number of valid values
        if min_num_valid > 0
            tem_num_valid = sum( ~isnan( var_value ), merge_dim );
        end
        
        if ~isempty( varname_save_valid_count ) && strcmpi( var_valid_value_counted, info0.Variables(iv).Name )
            output_num_valid = sum( ~isnan( var_value ), merge_dim );
            netcdf.putVar( ncid1, varID_count_valid, start, count, strid, output_num_valid);
        end
        
        var_value = nanmean( var_value, merge_dim );
        
        if min_num_valid > 0
            var_value( tem_num_valid < min_num_valid ) = nan;
        end
        
        netcdf.putVar( ncid1, varID1, start, count, strid, var_value);
        
        clear var_value
        
    else
        disp(['Loading from the sample file: ' sample_fn])
        ncid0 = netcdf.open( sample_fn, 'NOWRITE' );
        varID0 = netcdf.inqVarID( ncid0, info0.Variables(iv).Name );
        var_value = netcdf.getVar( ncid0, varID0 );
        netcdf.putVar( ncid1, varID1, var_value);
        netcdf.close( ncid0 );
    end
    
    clear VarDim_now VarDimIND_now varID1 varID0 var_value
end

netcdf.close(ncid1);
