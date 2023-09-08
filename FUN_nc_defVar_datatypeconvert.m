function out_type = FUN_nc_defVar_datatypeconvert(in_type)
% out_type = FUN_nc_defVar_datatypeconvert(in_type)
%   convert name of variable types in matlab to that in netcdf.
% -------------------------------------------------------------------------
% INPUT:
%   in_type: name of variable types in matlab, like single, double, etc.
% -------------------------------------------------------------------------
% OUTPUT:
%   out_type: name of variable types for writting netcdf
% -------------------------------------------------------------------------
% REF:
%   Details see here: http://www.mathworks.com/help/matlab/ref/netcdf.defvar.html
%   More details see here: https://www.mathworks.com/help/matlab/ref/nccreate.html
%
% V1.01 by L. Chi: remove warning messages if the built-in variable type
% (like NC_FLOAT) is used.
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

matlab_built_in_nc_types = {'NC_DOUBLE', 'NC_FLOAT', 'NC_INT64', 'NC_UINT64', 'NC_INT', 'NC_SHORT', 'NC_USHORT', 'NC_BYTE', 'NC_UBYTE', 'NC_CHAR', 'NC_STRING'};

if strcmp( in_type,'double' )
    out_type = 'double';
    
elseif strcmp( in_type,'single' )
    out_type = 'NC_FLOAT';
    
elseif strcmp( in_type, 'int64')
    out_type = 'NC_INT64';
    
elseif strcmp( in_type, 'uint64')
    out_type = 'NC_UINT64';
    
elseif strcmp( in_type,'int32' )
    out_type = 'NC_INT';
    
elseif strcmp( in_type,'int16' )
    out_type = 'NC_SHORT';
    
elseif strcmp( in_type,'int8' )
    out_type = 'NC_BYTE';
    
elseif strcmp( in_type,'uint8' )
    out_type = 'NC_UBYTE';
    
elseif strcmp( in_type,'char' )
    out_type = 'NC_CHAR';
    
elseif ismember( upper(in_type), upper(matlab_built_in_nc_types) )
    % built-in nc types will be returned as is. 
    out_type = in_type;

else
    warning('Unsupported data type')
    out_type = in_type;
end