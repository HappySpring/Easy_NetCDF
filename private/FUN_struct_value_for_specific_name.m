function output = FUN_struct_value_for_specific_name( data_in, name_field_str, name_required, value_field_str )


N = 0;
for ii = 1:length( data_in )
   
   if strcmp( data_in(ii).(name_field_str), name_required)
       N = N + 1;
       output = data_in(ii).(value_field_str);
   end
    
    
end


if N == 0
    warning('Not found')
    output = [];
elseif N > 1
    error('more than 1 results are found')
end

