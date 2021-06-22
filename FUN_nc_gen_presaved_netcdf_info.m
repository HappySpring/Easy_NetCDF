function pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path )
% pregen_info = FUN_nc_gen_presaved_netcdf_info( filelist, merge_dim_name, dim_name, dim_varname, time_var_name, output_file_path )
% This is an internal function called by FUN_nc_varget_enhanced_region_2_multifile
% 
% xxxx-xx-xx V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

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

% ## load dimensions name for each variable

for iv = 1:length( varlist )
    
    vn = varlist{iv};
    pregen_info.var(iv).Name = vn;
    tem = fn_info.Variables(iv).Dimensions;
    tem = rmfield( tem, 'Length' );  % aovid confusing results since the length for the merged dim is not true at this point.
    pregen_info.var(iv).Dimensions = tem;
    
end
iv = [];

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
    sprintf( '%s \n',fn);
    
    % load info
    fn_info = ncinfo(fn) ;
    
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
    if isempty( tmp_xor );
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
        
        % load basic info of the current dimension
        pregen_info.file(ii).dim(idim).name   = dn;
        tmp_ind = FUN_struct_find_field_ind( fn_info.Dimensions, 'Name', dn );
        
        pregen_info.file(ii).dim(idim).length = fn_info.Dimensions(tmp_ind).Length ;
        pregen_info.file(ii).dim(idim).is_unlimited = fn_info.Dimensions(tmp_ind).Unlimited ;
        
        % load axis associated with each dimension
        pregen_info.file(ii).dim(idim).is_time = false;

        if isempty( dim_varname_now ) || ( isnumeric( dim_varname_now ) && isnan( dim_varname_now ) )
            pregen_info.file(ii).dim(idim).value = 1 : pregen_info.file(ii).dim(idim).length;
            pregen_info.file(ii).dim(idim).varname = [];
        elseif strcmpi( dim_varname_now, time_var_name )
            pregen_info.file(ii).dim(idim).value = FUN_nc_get_time_in_matlab_format( fn, dim_varname_now );
            pregen_info.file(ii).dim(idim).is_time = true;
            pregen_info.file(ii).dim(idim).varname = dim_varname_now;
        else
            pregen_info.file(ii).dim(idim).value   = FUN_nc_varget_enhanced( fn, dim_varname_now );
            pregen_info.file(ii).dim(idim).varname = dim_varname_now;
        end

    end
    
    idim = [];
end

ii = [];

%% 
% =========================================================================
% # index of dimension for each variable
% =========================================================================

for iv = 1:length( varlist )    
    for idim = 1:length( pregen_info.var(iv).Dimensions )
        pregen_info.var(iv).Dim_ind(idim) = find( strcmpi( pregen_info.var(iv).Dimensions(idim).Name, dimlist ) );
    end
end

%% output 
if ~isempty( output_file_path )
    fprintf('writting into %s \n', output_file_path )
    save( output_file_path, 'pregen_info' );
else
    fprintf('Results will not be written into the disk since `output_file_path` is empty \n');
end