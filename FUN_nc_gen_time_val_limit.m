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
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)
% -------------------------------------------------------------------------
%%

% load time series
    time_in_ori = FUN_nc_varget_enhanced( filename0,  time_var_str );
    time_mtl = FUN_nc_get_time_in_matlab_format( filename0, time_var_str ); % time in matlab format
        
% calculate time limit in the original format of the given netcdf file
    time_ind = find( time_mtl >= timelimit(1) & time_mtl <= timelimit(2) );

    time_limit_in_ori = [ min( time_in_ori( time_ind) ),  max( time_in_ori( time_ind) ) ] ;
    time_mtl = time_mtl( time_ind );
    
% test results
    time_test = FUN_nc_varget_enhanced_region_2( filename0, time_var_str, {time_var_str}, {time_limit_in_ori} );

    if isequal(time_test.time, time_in_ori(time_ind))
    else
        error('Failed in test, Unexpected values!');
    end