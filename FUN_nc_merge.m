function FUN_nc_merge( input_dir, filelist, output_fn, merge_dim_name, compatibility_mode, varargin )
% This will murge a list of netcdf files within a specific time-space
% range.
% -------------------------------------------------------------------------
% INPUT: 
%
%   input_dir: The folder in which all input netcdf given by "filelist" is
%              located. If it is not empty, the path given here will be used
%              as a prefix (by fullfile) to the paths given in filelist.
%   filelist : the list of files which will be merged.
%              It could be an array of cells, in which one cell contains one path,
%              or an array of strings in which one row contains one one path, 
%              or an array of strcutures like what returned by the built-in command "dir".
%
%   output_fn : Name of output netcdf file
%   merge_dim_name : name of the dimension in which all varialbes will be merged.
%        (Variables without the dimension "merge_dim_name" will be copied from the first file given in the variable filelist)
%
%   compatibility_mode
%               =1: old netcdf format will be used (classic mode).
%               =0: NETCDF4 will be used.
%
% Optional input parameter: FUN_nc_merge( ..., Name, value )
%
%   compression_level [optional, default value: 1] conpression level
%               range from 0 to 9, where 0 is no compression at all and 9 is the most compression.
%
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
%
% % or disable compression in the output file:
%   FUN_nc_merge(  input_dir, filelist, output_fn, 'time',  compatibility_mode, 'compression_level', 0);
% -------------------------------------------------------------------------
%
%

%                             **todo**
% [x] support large files (iterations)
% [-] support rare cases: file1 is fully covered by file2: partly finished.
% [ ] rename some variables and improve structure (not decided yet)
% [ ] check attributes before merging files. The unit of time may vary
%      between files
%
%
% 2024-01-15 v1.12 by L. Chi: fix a bug in merging files with variable type "NC_USHORT",
%                             which is not included in "FUN_nc_defVar_datatypeconvert"
%                             and ends up with an error. From this version, the
%                             function searches netcdf.getConstantNames
%                             to identify data type.
%                             
% 2022-10-29 V1.11 by L. Chi: support large file by parameter "N_record_per_IO" 
%                             This only works for N_record_per_IO > 0.
%
% 2022-12-14 V1.10 by L. Chi: Support merging files with overlapping periods
%                             ** Limitation**
%                             There must be a variable share the same name
%                                - as the dimension to be merged. 
%                             This is designed to merge model output after
%                             multiple restarts. It may not work for other
%                             situations. 
%                                - This is still under development. It works
%                             in normal situation, but may end up with
%                             errors in some special cases
% 2022-10-29 V1.04 by L. Chi: add an optional input parameter "compression_level"
% 2021-07-20 V1.03 by L. Chi: fix a bug: an error may appear if "input_dir" is not empty and filelist is generated by dir.
% 2021-07-12 V1.02 by L. Chi: support more ways to speicify input files to be merged. 
%                             "filelist" could be an array of cells, strings or structures now.
% xxxx-xx-xx V1.01 by L. Chi: fix a bug.
% 2017-09-25 V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

%% read optional input parameters

[compression_level, varargin]  = FUN_codetools_read_from_varargin( varargin, 'compression_level', 1, true);

[merge_dim_var_name, varargin] = FUN_codetools_read_from_varargin( varargin, 'merge_dim_var_name', merge_dim_name, true);

[is_merge_dim_in_time_unit, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_merge_dim_in_time_unit', false, true);

[is_overlap_allowed, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_overlap_allowed', false, true);

[N_record_per_IO, varargin] = FUN_codetools_read_from_varargin( varargin, 'N_record_per_IO', false, true);


if ~isempty( varargin )
    error('Unknown input parameter');
end

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
MV.ind_start = nan( length( filepath_list ), 1 );
MV.ind_end   = nan( length( filepath_list ), 1 );

if is_overlap_allowed
    
    for ii = 1:length( filepath_list )
        fprintf('Checking: %s\n', filepath_list{ii} );
        
        if is_merge_dim_in_time_unit
            MV.val{ii} = FUN_nc_get_time_in_matlab_format( filepath_list{ii}, merge_dim_var_name );  
        else
            MV.val{ii} = FUN_nc_varget( filepath_list{ii}, merge_dim_var_name );  
        end
        MV.val{ii} = reshape( MV.val{ii}, [], 1 );
        
        tem_N = length( MV.val{ii} );
        if ii == 1
            MV.ind_start(ii) = 1;
            MV.ind_end(ii)   = tem_N;
        else
            MV.ind_start(ii) = MV.ind_end(ii-1) + 1;
            MV.ind_end(ii)   = MV.ind_start(ii) + tem_N - 1;
        end
        
        MV.start(ii)   = 1 - 1; % this is for netcdf.getvar
        MV.count(ii)   = tem_N; % this is for netcdf.getvar
        MV.val_end(ii) = MV.val{ii}(end);
    end
    tem_N = []; % clear 
    
    
    % resort by the last value
    [~, file_sort_ind] = sort( MV.val_end );
    MV.val       = MV.val(file_sort_ind);
    MV.ind_start = MV.ind_start(file_sort_ind);   % index in the final merged variable (start, 1-based index)
    MV.ind_end   = MV.ind_end(file_sort_ind);     % index in the final merged variable (end, 1-based index)
    MV.start     = MV.start(file_sort_ind);       % "start" for reading netcdf file, 0-based index
    MV.count     = MV.count(file_sort_ind);       % "count" for reading netcdf file, 0-based index
    filepath_list= filepath_list(file_sort_ind);
    
    MV = rmfield( MV, 'val_end');
    
    for ii = 2:length( filepath_list )
        
        [cm, ia, ib ] = intersect( MV.val{ii-1}, MV.val{ii} );
        
        if isempty(cm)
           continue 
        end
        
        % the overlap 
        if all( diff(ia) == 1 ) && ia(end) == length( MV.val{ii-1} )
            
            sel_ia = ia(1)-1;
            sel_ib = ib(1);
            
            if sel_ib ~= 1
                % for now, sel_ib should be 1.
                error
            end
            
            if sel_ia == 0
                MV.val{ii-1} = [];
                MV.ind_start(ii-1)  = 0;
                MV.ind_end(ii-1)    = 0;
                MV.start(ii-1)      = 0;
                MV.count(ii-1)      = 0;
            else
                MV.val{ii-1}      = MV.val{ii-1}(1:sel_ia);
                MV.ind_start(ii-1)  = MV.ind_start(ii-1);
                MV.ind_end(ii-1)    = MV.ind_start(ii-1) +  length( MV.val{ii-1} ) - 1;
                MV.start(ii-1)    = 1 - 1 ; % 0-based index system
                MV.count(ii-1)    = sel_ia;
            end
            
            %MV.val{ii}   = MV.val{ii}(sel_ib:end); % this is useless now, but may be useful to set an overall limit for the merging dim.
            MV.ind_start(ii) = MV.ind_end(ii-1)+1;
            MV.ind_end(ii)   = MV.ind_start(ii) + length( MV.val{ii} ) - 1;
           
        end

    end
    
    if any( isnan( MV.start ) )
        error('Not supportted yet. This is still under constuction.')
    end
    
    MV.all = cell2mat( MV.val(:) );
else
    
    MV.all = [];
    
    for ii = 1:length( filepath_list )
       fprintf('Checking: %s\n', filepath_list{ii} );
       tem = FUN_nc_varget( filepath_list{ii}, merge_dim_var_name ); 

       MV.all = [ MV.all ; tem(:) ];

       if ii == 1
           MV.ind_start(ii) = 1;
           MV.ind_end(ii)   = length( tem );
       else
           MV.ind_start(ii) = MV.ind_end(ii-1)+1;
           MV.ind_end(ii)   = MV.ind_start(ii) + length( tem ) - 1;
       end
       
       %MV.start(ii-1)    = 1 - 1 ; % 0-based index system
       %MV.count(ii-1)    = sel_ia;
       
       clear tem
    end
       clear ii
end
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
sample_fn = filepath_list{1};

info0 = ncinfo(sample_fn);
ncid0 = netcdf.open( sample_fn, 'NOWRITE' );


% delete variables without any values -------------------------------------
delete_var = [];
for iv = 1:length( info0.Variables )
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
        
        %  to be cleaned ---
        % var_str_now = merge_dim_name; %  to be cleaned
        % varid_now = netcdf.inqVarID(ncid0, var_str_now ) ;
        % var_now = netcdf.getVar(ncid0, varid_now ) ;
        % ------------------
        
        info1.Dim(ii).Name        = merge_dim_name;
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
    
    % find variable type from ncinfo: this works for most frequently
    % adopted variables but may fail for some types of variables.
    [var_type, is_dv_success] = FUN_nc_defVar_datatypeconvert(info0.Variables(iv).Datatype);

    % searching variable tpye from netcdf.getConstantNames
    if ~is_dv_success
        
        disp('finding data type by searching netcdf.getConstantNames')

        tem_vid1 = netcdf.inqVarID( ncid0, info0.Variables(iv).Name );
        [~, tem_xtype, ~, ~] = netcdf.inqVar( ncid0, tem_vid1 );

        tem_nc_constant_names = netcdf.getConstantNames;
        for cc = 1:length( tem_nc_constant_names )
            tem_nc_constant_value{cc} = netcdf.getConstant(tem_nc_constant_names{cc});
        end

        tem_type_ind = find( cellfun( @(x)isequal(x, tem_xtype), tem_nc_constant_value ) );
        
        if isscalar( tem_type_ind )
            var_type = tem_nc_constant_names{tem_type_ind};
            disp(['datatype for var [' info0.Variables(iv).Name '] is [' var_type ']'])
        else
            error(['Cannot found the variable type ' tem_xtype ' from netcdf.getConstantNames!'])
        end

    end


    varID1 = netcdf.defVar( ncid1, ...
        info0.Variables(iv).Name, ...
        var_type, ...
        dimID1( VarDimIND_now ) );
    
    if compatibility_mode == 1
        % This is not supported by NETCDF older than version 4.
        % netcdf.defVarDeflate( ncid1, varID1, true, true, 0 );%compression level-1 basic
    else 
        netcdf.defVarDeflate( ncid1, varID1, true, true, compression_level );%compression level-1 basic
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
            
            % MV.count is not assigned when is_overlap_allowed is false.
            % This is a temporal fix before next major update of this
            % function.
            if is_overlap_allowed && MV.count(ii) == 0 
               continue 
            end
            
            start( merge_dim ) = MV.ind_start(ii) - 1;
            count( merge_dim ) = MV.ind_end(ii) - MV.ind_start(ii) + 1;
            
            disp(['Loading from ' filepath_list{ii}  ])
            ncid2 = netcdf.open( filepath_list{ii}, 'NOWRITE' );
            
            if is_overlap_allowed
                source_start = start;
                source_count = count;
                source_start( merge_dim ) = MV.start(ii);
                source_count( merge_dim ) = MV.count(ii);
                
                if N_record_per_IO == 0
                    varID2 = netcdf.inqVarID( ncid2, info0.Variables(iv).Name );
                    var_value = netcdf.getVar( ncid2, varID2, source_start, source_count );
                elseif N_record_per_IO > 0
                    
                    % initial variables for writting in blocks
                    tem_read_start  = source_start;
                    tem_read_count  = source_count;
                    tem_write_start = start;
                    tem_write_count = count;
                    
                    % first loop
                    tem_read_start_md = MV.start(ii);
                    tem_read_count_md = min(N_record_per_IO, MV.start(ii) + MV.count(ii) - tem_read_start_md );% count for the dim to be merged

                    tem_read_start( merge_dim ) = tem_read_start_md;
                    tem_read_count( merge_dim ) = tem_read_count_md;

                    %tem_write_start( merge_dim ) = tem_write_start( merge_dim );
                    tem_write_count( merge_dim ) = tem_read_count_md;
                    
                    while true
                        
                        % % for debug purposes only
                        %fprintf('tem_read_start_md, tem_read_count_md, tem_write_start(merge_dim), tem_write_count(merge_dim)\n' );
                        %fprintf('%f, %f, %f, %f\n', tem_read_start_md, tem_read_count_md, tem_write_start(merge_dim), tem_write_count(merge_dim) );
                        
                        fprintf('  Index %i - %i from %s to %i - %i in output\n', tem_read_start_md+1, tem_read_start_md+tem_read_count_md, filepath_list{ii}, tem_write_start( merge_dim )+1, tem_write_start( merge_dim )+tem_read_count_md);
                        
                        varID2    = netcdf.inqVarID( ncid2, info0.Variables(iv).Name );
                        var_value = netcdf.getVar( ncid2, varID2, tem_read_start, tem_read_count );
                        
                        netcdf.putVar( ncid1, varID1, tem_write_start, tem_write_count, strid, var_value);
                        
                        % calculate indexes for next round
                        tem_read_start_md = tem_read_start_md + tem_read_count_md;
                        tem_read_count_md = min(N_record_per_IO, MV.start(ii) + MV.count(ii) - tem_read_start_md );% count for the dim to be merged

                        tem_read_start( merge_dim ) = tem_read_start_md;
                        tem_read_count( merge_dim ) = tem_read_count_md;

                        tem_write_start( merge_dim ) = tem_write_start( merge_dim ) + tem_write_count( merge_dim );
                        tem_write_count( merge_dim ) = tem_read_count_md;
                        
                        if tem_read_count_md <= 0
                            % for debug purpose only
                            % fprintf('---------------');
                            % fprintf('tem_read_start_md, tem_read_count_md, tem_write_start(merge_dim), tem_write_count(merge_dim)\n' );
                            % fprintf('%f, %f, %f, %f\n', tem_read_start_md, tem_read_count_md, tem_write_start(merge_dim), tem_write_count(merge_dim) );
                            break
                        end
                        
                    end
                else
                    error('N_record_per_IO must be 0 or positive!')
                end


            else
                varID2 = netcdf.inqVarID( ncid2, info0.Variables(iv).Name );
                var_value = netcdf.getVar( ncid2, varID2 );

                netcdf.putVar( ncid1, varID1, start, count, strid, var_value);

            end
            netcdf.close( ncid2 );
            
        end
    else
        disp(['Loading from the sample file: ' sample_fn])
        %ncid0 = netcdf.open( sample_fn, 'NOWRITE' );
        varID0 = netcdf.inqVarID( ncid0, info0.Variables(iv).Name );
        var_value = netcdf.getVar( ncid0, varID0 );
        netcdf.putVar( ncid1, varID1, var_value);
        %netcdf.close( ncid0 );
    end
    
    clear VarDim_now VarDimIND_now varID1 varID0 var_value
end

netcdf.close(ncid0);
netcdf.close(ncid1);
