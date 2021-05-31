function diminfo = FUN_nc_get_dims_from_varname( filename, varname )
% Find names and values of demensions of a given varname.
% V1.00 L. Chi (L.Chi.Ocean@outlook.com)

%% TEST only
% filename = './NETCDF4_selfGenreated/soda3.3.1_5dy_ocean_or_1999_12_24.nc';
% varname = 'temp';

%% 

varinfo = ncinfo( filename, varname );
diminfo = varinfo.Dimensions;

for ii = 1:length( diminfo )
   diminfo(ii).val = FUN_nc_varget_enhanced(filename, diminfo(ii).Name); 
end
