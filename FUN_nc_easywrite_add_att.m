function FUN_nc_easywrite_add_att( filename, var_name, att_name, att_value )
% FUN_nc_easywrite_add_att( filename, var_name, att_name, att_value )
% Add an attribute to an existing variable
% -------------------------------------------------------------------------
% INPUT
%   filename: Output filename.
%   var_name: for which variable the attribute will be added to. 
%             *The attribute will be added to NC_global if var_name is empty. 
%   att_name: name of the attribute.
%   att_value: value of the attribute.
% -------------------------------------------------------------------------
% OUTPUT
%   N/A
% -------------------------------------------------------------------------
% v1.11 by L. Chi, auto cleanup of netcdf file handles
% V1.10 By L. Chi support global att
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com).

%% 0. 
if exist(filename,'file')
% ok
else
    error('The file does not exist!');
end

%% 1. open the netcdf
% cid = netcdf.create(filename, mode)
% 'NC_NOCLOBBER'         Prevent overwriting of existing file with the same name.
% 'NC_SHARE'             Allow synchronous file updates.
% 'NC_64BIT_OFFSET'      Allow easier creation of files and variables which are larger than two gigabytes.

ncid = netcdf.open(filename,'WRITE');
cleanup_ncid = onCleanup(@() netcdf.close(ncid) ); % make sure the file will be closed

netcdf.reDef( ncid );

%% 2. find the var
    if isempty( var_name )
        varid = netcdf.getConstant('NC_GLOBAL');
    else
        varid = netcdf.inqVarID( ncid, var_name );
    end

%% 3. Creat att
% varid = netcdf.defVar(ncid,varname,xtype,dimids)
    netcdf.putAtt( ncid, varid, att_name, att_value);

%% 4 close att
netcdf.endDef(ncid);
%netcdf.close(ncid);
clear cleanup_ncid

return