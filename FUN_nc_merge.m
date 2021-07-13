function FUN_nc_merge( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode )
% This will murge a list of netcdf files within a specific time-space
% range.
% -------------------------------------------------------------------------
% INPUT: 
%   input_dir: The folder in which all input netcdf given by "filelist" is
%              located. If it is not empty, the path given here will be used
%              as a prefix (by fullfile) to the paths given in filelist.
%   filelist : the list of files which will be merged.
%              It could be an array of cells, in which one cell contains one path,
%              or an array of strings in which one row contains one one path, 
%              or an array of strcutures like what returned by the built-in command "dir".
%
%   output_fn : Name of output netcdf file
%   merge_dim_name : name of the dimension in which all varialbes will be
%   merged.
%   (Variables without the dimension "merge_dim_name" will be copied from the first file given in the variable filelist)
% -------------------------------------------------------------------------
% Output: None
%
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

% 2021-07-12 V1.02 By L. Chi: support more ways to speicify input files to be merged. 
%                             "filelist" could be an array of cells, strings or structures now.
% xxxx-xx-xx V1.01 By L. Chi: fix a bug.
% 2017-09-25 V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%% prepare input file paths

% generate filepath_list from the input filelsit.

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
MV.ind_start = nan( length( filepath_list ), 1 );
MV.ind_end   = nan( length( filepath_list ), 1 );


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
    error('E51: the merged variable must increase monoically!')
end

%% Load dimensional information from the sample file
sample_fn = fullfile( input_dir, filepath_list{1} );

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
        info1.Dim(ii).Length      = MV.N;
        info1.Dim(ii).MatInd      = ii;  % Location of this variable in the Dim Matrix
        info1.Dim(ii).originalVal = MV.all;
        info1.Dim(ii).start       = 0;
        info1.Dim(ii).count       = MV.N;
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
%% load/write variable
for iv = 1:length(info0.Variables)
    disp(['---------- Merging variable ' info0.Variables(iv).Name ' ----------'])
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
    if iv > 1
        netcdf.reDef(ncid1)
    end
    
    varID1 = netcdf.defVar( ncid1, ...
        info0.Variables(iv).Name, ...
        FUN_nc_defVar_datatypeconvert(info0.Variables(iv).Datatype), ...
        dimID1( VarDimIND_now ) );
    
    if compatibility_mode == 1
        % This is not supported by NETCDF older than version 4.
        % netcdf.defVarDeflate( ncid1, varID1, true, true, 0 );%compression level-1 basic
    else 
        netcdf.defVarDeflate( ncid1, varID1, true, true, 1 );%compression level-1 basic
    end
    
    % Add attribute ----------------------------
    for ii = 1:length(info0.Variables(iv).Attributes)
        if strcmp( info0.Variables(iv).Attributes(ii).Name, '_FillValue')
            % _FillValue can only be written by specific commends.
            netcdf.defVarFill( ncid1, varID1, false, info0.Variables(iv).Attributes(ii).Value ) 
        else
            netcdf.putAtt( ncid1, varID1, info0.Variables(iv).Attributes(ii).Name, info0.Variables(iv).Attributes(ii).Value);
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
            
            start( merge_dim ) = MV.ind_start(ii) - 1;
            count( merge_dim ) = MV.ind_end(ii) - MV.ind_start(ii) + 1;
            
            disp(['Loading from ' fullfile( input_dir, filepath_list{ii} ) ])
            ncid2 = netcdf.open( fullfile( input_dir, filepath_list{ii} ), 'NOWRITE' );
            
            varID2 = netcdf.inqVarID( ncid2, info0.Variables(iv).Name );
            var_value = netcdf.getVar( ncid2, varID2 );
            
            netcdf.putVar( ncid1, varID1, start, count, strid, var_value);
            netcdf.close( ncid2 );
            
        end
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
