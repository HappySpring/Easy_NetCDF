function out_bytes = FUN_nc_internal_bytes_per_value(in_type)
% How many bytes are occupied by one number/char in the given (in_type) format.
% this is used for estimating the chunk sizes

% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

if strcmp( in_type,'double' ) || strcmp( in_type, 'int64') ||  strcmp( in_type, 'uint64') || strcmp( in_type, 'NC_INT64') ||  strcmp( in_type, 'NC_UINT64')
    out_bytes = 8 ;
    
elseif strcmp( in_type,'single' ) || strcmp( in_type,'int32' ) || strcmp( in_type,'NC_FLOAT' ) || strcmp( in_type,'NC_INT' )
    out_bytes = 4;
    
elseif strcmp( in_type,'int16' ) || strcmp( in_type,'NC_SHORT' )
    out_bytes = 2;
    
elseif strcmp( in_type,'int8' ) || strcmp( in_type,'uint8' )  || strcmp( in_type,'NC_BYTE' ) || strcmp( in_type,'NC_UBYTE' )
    out_bytes = 1; 
    
elseif strcmp( in_type,'char' ) || strcmp( in_type,'NC_CHAR' )
    out_bytes = 1;
    
else
    warning('Unsupported data type')
    out_bytes = in_type;
end