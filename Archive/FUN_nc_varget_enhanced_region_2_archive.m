function [ out_dim, data ] = FUN_nc_varget_enhanced_region_2( filename, varname, dim_str, dim_limit, time_var_name )
% [ out_dim, data ] = FUN_nc_varget_enhanced_region_2( filename, varname, dim_str, dim_limit, [time_var_name] )
% Advanced nc file loader
% time_var_name is optional
%
% -------------------------------------------------------------------------
% INPUT:
%      filename : name of the NetCDF file
%      varname  : name of the variable
%                 For global attributes, the varname should be empty ([]).
%      dim_str  : name of the attribute. 
%      dim_limit:
%      time_var_name: [optional], name of the time axis
%
% OUTPUT:
%      att_value: value of the attribute 
% -------------------------------------------------------------------------
% Example: 
%
% filename  = 'I:\Data\ECCO2\data1_cube92_latlon_quart_90S_90N\SALT_monthly.nc\SALT.1440x720x50.199210.nc';
% varname   = 'SALT';
% dim_str   = { 'LONGITUDE_T', 'LATITUDE_T', 'DEPTH_T', 'TIME' };
% dim_limit = {[-100 -50]+360, [20 50 ],  [0 500] , [-inf inf] };
% 
% [ out_dim, data ] = FUN_NC_varget_enhanced_region_2( filename, varname, dim_str, dim_limit );
% -------------------------------------------------------------------------


% V1.10 By L. Chi
% V1.00 By L. Chi

%% prepare for loading 
for id = 1:length(dim_str)
    
    % ### default condition
    dim_is_time(id) = false;
    dim_var_exist(id) = true;
    
    % ### for time axis
    if exist('time_var_name','var') && ~isempty( time_var_name )
        if strcmpi( dim_str{id}, time_var_name )
            
            dim_list{id} = FUN_nc_get_time_in_matlab_format( filename, dim_str{id} );
            [nc_start(id) , nc_count(id), loc{id} ] = FUN_nc_varget_sub_genStartCount( dim_list{id}, dim_limit{id} );
            dim_list2{id} = dim_list{id}(loc{id});
            
            dim_is_time(id) = true;
            
            continue
        end
    end
    
    % ### for other axises
    try
        % ### Normal Case
        dim_list{id} =  FUN_nc_varget_enhanced( filename, dim_str{id} );
        
        [nc_start(id) , nc_count(id), loc{id} ] = FUN_nc_varget_sub_genStartCount( dim_list{id}, dim_limit{id} );
        
        dim_list2{id} = dim_list{id}(loc{id});
        
        
        
    catch log_err_1
        % ### if the variable for this dim does not exist.
        if FUN_nc_get_dim_length( filename, dim_str{id} ) == 1 ...
                && ...
                     ( isequal( dim_limit{id}(1), -inf ) && isequal( dim_limit{id}(2), inf ) ...
                       || isempty(  dim_limit{id} ) ...
                      )
                  
                  dim_list2{id}  = nan;
                  nc_start(id) = 0;
                  nc_count(id) = 1;
                  loc{id} = true;
                  
                  dim_var_exist(id) = false;

        else
            error('Error in loading axis value!');
        end
    end
        
    

    
end
    clear id
    
    nc_strid = ones(size(nc_start));
    
%% load data
    data = FUN_nc_varget_enhanced_region( filename, varname, nc_start, nc_count, nc_strid );
    
%% check dimension 
for id = 1:length(dim_str)
    
    if ~dim_var_exist(id) 
       % Skip the check if the variable does not exist.
       continue 
    end
    
    if  dim_is_time(id)
        dim_list_check{id} = FUN_nc_get_time_in_matlab_format( filename, dim_str{id}, nc_start(id), nc_count(id), 1 );
    else
        dim_list_check{id} = FUN_nc_varget_enhanced_region( filename, dim_str{id}, nc_start(id), nc_count(id), 1 );
    end
    if all( dim_list_check{id} == dim_list2{id})
    else
       error('Dimension doesn''t match!') 
    end
end
    clear id

%% output
for id = 1:length(dim_str)
    out_dim.(dim_str{id}) = dim_list2{id};
end
