function data = FUN_nc_varget(filename,varname)
% data = self_nc_varget(filename,varname)
% load a variable from netcdf file as is.
% This function will keep the original format of the variable 
% The offset and factor correction will not be applied.
% The fillvalues will be not replaced by NaNs. 

% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

ncid = netcdf.open(filename,'NOWRITE');
varid = netcdf.inqVarID(ncid,varname);
data = netcdf.getVar(ncid,varid);
netcdf.close(ncid)
