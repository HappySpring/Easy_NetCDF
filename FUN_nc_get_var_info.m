function var_info = FUN_nc_get_var_info( filename, varname )
% var_info = FUN_nc_get_var_info( filename, varname )
%
% Extract the information of a specific variable based on `ncinfo`
%

% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

info = ncinfo( filename );

% find variable
ind = nan;
for ii = 1:length( info.Variables )
    if strcmp( info.Variables(ii).Name, varname )
        ind = ii; 
    end
end

if isnan(ind)
    error('Variable [%s] not found!', varname);
end

var_info = info.Variables(ind);
