function FUN_nc_easywrite_enhanced( filename, dim_name, dim_length, varname, dimNum_of_var, data, global_str_att, varargin )
% FUN_nc_easywrite_enhanced( filename, dim_name, dim_length, varname, dimNum_of_var, data, global_str_att, varargin )
%
% Created NetCDF files containing one or more variables
% FUN_nc_easywrite_unconstructed_data( filename, dim_name, dim_length, varname, dimNum_of_var, data, global_str_att )
% for example:
%    FUN_nc_easywrite_enhanced('temp.nc',...
%                       {'Node','Cell','time'},[1000 2000 500],...
%                       {'node_lon','node_lat','lon_cell','lat_cell','sst'},{1,1,2,2,[1 3]},...
%                       {lon_node,lat_node,lon_cell,lat_cell,sst},'This is an example');
%
%    FUN_nc_easywrite_enhanced('test23.nc',...
%                       {'Node','cell'},[length(lon_node) 5],...
%                       {'lon_node','lat_node','D50_interp','test'},{1,1,1,[1 2]},...
%                       {lon_node,lat_node,D50_interp, repmat(D50_interp,1,5)},'This is an example'); 
%     
%

% 2025-10-17 v1.22 by L. Chi: add new parameter: force_chunksize_by_dim
%                             empty variable will not be put into the file
%                             (and won't cause an error). This is used to
%                             create empty file
% 2025-02-23 v1.21 by L. Chi: fix a bug in handling 1-D variables
% 2022-08-18 V1.20 by L. Chi: support unlimited size of dimension (defined by inf in dim_length)
% 2021-05-31 V1.11 by L. Chi: fix a bug in writting global attributes.
% xxxx-xx-xx V1.10 by L. Chi: support parameter `is_auto_chunksize`: estimating the chunksize automatically. 
% xxxx-xx-xx V1.01 by L. Chi: skip global att if 'global_str_att' does not exist or is empty.
% 2016-04-11 V1.00 by L. Chi (L.Chi.Ocean@outlook.com)


%% set default value 

% use a customed function to calculate the best chunksize
[is_auto_chunksize, varargin] = FUN_codetools_read_from_varargin( varargin, 'is_auto_chunksize', false, true );

% provide a chunksize for each dimension manually.
% for example, force_chunksize_by_dim = [ 100 100 1 ], where dim_name = {'lon','lat','time}
[force_chunksize_by_dim,   varargin] = FUN_codetools_read_from_varargin( varargin, 'force_chunksize_by_dim', [], true );


if ~isempty( varargin )
    error('Unkown parameters found!')
end

if ~iscell( dim_name )
    dim_name = {dim_name};
end

if ~iscell( varname )
    varname = {varname};
end

if ~iscell( dimNum_of_var )
    dimNum_of_var = {dimNum_of_var};
end

if ~iscell( data )
    data = {data};
end

%% remove old files

if exist(filename,'file')
    delete(filename)
end


%% 1 Create netcdf
% cid = netcdf.create(filename, mode)
% mode£º
% 'NC_NOCLOBBER'£º                Prevent overwriting of existing file with the same name.
% 'NC_SHARE'£º                        Allow synchronous file updates.
% 'NC_64BIT_OFFSET'£º        Allow easier creation of files and variables which are larger than two gigabytes.
% ndims = length(size(data));
ncid = netcdf.create(filename,'NETCDF4');

%% 2 Define dimensions
% dimid = netcdf.defDim(ncid,dimname,dimlen)

for idim = 1:length(dim_name)
    if isinf( dim_length(idim) )
        dim_length_ind = netcdf.getConstant('NC_UNLIMITED') ;
    else
        dim_length_ind = dim_length(idim) ;
    end
        dimID(idim) = netcdf.defDim(ncid,dim_name{idim}, dim_length_ind );
    
end
    clear idim
%% 3. Define variables
% varid = netcdf.defVar(ncid,varname,xtype,dimids)
    for ivar = 1:length(varname)
        
        try
            data_type = FUN_nc_defVar_datatypeconvert( class(data{ivar}) );
        catch
            warning('Unknown datatype, DOUBLE will be used by dafault');
            data_type = 'double';
        end
        varid(ivar) = netcdf.defVar( ncid, varname{ivar}, data_type, dimID( dimNum_of_var{ivar} )  );
    end
        clear ivar
        
% ### compression ---------------------------------------------------------
% netcdf.defVarDeflate(ncid,varid,shuffle,deflate,deflateLevel)
%
% Descriptionnetcdf.defVarDeflate(ncid,varid,shuffle,deflate,deflateLevel) sets the compression parameters for the NetCDF variable specified by varid in the location specified by ncid.
% shuffle:
% Boolean value. To turn on the shuffle filter, set this argument to true. The shuffle filter can assist with the compression of integer data by changing the byte order in the data stream.
% deflate:
% Boolean value. To turn on compression, set this argument to true and set the deflateLevelargument to the desired compression level.
% deflateLevel:
% Numeric value between 0 and 9 specifying the amount of compression, where 0 is no compression and 9 is the most compression.
for ivar = 1:length(varname)
    netcdf.defVarDeflate(ncid,varid(ivar),true,true,1);
end

% ### chunksize -----------------------------------------------------------
for ivar = 1:length(varname)

    % set chunk size (not necessary for non-dimensional var)

    if ~isempty(force_chunksize_by_dim)

        netcdf.defVarChunking( ncid, varid(ivar), 'CHUNKED', force_chunksize_by_dim(dimNum_of_var{ivar}) );

    elseif is_auto_chunksize

        try
            data_type = FUN_nc_defVar_datatypeconvert( class(data{ivar}) );
        catch
            warning('Unknown datatype, DOUBLE will be used by dafault');
            data_type = 'double';
        end

        tmp_bytes_per_val = FUN_nc_internal_bytes_per_value( data_type );
        tmp_chunksize = FUN_nc_internal_calc_chunk( dim_length( dimNum_of_var{ivar} ), tmp_bytes_per_val );
        netcdf.defVarChunking( ncid, varid(ivar), 'CHUNKED', tmp_chunksize );
    end

end
%% ** Add global an attributre
if exist('global_str_att','var') || ~isempty(global_str_att)
    netcdf.putAtt(ncid, netcdf.getConstant('NC_GLOBAL'), 'description', global_str_att );
end
%% 4 exit definition mode
netcdf.endDef(ncid)


%% 5 write data
% netcdf.putVar(ncid,varid,data)
% netcdf.putVar(ncid,varid,start,data)
% netcdf.putVar(ncid,varid,start,count,data)
% netcdf.putVar(ncid,varid,start,count,stride,data)
for ivar = 1:length(varname)
    
    nc_start = zeros(ndims(data{ivar}),1);
    nc_stride   = ones(ndims(data{ivar}),1);
    nc_count    = size(data{ivar});
    
    if length(dimID( dimNum_of_var{ivar} )) == 1
        
        if sum( size(nc_count) > 1 ) <= 1
        else
            error
        end

        nc_start = unique(nc_start);
        nc_stride= unique(nc_stride);
        nc_count = max(nc_count);        
    end
    
    if ~isempty(data{ivar})
        netcdf.putVar( ncid, varid(ivar), nc_start(:)', nc_count(:)', nc_stride(:)',  data{ivar} );
    end
end


%% 6 close the netcdf filie
netcdf.close(ncid);


return