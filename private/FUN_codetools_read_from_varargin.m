function [var, in_struct] = FUN_codetools_read_from_varargin( in_struct, var_name, default_val, is_rm_loadedd_param )
% [var, in_struct] = FUN_codetools_read_from_varargin( in_struct, var_name, default_val, is_rm_loadedd_param )

% V1.10 by L. Chi: If a property is givn mutiple times, the last one will
% be used.
% V1.00 by L. Chi

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
        if length(ind) > 1
            warning([ var_name ' appears more than once in the input parameters. The latest one will be used!'])
        end

        var = in_struct{ind(end)+1}; 
        if is_rm_loadedd_param
            in_struct([ind(:);ind(:)+1]) = [];
        end
    end
    
end