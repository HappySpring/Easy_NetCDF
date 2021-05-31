function FUN_nc_easywrite_add_var( filename, var_dim_str, var_kind, var_name, data, is_compression, varargin )
% FUN_nc_easywrite_add_var( filename, var_dim_str, var_kind, var_name, data, is_compression )
% FUN_nc_easywrite_add_var( filename, var_dim_str, var_kind, var_name, data, is_compression, 'is_auto_chunksize', true)
%
% Add a new variable to an existing netcdf file or replace an existing
% variable. Please note that this could not change the size of an existing
% variable.
% *The variable must fit existing dimensions
%
% -------------------------------------------------------------------------
% INPUT: 
% filename [string]: name of the netcdf file
% var_dim_str [cell]: a cell array contains name of corresponding
%                       dimensions in the netcdf file, e.g.,
%                       {'lon','lat','depth','time'}.
% var_kind [string]: type of the variable, e.g., 'double'
% var_name [string]: name of the variable, e.g., 'SST'
% data [N-D array]: 
% is_compression: true: compress the variable (true) or not (false).
% -------------------------------------------------------------------------
% optional paramters:
% + 'is_auto_chunksize' (default: false) 
%      This only matters if is_compression == true.
%      true: replace the Chunk size by results returned from
%        "FUN_nc_internal_calc_chunk". 
%      false: use default chunk size.
% -------------------------------------------------------------------------
% OUTPUT:
%   N/A
% -------------------------------------------------------------------------
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

%% debug
% filename = 'expt_53.X_1994_water_temp_bottom.nc';
% var_dim_str = {'time'};
% var_name = 'time';
% var_kind = 'double';
% data = FUN_nc_varget('expt_53.X_1994_time.nc','time');

%% 0. set default values and check the existing file

[is_auto_chunksize, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_auto_chunksize', false, true );
[nc_FillValue, varargin] = FUN_codetools_read_from_varargin( varargin, '_FillValue', [], true );

if ~isempty( varargin )
    error('Unkown parameters found!')
end


if exist(filename,'file')
% ok
else
    error('The file does not exist!');
end

if ~exist('is_compression') || isempty( is_compression );
    is_compression = false;
end


infos = ncinfo( filename );
existVarList = {infos.Variables.Name};
if any( strcmp( existVarList, var_name ) )
    disp('The variable already exists, it will be overwritten!')
    var_is_exist = true;
else
    var_is_exist = false;
    % ok
end

%% 1. open the netcdf
% cid = netcdf.create(filename, mode)
% mode
% 'NC_NOCLOBBER'         Prevent overwriting of existing file with the same name.
% 'NC_SHARE'             Allow synchronous file updates.
% 'NC_64BIT_OFFSET'      Allow easier creation of files and variables which are larger than two gigabytes.

ncid = netcdf.open(filename,'NC_WRITE');

netcdf.reDef( ncid );

%% 2. find Dimensions
% dimid = netcdf.defDim(ncid,dimname,dimlen)

for idim = 1:length( var_dim_str )
    var_dim_id(idim) = netcdf.inqDimID( ncid, var_dim_str{idim} );
    [~, var_dim_len(idim)] = netcdf.inqDim( ncid, var_dim_id(idim) );
end

%% 3. Define the varialbe
% varid = netcdf.defVar(ncid,varname,xtype,dimids)
    if var_is_exist
        varid = netcdf.inqVarID( ncid, var_name ); 
    else
        varid = netcdf.defVar( ncid, var_name, var_kind,  var_dim_id  );
    end
    
    if ~isempty( nc_FillValue )
       netcdf.defVarFill( ncid, varid, false, nc_FillValue ); 
    end
    
% ### compression ---------------------------------------------------------
% netcdf.defVarDeflate(ncid,varid,shuffle,deflate,deflateLevel)
%
% Descriptionnetcdf.defVarDeflate(ncid,varid,shuffle,deflate,deflateLevel) sets the compression parameters for the NetCDF variable specified by varid in the location specified by ncid.
% shuffle:
% Boolean value. To turn on the shuffle filter, set this argument to true. The shuffle filter can assist with the compression of integer data by changing the byte order in the data stream.
% deflate:
% Boolean value. To turn on compression, set this argument to true and set the deflateLevelargument to the desired compression level.
% deflateLevel:
% Numeric value between 0 and 9 specifying the amount of compression, where 0 is no compression and 9 is the most compression.
if is_compression
    netcdf.defVarDeflate(ncid,varid,true,true,1);
end

% ### set chunk size ------------------------------------------------------
if is_auto_chunksize
    
    try
        data_type = FUN_nc_defVar_datatypeconvert( var_kind );
    catch
        warning('Unknown datatype, DOUBLE will be used by dafault');
        data_type = 'double';
    end
    
    tmp_bytes_per_val = FUN_nc_internal_bytes_per_value( data_type );
    tmp_chunksize = FUN_nc_internal_calc_chunk( var_dim_len, tmp_bytes_per_val );
    netcdf.defVarChunking( ncid, varid, 'CHUNKED', tmp_chunksize );
end

%% 4 exit definition mode
netcdf.endDef(ncid)


%% 5 write into netcdf
% netcdf.putVar(ncid,varid,data)
% netcdf.putVar(ncid,varid,start,data)
% netcdf.putVar(ncid,varid,start,count,data)
% netcdf.putVar(ncid,varid,start,count,stride,data)
netcdf.putVar(ncid,varid,data)


%% 6 close file
netcdf.close(ncid);


return