function FUN_nc_rename_var( filename, varname_old, varname_new )
% FUN_nc_rename_var( filename, varname_old, varname_new )
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

    ncid = netcdf.open(filename,'NC_WRITE');

% Put file in define mode.
    netcdf.reDef(ncid)

% Get ID of the variable
    varid = netcdf.inqVarID(ncid, varname_old );

% Rename the variable, using a capital letter to start the name.
    netcdf.renameVar(ncid, varid, varname_new )
    
% Exist define mode
    netcdf.endDef(ncid)
    
% Close the file
    netcdf.close(ncid);