function dim_length = FUN_nc_get_dim_length( filename, dim_name_str )
% dim_length = FUN_nc_get_dim_length( filename, dim_name_str )
%
% find the length of the required dimension

% V1.01 by L. Chi: add "netcdf.close" at the end of the function
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

ncid = netcdf.open( filename, 'NOWRITE');

dimid = netcdf.inqDimID( ncid, dim_name_str );

[~, dim_length] = netcdf.inqDim( ncid, dimid );

netcdf.close(ncid)