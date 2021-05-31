function chunksize = FUN_nc_internal_calc_chunk( data_size, bytes_per_val )
% chunksize = FUN_nc_internal_calc_chunk( data_size, bytes_per_val )
% Calculat the chunk from data size.
% Please note that this works for datasets I used everyday, but is not
% necessary a good choice for other datasets.
% -------------------------------------------------------------------------
% Ref: 
% https://www.unidata.ucar.edu/blogs/developer/en/entry/chunking_data_choosing_shapes
% note: the above ref provides background information. This optimal estimation does not follow it closely. 
% -------------------------------------------------------------------------
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%%

chunk_size_in_bytes = 4096*10; % size of one 

chunksize = data_size;

if length( chunksize ) >= 3
    chunksize(3:end) = 1;
end

N =  ( prod( data_size(1:min([2 end])) ) ./ ( chunk_size_in_bytes/bytes_per_val) )^(1/2);
N = round( N );

for idm = 1 : min( [2, length( data_size ) ])
    
    chunksize(idm) = round( data_size(idm) / N );
    
    if chunksize(idm) == 0
        chunksize(idm) = 1;
    end
    
    if data_size(idm)/chunksize(idm) < 3
        chunksize(idm) = data_size(idm);
    end
    
end



