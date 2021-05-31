function tem_time = FUN_nc_get_time_in_matlab_format( file_now,  nc_time_str, varargin )
% tem_time = FUN_nc_get_time_in_matlab_format( file_now,  nc_time_str, varargin );
%  load time from netcdf files as the default unit in matlab 
%  This requires that time variable must contain an attribute like "hours sinc 2000-01-01 00:00:00"
% -------------------------------------------------------------------------
% INPUT
%     file_now   :  file name
%     nc_time_str:  name of variable for time
%     varargin [optional]: Same as [ start, count, stride ] in
%           netcdf.getVar. Please "doc netcdf.getVar" for more details.
% -------------------------------------------------------------------------
% OUTPUT
%     tem_time: time in days since  0000-00-00 00:00:00 (default unit used by matlab)
% -------------------------------------------------------------------------

% V1.2 by L. Chi: fix a bug introduced in V1.1
% V1.1 by L. Chi: Support loading a part of the time series.
% V1.0 by L. Chi (L.Chi.Ocean@outlook.com)

%%
    % load time & its unit
        if nargin > 2
            tem_time     = FUN_nc_varget_enhanced_region( file_now, nc_time_str, varargin{:} );
        else
            tem_time     = FUN_nc_varget_enhanced( file_now, nc_time_str );
        end
        tem_time_unit = FUN_nc_attget( file_now, nc_time_str, 'units' );
        
    % decode the unit str
        [tem_time_ref, tem_unit_str, tem_unit_to_day] = FUN_nc_get_time0_from_str( tem_time_unit );
        
    % convert time into the matlab built-in unit
        if strcmpi( tem_unit_str, 'months');
            [yy,mm,dd,HH,MM,SS] = datevec( tem_time_ref );
            
            tem_time = datenum( yy, mm + tem_time, dd, HH,MM,SS );
            
        else
            tem_time = tem_time_ref + tem_time * tem_unit_to_day;
        end

        
 return
      