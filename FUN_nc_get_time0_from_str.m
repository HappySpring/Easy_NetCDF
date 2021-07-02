function [time0, unit_str, unit_to_day] = FUN_nc_get_time0_from_str( time_str )
% [time0, unit_str, unit_to_day] = FUN_nc_get_time0_from_str( time_str )
%
% % Get more information from the units of nc files
% -------------------------------------------------------------------------
% INPUT:
%   time_str: 
%       A string containing unit of time, 
%       It is usually the the attribute "units" of the variable for time.
%       You may get it by `time_str = FUN_nc_attget( filename, time_var_name, 'units');`
%
% -------------------------------------------------------------------------
% OUTPUT:
%   time0:       the origin of the time axis.
%   unit_str:    time unit, e.g., 'days', 'hours'
%   unit_to_day: This is a factore to convert the current unit to days.
%      for example, if the time unit in the netcdf is hours, then
%      unit_to_day = 1/24. if the time unit int he netcdf is seconds, 
%      unit_to_day = 1/24/3600. It would be empty if the unit is 'months' or
%      'years' since it is not constant in such cases. 
% -------------------------------------------------------------------------
% Example: 
%
% time_str = 'hours since 1990-00-00 00:00';
% [time0, unit_str, unit_to_day] = FUN_nc_get_time0_from_str( time_str )
% 
% then, 
%   time0 = 726802
%   unit_str = 'hours'
%   unit_to_day = 0.0417 (1/24)

% -------------------------------------------------------------------------
% by L. Chi
% V1.12 2021-06-29: Use datetime (instead of datenum) to handle general data format
% V1.11 2021-06-24: add support for other format by "datenum" with its
%                     default behaviors. Please note that this may lead to 
%                     errors. And there is a potential bug in the matlab 
%                     built-in function datenum (See exampmles below)
%
%                     >> datestr(datenum('0001-00-00'))
%                     >> ans =
%                         '31-Dec-1999'
% 
%                     >> datestr(datenum('0015-00-00'))
%                     >> ans =
%                         '31-Dec-0014'
% 
% V1.10 2020-07-09: use regular expression to detect the time format
% V1.05 2019-08-24: Add support for msec
% V1.04 2017-04-16: Add support for minutes
% V1.03 2017-03-06: Fix a bug: data0 may be in format of yyy-mm-dd.
% V1.02 2016-10-31: Add support for second
% V1.01 2016-04-10: add additional format of time to make sure the result
%                   is correct.
% V1.00 2015-11-30 by L. Chi (L.Chi.Ocean@outlook.com)
% =========================================================================

% ==== # Find strings for starting time ===================================
    loc_since = strfind( time_str, 'since');
    time0_str = time_str( loc_since + length('since'):end );


% ==== # detect time format and convert strings into time =================
    % ** The order of pattern matters **
    % Leave the one for "yyyy-mm-dd" at the end since it will match all of the others. 

    % ---- ## Pre-defined time format ----
    itf = 0;

    itf = itf + 1;
    pd_time_format(itf).pattern    = '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}Z';
    pd_time_format(itf).timeformat = 'yyyy-mm-ddTHH:MM:SSZ';

    itf = itf + 1;
    pd_time_format(itf).pattern    = '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}T[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}';
    pd_time_format(itf).timeformat = 'yyyy-mm-ddTHH:MM:SS';
    
    itf = itf + 1;
    pd_time_format(itf).pattern    = '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}';
    pd_time_format(itf).timeformat = 'yyyy-mm-dd HH:MM:SS';

    itf = itf + 1;
    pd_time_format(itf).pattern    = '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}T[0-9]{1,2}:[0-9]{1,2}';
    pd_time_format(itf).timeformat = 'yyyy-mm-ddTHH:MM';
    
    itf = itf + 1;
    pd_time_format(itf).pattern    = '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}';
    pd_time_format(itf).timeformat = 'yyyy-mm-dd HH:MM';

    itf = itf + 1;
    pd_time_format(itf).pattern    = '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}';
    pd_time_format(itf).timeformat = 'yyyy-mm-dd';
    
    % ---- ## detect time format and get time0 ----
    time_str_selected = [];
    for ii = 1:length( pd_time_format )
        time_str_selected = regexp( time0_str, pd_time_format(ii).pattern, 'match');
        if isempty( time_str_selected )
            continue
        else
            time0 = datenum( time0_str, pd_time_format(ii).timeformat );
            break
        end
    end
    
    % ---- ## error if none of the pre-defined formats matched.------------
    if isempty( time_str_selected )
        try

            %time0 = datenum( time0_str );
            % Mathworks suggests that datetime is a better choice than datenum.
            % To keep compatiable with some old codes, `datenum` is applied to the
            % output of `datetime`.
			time0 = datenum( datetime( time0_str ) );
            fprintf(' FUN_nc_get_time0_from_str: "%s" -> %s. Please abort the command if this conversion is wrong \n', time0_str, datestr(time0) )
        catch
            error(['Unknown time format: ' time0_str])
        end
    end
    
    % % ---- Archive: Old codes -------------------------------------------
    %     if length( time0_str ) <12
    %         time0 = datenum( time0_str,'yyyy-mm-dd' );
    %     elseif  length( time0_str ) <18
    %         time0 = datenum( time0_str, 'yyyy-mm-dd HH:MM' );
    %     else
    %         time0 = datenum( time0_str, 'yyyy-mm-dd HH:MM:SS' );
    %     end
    %     
% ==== # detect time unit =================================================


    unit_str = time_str( 1: loc_since-2);

    if strcmp( unit_str, 'msec' )
        unit_to_day = 1/24/3600/1000;
    elseif strcmp( unit_str, 'seconds' )
        unit_to_day = 1/24/3600;
    elseif strcmp( unit_str, 'minutes' )
        unit_to_day = 1/24/60;
    elseif strcmp( unit_str, 'hours' )
        unit_to_day = 1/24;
    elseif strcmp( unit_str, 'days' )
        unit_to_day = 1;
    elseif strcmp( unit_str, 'months' )
        unit_to_day = []; %
    elseif strcmp( unit_str, 'years' )
        unit_to_day = [];
    else
        error('unacceptable unit '); 
    end

