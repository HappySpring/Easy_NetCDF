function data = FUN_nc_varget_enhanced_region(filename, varname, start, counts, stride )
% data = FUN_nc_varget_enhanced_region( filename, varname, start, counts, stride)
% data = FUN_nc_varget_enhanced_region( filename, varname)
% 
% Read the selected region of a variable. 
%
% scale, offset and missing values will be corrected automatically.
% -------------------------------------------------------------------------
% INPUT:
%   filename: name of the nc file
%   varname : name of the variable will be read from the nc file
%   start, count, stride: see doc netcdf.getVar
% -------------------------------------------------------------------------
% OUTPUT: 
%   data: data from the nc files
% -------------------------------------------------------------------------
% Example
% data2 = FUN_nc_varget_enhanced( 'TEST.nc', 'tempearture_3D', [ 20, 16, 30],[10, 15, 20], [1, 1, 1]);

%
% V1.23 by L. Chi, 2018-01-21: Add mask_value
% V1.22 by L. Chi, 2016-07-30: The function can be called by 2
% parameters like this: FUN_nc_varget_enhanced_region(filename,varname)
% V1.21 by L. Chi, 2015-11-30: Make sure output data will always be a double variable. 
%                                  Support add_offset
% V1.20 by L. Chi, 2015-11-11: Add auto scale_factor; fix a bug for auto-nan
% V1.12 by L. Chi, 2015-11-02: return to V1.10
% V1.11 by L. Chi, 2015-11-02: Fix a bug: double( data ) before data(nanloc) = nan;
% V1.10 by L. Chi, 2015-08-04. (L.Chi.Ocean@outlook.com)

if ~exist('stride','var') || isempty( stride )
    stride = ones( size( counts ) );
end

ncid = netcdf.open(filename,'NOWRITE');
varid = netcdf.inqVarID(ncid,varname);

count_inf_ind = find( isinf( counts ) );
if ~isempty( count_inf_ind )
% replace inf to the actuall length    
    
    [~,~,dimids,~] = netcdf.inqVar( ncid, varid );
    
    dim_len = nan( 1, length(count_inf_ind) );
    for jj = 1:length( count_inf_ind )
    
        [~, dim_len(jj) ] = netcdf.inqDim( ncid, dimids( count_inf_ind(jj) ) );
        dim_len(jj) = dim_len(jj) - start(count_inf_ind(jj));
    end
    
    counts( count_inf_ind ) = dim_len;
end


if nargin == 2
    data = netcdf.getVar(ncid, varid);
elseif nargin ==4 || nargin == 5 % stride is optional
    data = netcdf.getVar(ncid, varid, start, counts, stride );
else
    error
end

% get the format of data ( single or double )
data_format = whos('data');
data_format = data_format.class;

%% deal with Nans
 var_info = ncinfo(filename,varname);
 Nan_loc = false( size(data) ) ; 
 
 % If the data is single & FillValue is double, then the FillValue must be
 % converted into signle format to make sure nan can be detected correctly.
 % 
 scale_factor = 1;
 
 for ii = 1:length(var_info.Attributes)
    if strcmp( var_info.Attributes(ii).Name, 'FillValue')
        nan_val = netcdf.getAtt(ncid,varid,'FillValue');
        eval( ['nan_val = ' data_format '(nan_val);'] ); 
        Nan_loc = ( Nan_loc | data == nan_val );
        clear nan_val
    elseif strcmp( var_info.Attributes(ii).Name, '_FillValue')
        nan_val = netcdf.getAtt(ncid,varid,'_FillValue');
        eval( ['nan_val = ' data_format '(nan_val);'] ); 
        Nan_loc = ( Nan_loc | data == nan_val );
        clear nan_val
    elseif strcmp( var_info.Attributes(ii).Name, 'missing_value')
        nan_val = netcdf.getAtt(ncid,varid,'missing_value');
        eval( ['nan_val = ' data_format '(nan_val);'] )
        Nan_loc = ( Nan_loc | data == nan_val );
        clear nan_val
    elseif strcmp( var_info.Attributes(ii).Name, 'mask_value')
        nan_val = netcdf.getAtt(ncid,varid,'mask_value');
        eval( ['nan_val = ' data_format '(nan_val);'] )
        Nan_loc = ( Nan_loc | data == nan_val );
        clear nan_val
    elseif strcmp( var_info.Attributes(ii).Name, 'scale_factor')
        scale_factor = netcdf.getAtt(ncid,varid,'scale_factor');
    end
 end
    clear ii

%%
data = double(data);
data( Nan_loc ) = nan; 

data = data .* double( scale_factor );


%% Add offset
 offset = 0 ;

 for ii = 1:length(var_info.Attributes)
    if strcmp( var_info.Attributes(ii).Name, 'add_offset')
        offset = netcdf.getAtt(ncid,varid,'add_offset');
    end
 end
    clear ii
    
data = data + double( offset ) ;
    
%% return
netcdf.close(ncid)

