function [var, in_struct] = FUN_codetools_read_from_varargin( in_struct, var_name, default_val, is_rm_loadedd_param )
% [var, in_struct] = FUN_codetools_read_from_varargin( in_struct, var_name, default_val, is_rm_loadedd_param )

if ~exist('is_rm_loadedd_param','var') || isempty( is_rm_loadedd_param )
    is_rm_loadedd_param = true; % this is set to be compatible with some very old codes.
end

if isempty( in_struct )
    var = default_val;
    
else
    
    ind = find( strcmpi( in_struct, var_name ) );

    if isempty( ind )
        var = default_val;
    else
        var = in_struct{ind+1}; 
        if is_rm_loadedd_param
            in_struct(ind:ind+1) = [];
        end
    end
    
end