function pregen_info = FUN_nc_gen_presaved_netcdf_info_v2( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path, varargin)
% pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path )
% This is an internal function called by FUN_nc_varget_enhanced_region_2_multifile
% Please refer to the comments in "FUN_nc_varget_enhanced_region_2_multifile.m" for input parameters.
%
%
% 2024-07-31 v2.10 by L. Chi
%                             In windows system, the path separator is
%                             converted to "/". So the generated presaved
%                             info works on both windows and linux.
%                             
% 2023-11-19 v2.00 by L. Chi. Remove duplicated information saved in
%                                 pregen_info variable, which is ~ 10% of
%                                 the previous ones. 
%                             Disable dimension and variable check for each
%                             files to speed up the codes.
% 2021-08-02 V1.30 By L. Chi. It is possible to ignore certain dimensions
%                              and varialbes now by the following two
%                              parameters
%                                 + ignore_dim_name
%                                 + ignore_var_name
% 2021-07-05 V1.20 by L. Chi. `dim_varname` accepts manually set nuerical array as
%                  input.
% 2021-06-29 V1.10 By L. Chi: (partly) support outputting relative path 
%                               The input "path_relative_to" must be part of the absolute path for each file.
% xxxx-xx-xx V1.00 by L. Chi (L.Chi.Ocean@outlook.com)
%
%% 
% =========================================================================
% # Example
% =========================================================================
%     filelist       = dir('Demo_*.nc');
%     merge_dim_name = 'time'; % merge data in "time" dimension.
%     dim_name       = { 'lon', 'y', 'time' }; % In the demo files, the meridional dimension is named as "y".
%     dim_varname    = {'lon','lat','time'}; % This is to force the function to read values for the meridional dimension from the variable "lat". 
%     time_var_name  = 'time'; % convert values in "time" to matlab units (days since 0000-01-00 00:00). This is optional
% 
%     output_file_path = 'Presaved_info_demo.mat';
% 
%     % Please note that **absolute** file paths are saved in the generated file. If you moved the data, you need to run this again
%     pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path );
%     
%     % with relative path
%     pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path, 'path_relative_to', pwd );

%% 
% =========================================================================
% # set default values
% =========================================================================

if ~exist('dim_name','var')
    dim_name = [];
end

if ~exist('dim_varname','var')
    dim_varname = [];
end

if ~exist('time_var_name','var')
    time_var_name = [];
end

if ~exist('merge_dim_name','var')
    merge_dim_name = [];
end


pregen_info.format = 'v2';

pregen_info.merge_dim.name = merge_dim_name;

% If "path_relative_to" is not empty, the "folder" in the output structure
% will be replaced by paths relative to "path_relative_to"
[path_relative_to, varargin] = FUN_codetools_read_from_varargin( varargin, 'path_relative_to', [], true );


% Check whether each file contains same variables and dimensions
% The default value is set to false to speed up the codes
[is_check_each_file, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_check_each_file', false, true );

% Ignore the following dimensions and variables
[ignore_dim_name, varargin] = FUN_codetools_read_from_varargin( varargin, 'ignore_dim_name', [], true );
[ignore_var_name, varargin] = FUN_codetools_read_from_varargin( varargin, 'ignore_var_name', [], true );

if ~isempty( ignore_dim_name ) && ~iscell( ignore_dim_name )
   ignore_dim_name = {ignore_dim_name}; 
end

if ~isempty( ignore_var_name ) && ~iscell( ignore_var_name )
   ignore_var_name = {ignore_var_name}; 
end

pregen_info.param.ignored_dim = ignore_dim_name;
pregen_info.param.ignored_var = ignore_var_name;

if ~isempty(varargin)
   disp(varargin)
   error('Unknown paramters detected!'); 
end


%%
% =========================================================================
% # handle filelist format 
% =========================================================================

if ischar( filelist ) 
    if size( filelist, 1 ) == 1
        filelist = {filelist};
    else
        filelist = mat2cell( filelist, ones(size(filelist,1),1), size(filelist,2));
    end
end

if iscell( filelist )
    filepath_list = filelist ;

elseif isfield( filelist, 'folder' )
    filepath_list = fullfile( { filelist(:).folder }, { filelist(:).name } );
    
elseif isfield( filelist, 'name' )
    filepath_list = { filelist(:).name };
else
    error('Unknown input format for filelist');
end
    

%% 
% =========================================================================
% # load variable info.
% Note: all files must contain same variables.
% =========================================================================

fn_demo = filepath_list{1} ;
fn_info = ncinfo(fn_demo) ;

varlist = {fn_info.Variables.Name};
dimlist = {fn_info.Dimensions.Name};

if ~isempty( ignore_dim_name )
    rm_dim_loc = ismember( dimlist, ignore_dim_name );
    
    if any( rm_dim_loc )
        fprintf('  The following dimension and associated variables will be ignored:\n')
        fprintf('      Remove dimension: %s \n', dimlist{rm_dim_loc} )
        dimlist = dimlist(~rm_dim_loc);
    end
else
    % Pass
    
    %rm_dim_loc = [];
end

% ## load dimensions name for each variable
rm_var_loc = false(size(varlist));
for iv = 1:length( varlist )
    
    vn = varlist{iv};
    pregen_info.var(iv).Name = vn;
    tem = fn_info.Variables(iv).Dimensions;
    
    if ~isempty( tem )
        tem = rmfield( tem, 'Length' );  % aovid confusing results since the length for the merged dim is not true at this point.
    else
        % The code reaches here if the variable does not associated to any
        % dimension.
    end
    
    pregen_info.var(iv).Dimensions = tem;
    
    if ( ~isempty( ignore_dim_name ) && ~isempty( tem ) &&  any( ismember( {tem.Name}, ignore_dim_name ) ) ) ...
            || ( ~isempty(ignore_var_name) && ismember( {vn}, ignore_var_name) )
        
        rm_var_loc(iv) = true;
        fprintf('  The following variables will be ignored since they are associated an ignored dimension:\n')
        fprintf('      Remove variable: %s \n', vn )
    end
end
iv = [];

if any( rm_var_loc )
    % the variables will be ingored includes both variables associated ingnored
    % dimensions and variables listed in "ignore_var_name".
    %    
    pregen_info.var(rm_var_loc) = [];  
    varlist(rm_var_loc) = [];
else
    pregen_info.param.ignored_var = [];
end

% ## find corresponding variable name of each dimension
% If it cannot be found, and empty name will be allocated.
for idim = 1:length( dimlist )
    dn = dimlist{idim};
    
    tmp_dim_ind = find( strcmp(  dn, dim_name ) );
    
    if ~isempty( tmp_dim_ind )
        % The axis associated with the current dimension has been
        % provided manually
        dim_varname_list{idim} = dim_varname{ tmp_dim_ind };
        
    elseif any( strcmpi( dn, varlist ) )
        % A variable share the same name with the current dimesion has been found
        % Tt will be used as the axis associated with the current
        % dimension.
        dim_varname_list{idim} = dn;
    else
        % Cannot find any variables assocated with the current dimension
        % Its axis will be defined as 1:dim_length
        dim_varname_list{idim} = [];        
    end
    
end
idim = [];



%%
% =========================================================================
% load shared dimensions (dimension other than the one to be merged)
% =========================================================================


% interface
fn = filepath_list{1};

% load info
fn_info = ncinfo(fn) ;

% ## load dimensions ======================================================

for idim = 1:length( dimlist )

    % interface
    dn  = dimlist{idim}; % dimension name
    dim_varname_now = dim_varname_list{idim};

    % load basic info of the current dimension
    pregen_info.dim(idim).name = dn;
    tmp_ind = FUN_struct_find_field_ind( fn_info.Dimensions, 'Name', dn );

    pregen_info.dim(idim).length       = fn_info.Dimensions(tmp_ind).Length ;
    pregen_info.dim(idim).is_unlimited = fn_info.Dimensions(tmp_ind).Unlimited ;

    % load axis associated with each dimension
    pregen_info.dim(idim).is_time       = false;
    pregen_info.dim(idim).is_dim_merged = false;

    if strcmpi( dn, merge_dim_name )
        pregen_info.dim(idim).is_dim_merged = true;
    end
           
    if isempty( dim_varname_now ) || all( isnumeric( dim_varname_now ) & isnan( dim_varname_now ) )
        pregen_info.dim(idim).value   = 1 : pregen_info.dim(idim).length;
        pregen_info.dim(idim).varname = [];

    elseif strcmpi( dim_varname_now, time_var_name ) %The current dim is time
        pregen_info.dim(idim).value   = FUN_nc_get_time_in_matlab_format( fn, dim_varname_now );
        pregen_info.dim(idim).is_time = true;
        pregen_info.dim(idim).varname = dim_varname_now;

    elseif ischar( dim_varname_now ) % dim_varname_now is the name of a variable associated to this dimension
        pregen_info.dim(idim).value   = FUN_nc_varget_enhanced( fn, dim_varname_now );
        pregen_info.dim(idim).varname = dim_varname_now;

    elseif isnumeric( dim_varname_now ) % dim_varname_now contains a manually provded numerical matrx.

        if length( dim_varname_now ) == pregen_info.dim(idim).length
            pregen_info.dim(idim).value   = dim_varname_now;
            pregen_info.dim(idim).varname = dn;
        else
            error('The length of input dim_varname does not match the length of the assocated dimension!')
        end

    else
        error('Unexpected dim_varname!');
    end

end
    

%% 
% =========================================================================
% # load dimension info from each file
% =========================================================================

dim_varname_merged = dim_varname_list{ strcmpi( dim_varname_list, merge_dim_name ) };

for ii = 1:length( filepath_list ) 
    
    % =====================================================================
    
    % interface
    fn = filepath_list{ii};
    pregen_info.file(ii).path = fn;    
    fprintf( '%s \n',fn);
    
    % load info
    
    if is_check_each_file == false
        
        ncid = netcdf.open( fn );
        dimid= netcdf.inqDimID( ncid, dim_varname_merged );
        
        fn_info = [];
        [ fn_info.Dimensions.Name, fn_info.Dimensions.Length ] = netcdf.inqDim( ncid, dimid );

        tmp.unlimit_dim_id = netcdf.inqUnlimDims(ncid);
        fn_info.Dimensions.Unlimited = tmp.unlimit_dim_id == dimid;
        
        netcdf.close(ncid);
        
    else

        fn_info = ncinfo(fn) ;

        % remove ignored dimensions from "ignore_dim_name".
        %   Variables assocated to those dimensions will also be ignored. 
        if ~isempty(ignore_dim_name)
            rm_dim_loc = ismember( {fn_info.Dimensions.Name}, ignore_dim_name );
    
            % remove dimensions to be ignored
            if any(rm_dim_loc)
                % remove ignored dimensions
                fprintf('  The following dimension from the current file is ignored:\n')
                fprintf('      Ignored dimension: %s \n', fn_info.Dimensions(rm_dim_loc).Name );
                fn_info.Dimensions(rm_dim_loc) = [];
            end
        end
            
        % remove variables to be ignored
        if ~isempty( ignore_dim_name ) || isempty( ignore_var_name )
    
            rm_var_loc = false( size( fn_info.Variables ) );
    
            for jv = 1:length( fn_info.Variables )
                tem_dim = fn_info.Variables(jv).Dimensions;
    
                if ( ~isempty( ignore_dim_name ) && ~isempty( tem_dim ) &&  any( ismember( {tem_dim.Name}, ignore_dim_name ) ) ) ...
                        || ( ~isempty(ignore_var_name) && ismember( {fn_info.Variables(jv).Name}, ignore_var_name) )
                    rm_var_loc(jv) = true;
                    fprintf('  The following variables will be ignored since they are associated an ignored dimension:\n')
                    fprintf('      Remove variable: %s \n', fn_info.Variables(jv).Name )
                end
            end
            fn_info.Variables(rm_var_loc) = [];
    
        end

    end
    
    % ## Check ============================================================
    
    if is_check_each_file == true 
        % skip this will accelerate the codes

        % check - variables
        tmp_xor = setxor( {fn_info.Variables.Name}, varlist );
        if isempty( tmp_xor )
            % PASS
        else
           fprintf('Error with following variables: \n      ');
           fprintf('%s ',tmp_xor{:})
           fprintf('\n')
           error('All files must contain same variables'); 
        end
        
        % check - dimensions
        tmp_xor = setxor( {fn_info.Dimensions.Name}, dimlist );
        if isempty( tmp_xor )
            % PASS
        else
           fprintf('Error with following dimensions: \n      ');
           fprintf('%s ',tmp_xor{:})
           fprintf('\n')
           error('All files must contain same dimensions'); 
        end

    end
    
    % ## load the dimension to be merged only =============================
    
    % load basic info of the current dimension
    pregen_info.file(ii).dim.name   = merge_dim_name;
    tmp_ind = FUN_struct_find_field_ind( fn_info.Dimensions, 'Name', merge_dim_name );

    pregen_info.file(ii).dim.length = fn_info.Dimensions(tmp_ind).Length ;
    pregen_info.file(ii).dim.is_unlimited = fn_info.Dimensions(tmp_ind).Unlimited ;

    % load axis associated with each dimension
    pregen_info.file(ii).dim.is_time = false;

    if isempty( dim_varname_merged ) || all( isnumeric( dim_varname_merged ) & isnan( dim_varname_merged ) )
        pregen_info.file(ii).dim.value = 1 : pregen_info.file(ii).dim.length;
        pregen_info.file(ii).dim.varname = [];

    elseif strcmpi( dim_varname_merged, time_var_name ) %The current dim is time
        pregen_info.file(ii).dim.value = FUN_nc_get_time_in_matlab_format( fn, dim_varname_merged );
        pregen_info.file(ii).dim.is_time = true;
        pregen_info.file(ii).dim.varname = dim_varname_merged;

    elseif ischar( dim_varname_merged ) % dim_varname_now is the name of a variable associated to this dimension
        pregen_info.file(ii).dim.value   = FUN_nc_varget_enhanced( fn, dim_varname_merged );
        pregen_info.file(ii).dim.varname = dim_varname_merged;

    elseif isnumeric( dim_varname_merged ) % dim_varname_now contains a manually provded numerical matrx.

        if length( dim_varname_merged ) == pregen_info.file(ii).dim.length
            pregen_info.file(ii).dim.value   = dim_varname_merged;
            pregen_info.file(ii).dim.varname = merge_dim_name;
        else
            error('The length of input dim_varname does not match the length of the assocated dimension!')
        end
    else
        error('Unexpected dim_varname!');
    end
    
    % control shape
    pregen_info.file(ii).dim.value = pregen_info.file(ii).dim.value(:);
    
    %idim = [];
end


%% 
% =========================================================================
% # index of dimension for each variable
% =========================================================================

for iv = 1:length( varlist )    
    for idim = 1:length( pregen_info.var(iv).Dimensions )
        pregen_info.var(iv).Dim_ind(idim) = find( strcmpi( pregen_info.var(iv).Dimensions(idim).Name, dimlist ) );
    end
end

%% 
% =========================================================================
% # replace absolute path by relatve path
% =========================================================================
% This feature is partly supported at this point.
%   The input "path_relative_to" must be part of the absolute path for each file.
%   This should be enough for most cases. 

if ~isempty( path_relative_to )
    
    path_relative_to = fullfile(path_relative_to);
    
    if length(path_relative_to) > 1 && ( path_relative_to(end) == '\' || path_relative_to(end) == '/' )
        path_relative_to = path_relative_to(1:end-1);
    end
    
    
    for ii = 1:length( pregen_info.file )
        
        [tem_pathstr, tem_name, tem_ext] = fileparts( pregen_info.file(ii).path );
        
        %pregen_info.file(ii).name = [tem_name, tem_ext];
        
        tem_match_ind = strfind( tem_pathstr, path_relative_to );
        if length( tem_match_ind ) == 1 && tem_match_ind == 1
            % find the relative path from the absolute path.
            pregen_info.file(ii).path = ['.' pregen_info.file(ii).path( length(path_relative_to)+1 : end )];            
            pregen_info.param.is_relative_path = true;
            
        elseif ispc == 1
            % If this is run in windows, repeath the search after converting characters in the path to upper cases. 
            %
            % Windows is not case sensitive in most cases.
            % Warning: This is not guranteed. Win 10 can be configured as a case sensitive system to 
            %          be compatible to WSL. Use with caution.
            
            warning('Did not found the input "path_relative_to" from the absolute path. Retry after setting all charaters to upper cases!');
            
            tem_pathstr_U = upper(tem_pathstr);
            path_relative_to_U = upper(path_relative_to);
            
            tem_match_ind = strfind( tem_pathstr_U, path_relative_to_U );
                        
            if length( tem_match_ind ) == 1 && tem_match_ind == 1
                pregen_info.file(ii).path = ['.' pregen_info.file(ii).path( length(path_relative_to)+1 : end )];            
                pregen_info.param.is_relative_path = true;
            else
                error('Cannot find the input "path_relative_to" from the absolute path!');
            end
            
        else
            error('Cannot find the input "path_relative_to" from the absolute path!');
        end
        
    end
    
else
    pregen_info.param.is_relative_path = false;    
end


%% 
% % =======================================================================
% # correct values for the merged dimension.
% =========================================================================

nm = 0;
for ii = 1:length( pregen_info.file )
    nm = nm + pregen_info.file(ii).dim.length;
end

tmp_dim_merged_val = nan(nm, 1);
tmp_dim_merged_fileID = nan(nm,1);
n0 = 0;
for ii = 1:length( pregen_info.file )
    n = pregen_info.file(ii).dim.length;
    tmp_dim_merged_val(n0+1:n0+n)    = pregen_info.file(ii).dim.value;
    tmp_dim_merged_fileID(n0+1:n0+n) = ii;
    n0 = n0 + n;
end

if n0 == nm 
else
    error
end

mdimid = find([pregen_info.dim(:).is_dim_merged]);
pregen_info.dim(mdimid).value  = tmp_dim_merged_val;
pregen_info.dim(mdimid).length = nm;

pregen_info.merge_dim.value = tmp_dim_merged_val;
pregen_info.merge_dim.length= nm;
pregen_info.merge_dim.files = tmp_dim_merged_fileID;

%% 
% =========================================================================
% # update file path
% =========================================================================
if ispc  
    disp(' [Current system: windows] The path separator "\" will be replaced by linux path separator "/"');
    disp('   matlab is able to handle "/" in Windows properly, however, a separator of "/" causes problems in Linux.');
    disp('   This will make sure the generated presaved netcdf info works on both Windows and Linux');

    for ii = 1:length( pregen_info.file )
        
        pregen_info.file(ii).path = strrep( pregen_info.file(ii).path, '\', '/');

    end

end


%% 
% =========================================================================
% # Output
% =========================================================================
if ~isempty( output_file_path )
    fprintf('writting into %s \n', output_file_path )
    save( output_file_path, 'pregen_info' );
else
    fprintf('Results will not be written into the disk since `output_file_path` is empty \n');
end