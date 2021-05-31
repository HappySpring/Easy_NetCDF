function time_out = FUN_nc_convert_time_to_time_in_matlab( time_in, time_unit_str )
% time_out = FUN_nc_convert_time_to_time_in_matlab( time_in, time_unit_str )
% 
% convert time from nc files to time in matlab unit (days from 0000-00-00);
%
% -------------------------------------------------------------------------
% INPUT: 
%       time_in      : time read from 
%       time_unit_str: time units read from netcdf files. 
%                      It should be given following a format like this:
%                      "days since 2000-00-00 00:00:00"
%                      "hours since 2000-00-00 00:00"
%                      ...
%                      More details can be found in FUN_nc_get_time0_from_str
% OUTPUT:
%      time_out : time in matlab built-in unit (days since 0000-00-00
%      00:00)
% -------------------------------------------------------------------------
% By L. Chi, 2020-10-14 (L.Chi.Ocean@outlook.com)
% -------------------------------------------------------------------------

[time0, ~, unit_to_day] = FUN_nc_get_time0_from_str( time_unit_str );
time_out = time0 + time_in .* unit_to_day;
