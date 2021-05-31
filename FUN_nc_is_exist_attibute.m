function is_att_exist = FUN_nc_is_exist_attibute( filename, varname, attname )
% Determine whether an attribute exists in a given netcdf file
% For global attributes, varname is empty or 0
%
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

ncid = netcdf.open( filename );

if isempty(varname) || ( isnumeric(varname) && varname == 0 )
    varid = netcdf.getConstant('NC_GLOBAL');
else
    varid= netcdf.inqVarID( ncid, varname );
end

[~,~,~,att_num] = netcdf.inqVar( ncid, varid );

is_att_exist = false;
for ii = 1:att_num
    tem_att_name = netcdf.inqAttName( ncid, varid, ii );
    if strcmp( tem_att_name, attname )
        is_att_exist = true;
        break
    end
end


netcdf.close(ncid)