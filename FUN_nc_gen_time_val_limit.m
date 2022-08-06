function [ time_limit_in_ori, time_mtl ]= FUN_nc_gen_time_val_limit( filename0, time_var_str, timelimit )        
% [ time_limit_in_ori ]= FUN_nc_gen_time_val_limit( filename0, time_var_str, timelimit )       
% calculate time limit in the same unit as used in the netcdf file
% -------------------------------------------------------------------------
% INPUT
%      filename0: netcdf file path
%      time_var_str: name of time variable
%      timelimit: time limit in matlab format
% -------------------------------------------------------------------------
% OUTPUT
%       time_limit_in_ori
%       time_mtl
% -------------------------------------------------------------------------
%
% V1.01 By L. Chi: Improve performance
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)
% -------------------------------------------------------------------------
%%

% load time series
    time_in_ori = FUN_nc_varget_enhanced( filename0,  time_var_str );
    %time_mtl    = FUN_nc_get_time_in_matlab_format( filename0, time_var_str ); % time in matlab format
    
    tem_time_unit = FUN_nc_attget( filename0, time_var_str, 'units' );
    [tem_time_ref, tem_unit_str, tem_unit_to_day] = FUN_nc_get_time0_from_str( tem_time_unit );
    
    if strcmpi( tem_unit_str, 'months')
        [yy,mm,dd,HH,MM,SS] = datevec( tem_time_ref );
        
        time_mtl = datenum( yy, mm + time_in_ori, dd, HH, MM, SS );
        
    else
        time_mtl = tem_time_ref + time_in_ori * tem_unit_to_day;
    end

% calculate time limit in the original format of the given netcdf file
    time_ind = find( time_mtl >= timelimit(1) & time_mtl <= timelimit(2) );

    if isempty( time_ind )
        disp('Data are not available within the required range!')
        time_limit_in_ori = [nan nan];
        time_mtl = [];
        return
    end
    
    time_limit_in_ori = [ min( time_in_ori( time_ind) ),  max( time_in_ori( time_ind) ) ] ;
    time_mtl = time_mtl( time_ind );
    
% test results
    time_test = FUN_nc_varget_enhanced_region_2( filename0, time_var_str, {time_var_str}, {time_limit_in_ori} );

    if isequal(time_test.time, time_in_ori(time_ind))
    else
        error('Failed in test, Unexpected values!');
    end