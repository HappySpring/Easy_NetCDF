function data = FUN_exchage_dim(data, dim1, dim2 )
% exchange two dimensions in a n-dim matrix
%

% 2020-04-20, By L. Chi dim1, dim2 can exceed ndim(data) now.
% 2015-11-08, By L. Chi

tot_dim = max( [ndims(data), dim1, dim2] );

dimlist = 1 : tot_dim;

dimlist(dim1) = dim2;
dimlist(dim2) = dim1;

data = permute( data, dimlist );
