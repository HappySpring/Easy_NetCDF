function [data, ind_reverse] = FUN_dim_move_to_end(data, dim1 )
% move a specific dim to the end
% e.g. 
%       data = rand(2,3,4,5,6,7);
%       [data2, ind_reverse] = FUN_dim_move_to_end( data, 2);
%       size(data2) = [ 2 4 5 6 7 3]
%       size( permute(data2,ind_reverse) ) = [2 3 4 5 6 7];
% 2016-11-14, By Lequan Chi




tot_dim = ndims(data);

if dim1 == tot_dim
    ind_reverse = 1:tot_dim;
    
else
    dimlist = 1 : tot_dim;
    
    dimlist2 = dimlist;
    dimlist2(end) = dim1;
    dimlist2(dim1:end-1) = dimlist(dim1+1:end);
    
    ind_reverse = 1:tot_dim;
    ind_reverse(dim1) = tot_dim;
    ind_reverse(dim1+1:end) = ind_reverse(dim1+1:end)-1;
    
    data = permute( data, dimlist2 );

end


