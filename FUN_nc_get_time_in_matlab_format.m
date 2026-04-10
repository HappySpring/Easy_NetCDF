function [tem_time, raw_time, tem_time_unit] = FUN_nc_get_time_in_matlab_format( file_now,  nc_time_str, varargin )
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
%     raw_time: time in raw unit (without unit convertion based on time units)
% -------------------------------------------------------------------------

% V1.31 by L. Chi: add more outputs
% V1.30 by L. Chi: add a temporal fix for netcdf files with reference time before 1583 which may cause calendar problems.
% V1.2  by L. Chi: fix a bug introduced in V1.1
% V1.1  by L. Chi: Support loading a part of the time series.
% V1.0  by L. Chi (L.Chi.Ocean@outlook.com)

%% parameters
    
% this is a temporal fix to download era5 from asian-pacific data center from hawaii, which use mixed julian/gregorian calendar, which means Julian calender before Oct 1852 and Gregorian calendar after that. There is a jump in Oct 1852 need to be handled specifically.
    is_rm_loadedd_param = true;
    [calendar_in, varargin] = FUN_codetools_read_from_varargin( varargin, 'calendar_in', [], is_rm_loadedd_param );

%%
    % load time & its unit
        if ~isempty(varargin)
            tem_time     = FUN_nc_varget_enhanced_region( file_now, nc_time_str, varargin{:} );
        else
            tem_time     = FUN_nc_varget_enhanced( file_now, nc_time_str );
        end
        
        if nargout >= 2
            raw_time = tem_time;
        end

        tem_time_unit = FUN_nc_attget( file_now, nc_time_str, 'units' );
        
    % decode the unit str
        [tem_time_ref, tem_unit_str, tem_unit_to_day] = FUN_nc_get_time0_from_str( tem_time_unit );
        
    % convert time into the matlab built-in unit
        if strcmpi( tem_unit_str, 'months')
            [yy,mm,dd,HH,MM,SS] = datevec( tem_time_ref );
            
            tem_time = datenum( yy, mm + tem_time, dd, HH,MM,SS );
            
        else
            tem_time = tem_time_ref + tem_time * tem_unit_to_day;
        end


        
        if tem_time_ref < datenum(1583,1,1) 
            
            if strcmpi( calendar_in, 'matlab' ) || strcmpi( calendar_in, 'proleptic_gregorian' )
                % matlab built-in calendar is the proleptic Gregorian calendar, which extends the Gregorian calendar to dates preceding its official introduction in 1582.

            elseif strcmpi( calendar_in, 'gregorian' ) 
                % gregorian means mixed Julian/Gregorian calendar, which means Julian calender before Oct 1852 and Gregorian calendar after that. There is a jump in Oct 1852 need to be handled specifically.
                % Here is a temporal fix for downloading era5 data from hawaii, which use the mixed Julian/Gregorian calendar. 
                %   The reference time is 0001-01-01 00:00:00 in the Julian calendar, which is 2 days later in the proleptic Gregorian calendar. 
                %   So we add a constant offset of 2 days to handle this issue. This fix works for dates after 1583-01-01, 
                %   but may cause errors for dates before that due to the date switch in 1582 and different definitions of 
                %   leap years. A more rigorous fix is needed if the data contain dates before 1583-01-01 or the referece time is not 0001-01-01.
                

                if all( tem_time > datenum(1583,1,1) ) && tem_time_ref == datenum(1,1,1)
                    disp(' A temporal fix of -2 days is applied for the mixed Julian/Gregorian calendar (Gregorian calendar) with a reference time of 0001-01-01!');
                    tem_time = tem_time - 2; 
                else
                    error('Calendar "gregorian" only support dates after 1583-01-01. And the current tomporal fix only works for reference time of 0001-01-01 as used by hawaii asican pacific data center!')
                end

            else
                    warning('Referce time is before 1583, which may cause errors due to calendar switch from Julidan to Gregorian');
                    error(' A calendar type must be given explicitly if the reference time is before 1583!');

            end
            
        end

        
 return
      