function is_dim_exist = FUN_nc_is_exist_dimension( fn, inq_dim_name, varname )
% is_dim_exist = FUN_nc_is_exist_dimension( filename, inq_dim_name, varname )
% Determine whether a specific dimension exists in a given nc file or assoicated to a variable.
% 
% INPUT: 
%       fn:  path to the netcdf file 
%       inq_dim_name: name of the dimensional to be checked.
%       varname (optional): Variable name. 
%               + when the varname is empty, this function checks whether a
%                 dimension exists in the netcdf spcified by fn
%               + when the varname is not empty, this function checks
%                 whether the dimension "inq_dim_name" is associated to
%                 this variable. 
% OUTPUT:
%      is_dim_exist (logical): whether the dimension exists. 
%
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%% Set default values
if ~exist('varname','var')
    varname = [];
end

%% list all related dimensions
ncid = netcdf.open( fn, 'NOWRITE' );

if ~isempty( varname )
    varid = netcdf.inqVarID( ncid, varname );
    [~,~,dimids,~] = netcdf.inqVar(ncid,varid); 
else
    dimids = netcdf.inqDimIDs( ncid );
end

%% check the dimension
is_dim_exist = false;
for ii = 1:length( dimids )
    [dimname, ~] = netcdf.inqDim( ncid, dimids(ii) );
    
    if strcmpi( dimname, inq_dim_name )
        is_dim_exist = true;
    end
end

%% close file
netcdf.close( ncid );