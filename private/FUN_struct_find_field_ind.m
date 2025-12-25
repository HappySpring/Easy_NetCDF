function field_ind = FUN_struct_find_field_ind( data_in, name_field_str, name_required )
%V1.1 replace strcmp by isequal. All tpyes of data, including numbers are
%supported now.


field_ind = nan;
for ii = 1:length( data_in )
   
   
    
    if isequal( data_in(ii).(name_field_str), name_required)
       if isnan(field_ind)
            field_ind = ii;
       else
            error('imposible condition! something must be wrong.')
       end
   end
    
    
end
