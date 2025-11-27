function FUN_nc_copy_with_limit( filename0, filename1, dim_limit_name, dim_limit_val, is_compressed_output, varargin )
% This will copy the original netcdf file within a specific time-space range.
%
% For complex cases, "FUN_nc_OpenDAP_with_limit" is recommended. 
% -------------------------------------------------------------------------
% INPUT: 
%   filename0 [char] : source of the netcdf file
%   filename1 [char]: Name of output netcdf file
%   dim_limit_name [cell]: which axises you want to set the limit
%   dim_limit_val  [cell]: the limit of each axises
%   is_compressed_output : True: variables in the output file will be compressed, 
%        (The nondemensional variables will not be compressed even if it is set to true);
%    
%   More optional parameters can be found in optional parameters section below.
%
% -------------------------------------------------------------------------
%  Output: None
%
% Notice: To recongnize the axis correctly, there must be one variable
% named as by each axis! For example, if a dimension is named "x", then
% there must be a variable named "x" in the netcdf file.
%
% -------------------------------------------------------------------------
% Example: 
%     dim_limit_name = {'lon','lat'};
%     dim_limit_val = {[90 180],[0 50]};
% 
%     filename0 = 'sss_binned_L3_MON_SCI_V3.0_CAP_2013.nc';
%     filename1 = ['part' datestr(now,'HH_MM_SS') '.nc'];
%
%     FUN_nc_copy_with_limit( filename0, filename1, dim_limit_name, dim_limit_val  )
% -------------------------------------------------------------------------
%
% v1.23 by L. Chi: support copy variables by indexes at specific dimensions, see "dim_varname" below
%
% v1.22 by L. Chi: support rare data types
% V1.21 by L. Chi:
%       It is possible to specify a dimension whose chunksize will be
%       forced to 1. see optional paramter "chunksize1_dim_name".
%
% V1.20 by L. Chi:
%       Estimate the chunksize automatically.
%       (Please not that if the chunksize in the sources (filename0) will not be used in the destination (filename1))
%           This may be included in a future version.
% V1.10 by L. Chi: 
%       Support nondemensional variables.
% V1.00
% By L.Chi V1.00 2016-10-24 (L.Chi.Ocean@outlook.com)
% -------------------------------------------------------------------------

% ---- default values --------------------------------------------------
if ~exist('is_compressed_output','var') || isempty( is_compressed_output )
    is_compressed_output = true;
end


% ---- optional parameters --------------------------------------------------

%      dim_varname   [cell, optional]: name of the variable defining the axis at each dimension.
%           + by default, each axis is defined by a variable sharing the same name as the dimension. 
%           + "dim_varname{1} = nan" will force the dimension assicated with 
%             an vector defined as 1, 2, 3, ... Nx, where Nx is the length
%             of the dimension, ingnoring the variable shares the same name
%             with this dimension (if it exists)
%           + dim_varname can also caontain arrays to set the longitude,
%           latitude, time, etc, manually instead of reading them from the
%           netcdf file. E.g., dim_varname = { [-82:1/4:-55], [26:1/4:45]};
[dim_varname, varargin] = FUN_codetools_read_from_varargin( varargin, 'dim_varname', dim_limit_name );


% is_auto_chunksize: replace the default setting for chunksize by a customed equation in Easy_NetCDF
[is_auto_chunksize, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_auto_chunksize', false );

[chunksize1_dim_name, varargin] = FUN_codetools_read_from_varargin( varargin, 'chunksize1_dim_name', [] );

% is_add_preset_att: add some preset attributes in the output files, like "Copy Source", "Copy Date", "Copy Range". 
[is_add_preset_att, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_add_preset_att', true );


% variables to be included. var_included is empty => including all
% variables
[var_included, varargin] = FUN_codetools_read_from_varargin( varargin, 'var_included', {} );

% variables to be exclueded
[var_excluded, varargin] = FUN_codetools_read_from_varargin( varargin, 'var_excluded', {} );

if length( varargin ) > 0
    error('Unkown parameters found!')
end

%% Load the original data

info0 = ncinfo(filename0);
ncid0 = netcdf.open( filename0, 'NOWRITE' );

%% prepare dimensions

for ii = 1:length(info0.Dimensions)
    
    % decide wehter this dim should be loaded partly.
    dim_cmp_loc = strcmp( info0.Dimensions(ii).Name, dim_limit_name );
    
    if any( dim_cmp_loc )
        % load by part

        % interface
        tem = 1:length(dim_limit_name);
        ij  = tem(dim_cmp_loc);% for dim_limit_name & dim_limit_val
        
        dim_name_now    = dim_limit_name{ij};
        dim_varname_now = dim_varname{ij};
        
        % determine the dimension variable 
        if ischar(dim_varname_now) || isstring(dim_varname_now)
            varid_now = netcdf.inqVarID(ncid0, dim_varname_now ) ;
            var_now = netcdf.getVar(ncid0, varid_now ) ;

        elseif isnan(dim_varname_now)
            dimid_now = netcdf.inqDimID(ncid0, dim_name_now ) ;
            [~, dimlen] = netcdf.inqDim(ncid0, dimid_now);
            var_now   = 1:dimlen;
           
        elseif isnumeric(dim_varname_now)
            var_now = dim_varname_now;

        else
            error('dim_varname can only be char, nan, or numeric array!')
        end

        
        [start, count, ind] = FUN_nc_varget_sub_genStartCount( var_now, dim_limit_val{ij} );
        
        info1.Dim(ii).Name        = dim_name_now;
        info1.Dim(ii).Length      = count;
        info1.Dim(ii).MatInd      = ii;  % Location of this variable in the Dim Matrix
        %info1.Dim(ii).originalVal = var_now;
        info1.Dim(ii).start       = start;
        info1.Dim(ii).count       = count;
        info1.Dim(ii).ind         = ind;
        info1.Dim(ii).is_seleted  = true;
    else
        
        info1.Dim(ii).Name        = info0.Dimensions(ii).Name;
        info1.Dim(ii).Length      = info0.Dimensions(ii).Length;
        info1.Dim(ii).MatInd      = ii;
        %info1.Dim(ii).originalVal = [];
        info1.Dim(ii).start       = 0;
        info1.Dim(ii).count       = info1.Dim(ii).Length;
        info1.Dim(ii).ind         = 1:info1.Dim(ii).Length ;
        info1.Dim(ii).is_seleted  = false;
    end
end

%% open new file and write dimensions
ncid1 = netcdf.create(filename1,'NETCDF4');

for ii = 1:length( info1.Dim )
    dimID1(ii) = netcdf.defDim(ncid1, info1.Dim(ii).Name , info1.Dim(ii).Length );
end

% set global ATT
for ii = 1:length(info0.Attributes)
    netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), info0.Attributes(ii).Name, info0.Attributes(ii).Value);
end

if is_add_preset_att
    netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), 'Copy Source', filename0 );
    netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), 'Copy Date', datestr(now) );
    for ii = 1:length( dim_limit_name )
        netcdf.putAtt( ncid1, netcdf.getConstant('NC_GLOBAL'), ['Copy Range-' num2str(ii)], [dim_limit_name{ii} ' ' num2str( dim_limit_val{ii} )] );
    end
end
%% load/write variable
for iv = 1:length(info0.Variables)
    
    if isempty( var_included ) || any(strcmpi( var_included, info0.Variables(iv).Name ) )
        
    else
        fprintf(' var %s is skipped since it is not listed in "var_included" \n', info0.Variables(iv).Name)
        continue
    end

    if ~isempty( var_excluded ) && any(strcmpi( var_excluded, info0.Variables(iv).Name ) )
        fprintf(' var %s is skipped since it is listed in "var_excluded" \n', info0.Variables(iv).Name)
        continue
    end



   % Prepare for varialbes
    VarDim_now = info0.Variables(iv).Dimensions;
    if isempty( VarDim_now )
        % A variable can be defined without any dimensional info.
        is_var_with_dim = false;
        VarDimIND_now = [];
    else
        is_var_with_dim = true;
    end
    
    for id = 1:length( VarDim_now )
        VarDimIND_now(id) = FUN_struct_value_for_specific_name( info1.Dim, 'Name', VarDim_now(id).Name, 'MatInd' );
    end
    
    start = [];
    count = [];
    strid = [];
    for id = 1:length( VarDimIND_now )
        start = [start info1.Dim( VarDimIND_now(id) ).start];
        count = [count info1.Dim( VarDimIND_now(id) ).count];
        strid = [strid 1];%stride
    end
    
    % Define Variable -----------------------------------------------------
    if iv > 1
        netcdf.reDef(ncid1)
    end
    
    [var_type, is_dv_success] = FUN_nc_defVar_datatypeconvert(info0.Variables(iv).Datatype);

    % searching variable tpye from netcdf.getConstantNames
    if ~is_dv_success
        disp('finding data type by searching netcdf.getConstantNames')
        var_type = FUN_nc_get_var_type_by_name( ncid0, info0.Variables(iv).Name );
        disp(['datatype for var [' info0.Variables(iv).Name '] is [' var_type ']']);
    end
    


    varID1 = netcdf.defVar( ncid1, ...
        info0.Variables(iv).Name, ...
        var_type, ...
        dimID1( VarDimIND_now ) );
    
    % set compression level
    if is_compressed_output && is_var_with_dim
        %It is not necessary to compress a variable without dimensions.
        netcdf.defVarDeflate( ncid1, varID1, true, true, 1);%compression level-1 basic
    end
    
    % set chunk size (not necessary for non-dimensional var)
    if ~isempty(chunksize1_dim_name)
            
        ind_dim_chunk1 = find(strcmpi({VarDim_now.Name},chunksize1_dim_name));
        
        if ~isempty( ind_dim_chunk1 )
            
            if length( VarDim_now ) == 1
                % skip the variable with only one dimension, which is chunksize1_dim_name.
            else
                tmp_chunksize  = count;
                tmp_chunksize(ind_dim_chunk1) = 1;
                netcdf.defVarChunking( ncid1, varID1, 'CHUNKED', tmp_chunksize );
            end
        end

    elseif is_auto_chunksize && is_var_with_dim

        tmp_bytes_per_val = FUN_nc_internal_bytes_per_value( info0.Variables(iv).Datatype );
        tmp_chunksize = FUN_nc_internal_calc_chunk( count, tmp_bytes_per_val );
        netcdf.defVarChunking( ncid1, varID1, 'CHUNKED', tmp_chunksize );
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

    netcdf.endDef(ncid1)

    % write varialbe ------------------------------------------------------
    varID0 = netcdf.inqVarID( ncid0, info0.Variables(iv).Name );
    if is_var_with_dim
        var_value = netcdf.getVar( ncid0, varID0, start, count, strid );
    else
        var_value = netcdf.getVar( ncid0, varID0 );
    end
    
    netcdf.putVar( ncid1, varID1, var_value);
    netcdf.sync( ncid1 );
    
    clear VarDim_now VarDimIND_now varID1 varID0 var_value
end

netcdf.close(ncid0);
netcdf.close(ncid1);


%% test =========================================================
% % % clear all
% % % close all
% % % clc
% % % 
% % % %%
% % % dim_limit_name = {'lon','lat'};
% % % dim_limit_val = {[ -90 -50 ]+360, [ 20 70 ]};
% % % filename0 = 'EN.4.1.1.f.analysis.g10.201412.nc';
% % % filename1 = 'EN4201412_seleted6.nc';
% % % FUN_nc_copy_with_limit( filename0, filename1, dim_limit_name, dim_limit_val  );
% % % 
% % % 
% % % %%
% % % lon1 = FUN_nc_varget( filename1,'lon');
% % % lat1 = FUN_nc_varget( filename1,'lat');
% % % depth1 = FUN_nc_varget( filename1,'depth');
% % % t1 = FUN_nc_varget_enhanced( filename1,'temperature');
% % % 
% % % %%
% % % figure('position',[100    86   523   862])
% % % subplot(3,1,1)
% % % q_pcolor(lon1,lat1, squeeze( t1(:,:,1) )');
% % % title('t1')
% % % 
% % % [ out_dim, t2 ] = FUN_NC_varget_enhanced_region_2( filename0, 'temperature', {'lon','lat','depth','time'}, {[ -90 -50 ]+360, [ 20 70 ],[-inf inf],[-inf inf]  });
% % % 
% % % subplot(3,1,2)
% % % q_pcolor(lon1,lat1, squeeze( t2(:,:,1) )');
% % % title('t2')
% % % 
% % % subplot(3,1,3)
% % % q_pcolor(lon1,lat1, squeeze( t1(:,:,1) - t2(:,:,1) )');
% % % title('t2')
