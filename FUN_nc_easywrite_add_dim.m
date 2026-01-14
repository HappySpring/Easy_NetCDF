function dimID = FUN_nc_easywrite_add_dim(filename, dim_name, dim_length, varargin )
% FUN_nc_easywrite_add_att
%
% 2026-01-14 v1.01 By L. Chi: add support for auto cleanup of netcdf file handles
% 2023-07-24 V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%% pre-process input data
if isinf( dim_length ) 
    dim_length = netcdf.getConstant('NC_UNLIMITED');
end

%% Define Dimensions

ncid = netcdf.open(filename,'WRITE');
cleanup_ncid = onCleanup(@() netcdf.close(ncid) ); % make sure the file will be closed

netcdf.reDef(ncid);
dimID = netcdf.defDim(ncid, dim_name, dim_length );

%% exit definition mode
netcdf.endDef(ncid)


%% close file
% netcdf.close(ncid);
clear cleanup_ncid


return