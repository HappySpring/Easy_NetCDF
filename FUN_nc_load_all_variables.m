function data_out = FUN_nc_load_all_variables( fn, varargin )
% data_out = FUN_nc_load_all_variables( fn, varargin )
% 
% INPUTS
%    fn:  name of the netcdf file to be loaded
%
%    'time_var_name': name of the variable for time. (empty by default)
%                     The value of the corresponding variable will be
%                     converted to matlab time unit (days since 0000-01-00)
%                     used by datenum
% OUTPUT
%    data_out: it is a structure containing all variables like this:
%
%              struct with fields:
%            
%                 lat: [94×1 double]
%                 lon: [192×1 double]
%                time: 1569072
%                land: [192×94 double]

% =========================================================================
% v1.00 by L. Chi (L.Chi.Ocean@outlook.com)

% ----------------------------------------------------------------------
% parameters
% ----------------------------------------------------------------------

[time_var_name, varargin] = FUN_codetools_read_from_varargin( varargin, 'time_var_name', [], true ); % do not print skipped files on the screen.

if ~isempty( varargin )
    error('unknown input parameters found!')
end


% ----------------------------------------------------------------------
% get file info & start loop
% ----------------------------------------------------------------------
finfo = ncinfo( fn );


for iv = 1:length( finfo.Variables )
    
    % vn_nc: name of the variable in netcdf files
    % vn_out: name of the varialbe in matlab. It is usually same as vn_nc.
    %         A "var_" will be added to the beginning of the variable in
    %         case it starts from a character other than a-z or A-Z to
    %         satisfy the requirement of matlab
    %
    vn_nc  = finfo.Variables(iv).Name;
    
% ----------------------------------------------------------------------
% get variable name
% ----------------------------------------------------------------------
    vn1= vn_nc(1);

    if ischar(vn1) && ( (vn1 >= 'a' && vn1 <= 'z') || ...
                        (vn1 >= 'A' && vn1 <= 'Z') )
        vn_out = vn_nc;
    else
        vn_out = ['v_' vn_nc];
        fprintf(' Variable [%s] is renamed to [%s] \n', vn_nc, vn_out);
    end

    % data_out

% ----------------------------------------------------------------------
% load variables
% ----------------------------------------------------------------------


    if ~isempty(time_var_name) && strcmpi( time_var_name, vn_nc )
        
        [tmp, ~] = FUN_nc_varget_enhanced_region_2( fn, vn_nc, [], [], time_var_name, [] );
        data_out.(vn_out) = tmp.(time_var_name);

    else
        data_out.(vn_out) = FUN_nc_varget_enhanced( fn, vn_nc );

    end



end
