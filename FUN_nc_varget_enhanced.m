function data = FUN_nc_varget_enhanced(filename,varname,varargin)
% data = FUN_nc_varget_enhanced(filename,varname)
% data = FUN_nc_varget_enhanced(filename, varname, [ special_points_list ] )
%
% compared with old version( FUN_nc_varget ), this new scripts will detect
% and handling scale, offset, and missing values.
% ----------------------------------------------------------------------- %
% INPUT:
%   filename: name of the nc file
%   varname:  name of the variable will be read from the nc file
%   special_points_list: optional. Only the specific points listed in
%       `speical_points_list` will be read.
%       format: M x N, where M should be the number of specific points,
%       and N should be the same as the dimension of variable which will be
%       loaded from the nc file. 
%       each line of special_points_list define a specific points.        
%       The whole variable will be loaded if varname doesn't exist. 
% -------------------------------------------------------------------------
% OUTPUT: 
% data: data from the nc files
% ----------------------------------------------------------------------- %
% Example
% data  = FUN_nc_varget_enhanced( 'TEST.nc', 'tempearture_3D');
% data2 = FUN_nc_varget_enhanced( 'TEST.nc', 'tempearture_3D', [ 20, 16, 30]);
%    In the second case, data2 = data(20,16,30); 
% ----------------------------------------------------------------------- %

% V1.4  by L. Chi, 2019-06-23: ".'" is used instead of "'"
% V1.3  by L. Chi, 2018-04-03: Add support for loading variable with
% datatype "char".
% V1.2  by L. Chi, 2016-10-24: Add slope and offset values
% V1.12 by L. Chi, 2016-08-18
%             This function won't try to apply the nan mask if missing
%             values are not detected.
% V1.11 by L. Chi, 2015-09-09
%                add _FillValue => nan;
% V1.10 by L. Chi, 2015-08-04. (L.Chi.Ocean@outlook.com)

if nargin == 3
   is_read_special_points_only = 1; 
   special_points_list = varargin{1};
else
   is_read_special_points_only = 0; 
   special_points_list= [];
end

ncid = netcdf.open(filename,'NOWRITE');
varid = netcdf.inqVarID(ncid,varname);
if is_read_special_points_only == 0
    data = netcdf.getVar(ncid,varid);
elseif is_read_special_points_only == 1;
    
    for isp = 1:size(special_points_list,1)
       data(isp) = netcdf.getVar(ncid,varid, [special_points_list(isp, :)-1], ones(1,size(special_points_list,2) )   );
    end
        clear isp
end
% get the format of data ( single or double )
data_format = whos('data');
data_format = data_format.class;

%% deal with Nans
 var_info = ncinfo(filename,varname);
 
 if strcmp( var_info.Datatype(1:4), 'char')
     % For characters -----------------------------------------------------
         % No further correction is necessary
         
         
     % For 1-D characters, it will be reshaped into 1 line automatically
     if sum( [var_info.Dimensions.Length] > 1.1 ) == 1
         data = data(:).';
     end
     
     % --------------------------------------------------------------------    
 else
     % For numbers --------------------------------------------------------
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
        elseif strcmp( var_info.Attributes(ii).Name, 'scale_factor')
            scale_factor = netcdf.getAtt(ncid,varid,'scale_factor');
        end
     end
        clear ii

        data = double(data);

        if sum( Nan_loc ) == 0
            % No nan mask will be applied
        else
            data( Nan_loc ) = nan;
        end

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

    %% convert to double
    data = double(data);

 end
%% close netcdf
netcdf.close(ncid)

