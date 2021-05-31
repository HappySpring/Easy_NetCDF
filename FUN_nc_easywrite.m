function FUN_nc_easywrite(filename,varname,data,varargin)
% FUN_nc_easywrite(filename,varname,data,varargin)
% FUN_NC_easywrite(filename,varname,data,[dim_name])
% FUN_NC_easywrite(filename,varname,data,[dim_name],[global_discriptions])
%
% Create a netcdf file containing **one** variable with minimal parameters.
% ** For more complex cases, please use "FUN_nc_easywrite_enhanced" **
%
% -------------------------------------------------------------------------
% INPUT:
%   filename [string]: name of the netcdf file to be created
%   variable [string]: name of variables to be created. e.g., 'sst'
%   data     [array]: data array to be writtened to the netcdf file.
%   dim_name [cell, optional]:  name of dimensions of the variable.
%                (Default value: dimension_name = {'x','y','z','t'}).
%   global_discriptions [string,optional]: a global attribute will be added
%                           to the netcdf file if it is not empty
%
%   **Please use "FUN_nc_easywrite_enhanced" for writting more than one
%   variable.
% -------------------------------------------------------------------------
% OUTPUT:
%    N/A
% -------------------------------------------------------------------------
% Example:
%
%    FUN_NC_easywrite('temp.nc','T',Temp); or
%    FUN_NC_easywrite('temp.nc','T',Temp,{'x','y','z','t'}); or
%    FUN_NC_easywrite('temp.nc','T',Temp,{'x','y','z','t'},'This is an example'); 
%
% 2013-12-19 V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

if exist(filename,'file')
    delete(filename)
end
%% 1 Create Netcdf 
% cid = netcdf.create(filename, mode)
% mode£º
% 'NC_NOCLOBBER'           Prevent overwriting of existing file with the same name.
% 'NC_SHARE'               Allow synchronous file updates.
% 'NC_64BIT_OFFSET'        Allow easier creation of files and variables which are larger than two gigabytes.
ndims = length(size(data));
ncid = netcdf.create(filename,'NETCDF4');

%% 2 Define Dimensions
% dimid = netcdf.defDim(ncid,dimname,dimlen)


dim_name_default = {'x','y','z','t'};
if length(varargin) >=1
    dim_name = varargin{1};
else
    dim_name = dim_name_default;
end
for ii = 1:ndims
    dimID(ii) = netcdf.defDim(ncid,dim_name{ii},size(data,ii));
end

%% 3. Define variables
% varid = netcdf.defVar(ncid,varname,xtype,dimids)
varid = netcdf.defVar(ncid,varname,'double',dimID);

% [compression]------------------------------------------------------------
% netcdf.defVarDeflate(ncid,varid,shuffle,deflate,deflateLevel)
%
% Descriptionnetcdf.defVarDeflate(ncid,varid,shuffle,deflate,deflateLevel) sets the compression parameters for the NetCDF variable specified by varid in the location specified by ncid.
% shuffle:
% Boolean value. To turn on the shuffle filter, set this argument to true. The shuffle filter can assist with the compression of integer data by changing the byte order in the data stream.
% deflate:
% Boolean value. To turn on compression, set this argument to true and set the deflateLevelargument to the desired compression level.
% deflateLevel:
% Numeric value between 0 and 9 specifying the amount of compression, where 0 is no compression and 9 is the most compression.
netcdf.defVarDeflate(ncid,varid,true,true,1);

if length(varargin) >= 2
%% ** Add a global attribute
netcdf.putAtt(ncid,0,'description',varargin{2});
end
%% 4 exit definition mode
netcdf.endDef(ncid)


%% 5 write data
% netcdf.putVar(ncid,varid,data)
% netcdf.putVar(ncid,varid,start,data)
% netcdf.putVar(ncid,varid,start,count,data)
% netcdf.putVar(ncid,varid,start,count,stride,data)
netcdf.putVar(ncid,varid,data)


%% 6 close file
netcdf.close(ncid);


return