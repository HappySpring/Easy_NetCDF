function out = FUN_nc_attget( filename, varname, attname )
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
%                if attname = [], return all attributes associated with
%                this variable.
%
% OUTPUT:
%      out: value of the attribute 
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


if ~isempty( attname )
    % read the specific att
    out = netcdf.getAtt(ncid,varid,attname);
    
else
    % read all attributes from a variable
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid,varid);
    
    
    for ii = 1 : natts
        
        att_name = netcdf.inqAttName( ncid, varid, ii-1 );
        att_val  = netcdf.getAtt( ncid, varid, att_name );
        
        if strcmp( att_name(1), '_' )
            att_name = [att_name(2:end) , '_' ]; 
        end
        
        out.(att_name) = att_val;
        
        att_name = [];
        att_val  = [];
    end
    
end

netcdf.close(ncid);


return