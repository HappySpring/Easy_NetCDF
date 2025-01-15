function var_type = FUN_nc_get_var_type_by_name( ncid0, var_name )
% var_type = FUN_nc_get_var_type_by_name( ncid0, var_name )
% 
% find variable type according to varname
%
%

% V1.00 by L. Chi (2025-01-15)


% find type identifier 
tem_vid1 = netcdf.inqVarID( ncid0, var_name );
[~, tem_xtype, ~, ~] = netcdf.inqVar( ncid0, tem_vid1 );


% list all netcdf constants
tem_nc_constant_names = netcdf.getConstantNames;

for cc = 1:length( tem_nc_constant_names )
    tem_nc_constant_value{cc} = netcdf.getConstant(tem_nc_constant_names{cc});
end


% find data type from netcdf constants and type identifier
tem_type_ind = find( cellfun( @(x)isequal(x, tem_xtype), tem_nc_constant_value ) );

% final check
if isscalar( tem_type_ind )
    var_type = tem_nc_constant_names{tem_type_ind};
    %disp(['datatype for var [' var_name '] is [' var_type ']'])
else
    error(['Cannot found the variable type ' tem_xtype ' from netcdf.getConstantNames!'])
end