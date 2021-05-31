function [ out_var, out_sourcefile_ind, filelist ] = FUN_nc_varget_enhanced_from_multifiles( input_dir, filelist, var_name, merge_dim_name )
% [ out_var, out_sourcefile_ind, filelist ] = FUN_nc_varget_enhanced_from_multifiles( input_dir, filelist, var_name, merge_dim_name )
%
% Load variable from multiple files.
% 
% "FUN_nc_varget_enhanced_region_2_multifile" is recommended. 
%
% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)


%% search all files to determine the information of the merged dimensiona.
MV.all = [];  % information of the merged dimension
MV.ind_start = nan( size( filelist ) );
MV.ind_end   = nan( size( filelist ) );

for ii = 1:length( filelist )

   tem_dim_length = FUN_nc_get_dim_length(  fullfile( input_dir, filelist(ii).name ), merge_dim_name );
   if  FUN_nc_exist_var( fullfile( input_dir, filelist(ii).name ), merge_dim_name )
        tem = FUN_nc_varget( fullfile( input_dir, filelist(ii).name ), merge_dim_name ); 
   else
        tem = ii * 100 + [1:tem_dim_length] * 99 / tem_dim_length;
   end
   
   MV.all = [ MV.all ; tem(:) ];
   
   if ii == 1
       MV.ind_start(ii) = 1;
       MV.ind_end(ii)   = tem_dim_length;
   else
       MV.ind_start(ii) = MV.ind_end(ii-1)+1;
       MV.ind_end(ii)   = MV.ind_start(ii) + tem_dim_length - 1;
   end
   
   clear tem
end
   clear ii
   
   % the total length of the merged dimension.
   MV.N = length( MV.all );
   
%% check: the values of the merged variable should increase monoically.
if all( diff( MV.all ) > 0 )
    % Pass: monotonic variable
else
    error('E51: the merged variable must increase monoically!')
end

%% Load dimensional information from the sample file
sample_fn = fullfile( input_dir, filelist(1).name );
info0 = ncinfo(sample_fn);

%% prepare dimensions
var_ind = FUN_struct_find_field_ind( info0.Variables, 'Name', var_name );
dim_ind = FUN_struct_find_field_ind( info0.Variables(var_ind).Dimensions, 'Name', merge_dim_name );
var_size0 =  [info0.Variables(var_ind).Dimensions.Length];
if length(var_size0) == 1
    var_size0 = [ var_size0, 1];
end

var_size1 = var_size0;
var_size1( dim_ind ) = MV.N;

is_1D = length(var_size1) == 2 && any( var_size1 == 1 );
var_size2 = var_size1;

if dim_ind == length( var_size1 ) || is_1D;
    % ok
else
    error('The merged dim must be the last dimension. Other conditions are not supported yet')
end
    
if is_1D
    %this is a 1-D array
    NX = 1 ;
else
    NX = prod(var_size2(1:end-1));
end

out_var = nan( NX, MV.N ) ;
out_sourcefile_ind = nan( 1, MV.N );

%% load/write variable
    for ii = 1:length( filelist );
        disp(['Loading from ' fullfile( input_dir, filelist(ii).name ) ])
        out_var(:, MV.ind_start(ii): MV.ind_end(ii)) = reshape( FUN_nc_varget_enhanced( fullfile( input_dir, filelist(ii).name ), var_name ), NX, [] );
        out_sourcefile_ind( MV.ind_start(ii): MV.ind_end(ii) ) = ii;
    end

%% == reshape back to original size ==
out_var = reshape( out_var, var_size1 );
