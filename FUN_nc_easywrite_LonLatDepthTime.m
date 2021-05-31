function FUN_nc_easywrite_LonLatDepthTime(filename,varname,data,lon,lat,depth,time,varargin)
% FUN_NC_easywrite(filename,varname,data,[namelist of each dims],[discriptions])
% for example:
%    FUN_NC_easywrite('temp.nc',{'T','Salt'},{Temp,Salt}); or
%    FUN_NC_easywrite('temp.nc',{'T'},{Temp},{'x','y','z','t'}; or
%    FUN_NC_easywrite('temp.nc',{'T'},{Temp},{'x','y','z','t'},'This is an example'); 
% 2013-12-19 V1

if exist(filename,'file')
    delete(filename)
end
%% 1 Create netcdf
% cid = netcdf.create(filename, mode)
% mode£º
% 'NC_NOCLOBBER'£º                Prevent overwriting of existing file with the same name.
% 'NC_SHARE'£º                        Allow synchronous file updates.
% 'NC_64BIT_OFFSET'£º        Allow easier creation of files and variables which are larger than two gigabytes.
ndims = length(size(data));
ncid = netcdf.create(filename,'NETCDF4');

%% 2 Define dimensions
% dimid = netcdf.defDim(ncid,dimname,dimlen)


dim_name_default = {'x','y','z','t'};
if length(varargin) >=1
    dim_name = varargin{1};
else
    dim_name = dim_name_default;
end

    dimID(1) = netcdf.defDim(ncid,dim_name{1}, length(lon) );
    dimID(2) = netcdf.defDim(ncid,dim_name{2}, length(lat) );
    dimID(3) = netcdf.defDim(ncid,dim_name{3}, length(depth) );
    dimID(4) = netcdf.defDim(ncid,dim_name{4}, length(time) );


%% 3. Define variables
% varid = netcdf.defVar(ncid,varname,xtype,dimids)
    varid = netcdf.defVar(ncid,varname,'double',dimID);
    varidlon   = netcdf.defVar(ncid, 'lon','double',dimID(1)  );
    varidlat   = netcdf.defVar(ncid, 'lat','double',dimID(2)  );
    variddepth = netcdf.defVar(ncid, 'depth','double',dimID(3));
    varidtime  = netcdf.defVar(ncid, 'time','double',dimID(4) );

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
%% ** Add global an attributre
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
netcdf.putVar(ncid,varidlon,lon)
netcdf.putVar(ncid,varidlat,lat)
netcdf.putVar(ncid,variddepth,depth)
netcdf.putVar(ncid,varidtime,time)


%% 6 close the netcdf filie
netcdf.close(ncid);


return