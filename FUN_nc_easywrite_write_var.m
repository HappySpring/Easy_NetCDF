function FUN_nc_easywrite_write_var( filename, var_name, data, varargin )
% FUN_nc_easywrite_write_var( filename, var_name, data )
% FUN_nc_easywrite_write_var( filename, var_name, data, start, count, stride )
% Write data into an existing variable

% V1.00 by L. Chi


%% ## 0.

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
    error(['Variable ' var_name ' does not exist']);
end

%% ## 1. open the netcdf
% cid = netcdf.create(filename, mode)
% mode£º
% 'NC_NOCLOBBER'£º           Prevent overwriting of existing file with the same name.
% 'NC_SHARE'£º               Allow synchronous file updates.
% 'NC_64BIT_OFFSET'£º        Allow easier creation of files and variables which are larger than two gigabytes.

ncid = netcdf.open(filename,'NC_WRITE');

varid = netcdf.inqVarID( ncid, var_name );


%% ## 2. write into netcdf
netcdf.putVar( ncid, varid, data, varargin{:} );


%% ## 3. close file
netcdf.close(ncid);


return