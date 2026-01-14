function FUN_nc_easywrite_write_var( filename, var_name, data, varargin )
% FUN_nc_easywrite_write_var( filename, var_name, data )
% FUN_nc_easywrite_write_var( filename, var_name, data, start, count, stride )
% Write data into an existing variable

% Known problem:
%     **This does not consider off_set and scale_factor**
%

% V1.03 by L. Chi: add support for auto cleanup of netcdf file handles
% V1.02 by L. Chi: clean useless codes
% V1.01 by L. Chi: fix a bug: an error occurred when varargin is not empty.
% V1.00 by L. Chi


%% ## 0. check ============================================================

% ####
if exist(filename,'file')
% ok
else
    error('The file does not exist!');
end

% ####
is_var_exist = FUN_nc_is_exist_variable( filename, var_name );
if is_var_exist
    %Pass
else
    error(['Variable ' var_name ' does not exist! Please define it before writing data!']);
end

%% ## 1. open the netcdf ==================================================

% open file
ncid = netcdf.open(filename,'NC_WRITE');
cleanup_ncid  = onCleanup(@() netcdf.close(ncid) ); % make sure the file will be closed

% get variable ID
varid = netcdf.inqVarID( ncid, var_name );


%% ## 2. write into netcdf ================================================
if nargin == 0
    % write the entire variable
    netcdf.putVar( ncid, varid, data );
else
    % write a subset of the variable
    netcdf.putVar( ncid, varid, varargin{:}, data );

end


%% ## 3. close the file ====================================================
%netcdf.close(ncid);
clear cleanup_ncid


return