function pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path, varargin)
% pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path )
% This is an internal function called by FUN_nc_varget_enhanced_region_2_multifile
% Please refer to the comments in "FUN_nc_varget_enhanced_region_2_multifile.m" for input parameters.
%
% 2023-11-20 v1.31 by L. Chi. It is recommended to replaced this by
%                             "FUN_nc_gen_presaved_netcdf_info_v2". An
%                             warning message has been added for this
%                             purpose. 
% 2021-08-02 V1.30 by L. Chi. It is possible to ignore certain dimensions
%                              and varialbes now by the following two
%                              parameters
%                                 + ignore_dim_name
%                                 + ignore_var_name
% 2021-07-05 V1.20 by L. Chi. `dim_varname` accepts manually set nuerical array as
%                  input.
% 2021-06-29 V1.10 by L. Chi: (partly) support outputting relative path 
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

warning('It is highly recommended to use replace this by "FUN_nc_gen_presaved_netcdf_info_v2" with significant performance improvements and ~90% reduced size of the output .mat file')

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

pregen_info.merge_dim.name = merge_dim_name;

% If "path_relative_to" is not empty, the "folder" in the output structure
% will be replaced by paths relative to "path_relative_to"
[path_relative_to, varargin] = FUN_codetools_read_from_varargin( varargin, 'path_relative_to', [], true );

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
% # load dimension info from each file
% =========================================================================



for ii = 1:length( filepath_list ) 
    
    % =====================================================================
    
    % interface
    fn = filepath_list{ii};
    pregen_info.file(ii).path = fn;    
    fprintf( '%s \n',fn);
    
    % load info
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

    
    
    % ## Check ============================================================
    
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
    
    % ## load dimensions ==================================================

    for idim = 1:length( dimlist )
        
        % interface
        dn  = dimlist{idim}; % dimension name
        dim_varname_now = dim_varname_list{idim};
        
        %if ii > 1 && ~strcmpi( dn, merge_dim_name )
        %    continue
        %end

        % load basic info of the current dimension
        pregen_info.file(ii).dim(idim).name   = dn;
        tmp_ind = FUN_struct_find_field_ind( fn_info.Dimensions, 'Name', dn );
        
        pregen_info.file(ii).dim(idim).length = fn_info.Dimensions(tmp_ind).Length ;
        pregen_info.file(ii).dim(idim).is_unlimited = fn_info.Dimensions(tmp_ind).Unlimited ;
        
        % load axis associated with each dimension
        pregen_info.file(ii).dim(idim).is_time = false;

        if isempty( dim_varname_now ) || all( isnumeric( dim_varname_now ) & isnan( dim_varname_now ) )
            pregen_info.file(ii).dim(idim).value = 1 : pregen_info.file(ii).dim(idim).length;
            pregen_info.file(ii).dim(idim).varname = [];
        elseif strcmpi( dim_varname_now, time_var_name ) %The current dim is time
            pregen_info.file(ii).dim(idim).value = FUN_nc_get_time_in_matlab_format( fn, dim_varname_now );
            pregen_info.file(ii).dim(idim).is_time = true;
            pregen_info.file(ii).dim(idim).varname = dim_varname_now;
        elseif ischar( dim_varname_now ) % dim_varname_now is the name of a variable associated to this dimension
            pregen_info.file(ii).dim(idim).value   = FUN_nc_varget_enhanced( fn, dim_varname_now );
            pregen_info.file(ii).dim(idim).varname = dim_varname_now;
        elseif isnumeric( dim_varname_now ) % dim_varname_now contains a manually provded numerical matrx.
            
            if length( dim_varname_now ) == pregen_info.file(ii).dim(idim).length
                pregen_info.file(ii).dim(idim).value   = dim_varname_now;
                pregen_info.file(ii).dim(idim).varname = dn;
            else
                error('The length of input dim_varname does not match the length of the assocated dimension!')
            end
        else
            error('Unexpected dim_varname!');
        end

    end
    
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
% =========================================================================
% # Output
% =========================================================================
if ~isempty( output_file_path )
    fprintf('writting into %s \n', output_file_path )
    save( output_file_path, 'pregen_info' );
else
    fprintf('Results will not be written into the disk since `output_file_path` is empty \n');
end