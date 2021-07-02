function is_var_dimless = FUN_nc_is_variable_dimensionless( filename, varname )
% is_var_dimless = FUN_nc_is_variable_dimensionless( filename, varname )
% Determine whether a variable exists in a given nc file.
%
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)



ncid = netcdf.open( filename, 'NOWRITE' );

varid = netcdf.inqVarID( ncid, varname );
[~,~,dimids,~] = netcdf.inqVar(ncid,varid);

is_var_dimless = isempty(dimids);

%% close file
netcdf.close( ncid );