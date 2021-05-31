function is_exist = FUN_nc_isexist_var( file_now, var_name )
% check whether a variable exists in the netcdf file.
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

info = ncinfo( file_now );
varname_list = {info.Variables.Name};

if any( strcmpi( varname_list, var_name ) )
    is_exist = true;
else
    is_exist = false; 
end