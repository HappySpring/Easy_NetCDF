function is_var_exist = FUN_nc_is_exist_variable( filename, varname )
% Determine whether a variable exists in a given nc file.
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

nc = ncinfo( filename );
nc_variable_list = {nc.Variables.Name};

is_var_exist = any( strcmp( nc_variable_list, varname ) );