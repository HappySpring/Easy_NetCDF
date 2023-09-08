function FUN_nc_easywrite_create_blank_file(filename, mode, is_overwrite )
% FUN_nc_easywrite_create_blank_file(filename,mode)
%
% 2023-07-24 V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

if ~exist('mode','var') || isempty( mode )
    mode = 'NETCDF4';
end

if ~exist('is_overwrite','var') || isempty( is_overwrite )
    is_overwrite = true;
end

if strcmpi( mode, 'CLOBBER' ) &  ~is_overwrite
    error('Clober mode with is_overwrite set to false. Please fix this conflict!');
    
end


% if exist(filename,'file')
%     delete(filename)
% end


%% 1 Create Netcdf 

ncid = netcdf.create(filename, mode);


%% 4 exit definition mode
netcdf.endDef(ncid)

%% 6 close file
netcdf.close(ncid);


return