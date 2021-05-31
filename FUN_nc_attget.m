function att_value = FUN_nc_attget( filename, varname, attname )
% function att_value = FUN_nc_attget( filename, varname, attname )
%
% read attributes from netcdf files
%
% -------------------------------------------------------------------------
% INPUT:
%      filename: name of the NetCDF file
%      varname : name of the variable
%                For global attributes, the varname should be empty ([]).
%      attname : name of the attribute. 
%
% OUTPUT:
%      att_value: value of the attribute 
% -------------------------------------------------------------------------
%
% V1.1 By L.Chi., 2016-07-25
%      Add support for loading global attributes
% V1.0 initial version by L. Chi (L.Chi.Ocean@outlook.com)
% -------------------------------------------------------------------------

ncid = netcdf.open( filename, 'NOWRITE');

if isempty( varname ) % empty varname -> global attributes
    varid = netcdf.getConstant('NC_GLOBAL');
else
    varid = netcdf.inqVarID( ncid, varname);
end

att_value = netcdf.getAtt(ncid,varid,attname);
netcdf.close(ncid);


return