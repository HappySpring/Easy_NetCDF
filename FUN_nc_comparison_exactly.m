function is_equal = FUN_nc_comparison_exactly(file1, file2)
% is_equal = FUN_nc_comparison_exactly(file1, file2)
% check whether the two netcdf files containing exactly the same info.
%
% -------------------------------------------------------------------------
% INPUT:
%      file1, file2: names of netcdf files
% -------------------------------------------------------------------------
% OUTPUT:
%      is_equal: Return "true" if file1 is equal to file 2.
% ** NOTE **:
%      file1 is used as baseline. is_equal = true if the only differnece 
%         are that file2 contains extra attributes than file 1. 
% -------------------------------------------------------------------------
%
% ** Known problems **
%  if the order of variables or attributes changes with files, this script will not work properly

% V1.00 By L. Chi (L.Chi.Ocean@outlook.com)

%% initial

is_equal = true;

file1_info = ncinfo(file1);
file2_info = ncinfo(file2);

%% dimension
disp( [ '[' file1 ' ] vs. [' file2 ']'] )

% # of dimensions
if length(file1_info.Dimensions) == length(file2_info.Dimensions)
else
    disp(['[Dismatch] Number of Dimensions'])
end

% Details of each dimensions
for ii = 1:length( file1_info.Dimensions )
    
    if strcmpi(file1_info.Dimensions(ii).Name, file2_info.Dimensions(ii).Name) 
    else
        disp(['[Dismatch] Dimensions.name '])
        is_equal = false;
    end
    
    if (file1_info.Dimensions(ii).Length == file2_info.Dimensions(ii).Length)
    else
        disp(['[Dismatch] Dimensions.Length'])
        is_equal = false;
    end

end

%% varialbe basic

% Num of variables
if length(file1_info.Variables) == length(file2_info.Variables)
else
    disp(['[Dismatch] Num of Dimensions'])
end

% details of each variables
for ii = 1:length( file1_info.Variables )
    
    % Name
    if strcmpi(file1_info.Variables(ii).Name, file2_info.Variables(ii).Name) 
    else
        disp(['[Dismatch] Variable.name '])
        is_equal = false;
    end
    
    % Size
    if all(file1_info.Variables(ii).Size == file2_info.Variables(ii).Size)
    else
        disp(['[Dismatch] Variable.size'])
        is_equal = false;
    end

    % attributes
    for jj = 1:length( file1_info.Variables(ii).Attributes )
        if strcmpi( file1_info.Variables(ii).Attributes(jj).Name, file2_info.Variables(ii).Attributes(jj).Name ) ...
                && all( file1_info.Variables(ii).Attributes(jj).Value == file2_info.Variables(ii).Attributes(jj).Value )
        else
        disp(['[Dismatch] Variable.Attributes (' num2str(ii) ' - ' num2str(jj) ')' ])
        is_equal = false;
        end
    end
    
end

%% data
for iv =  1:length( file1_info.Variables )
   varname =  file1_info.Variables(iv).Name;
   
   % load values
   data1 = FUN_nc_varget_enhanced( file1, varname );
   data2 = FUN_nc_varget_enhanced( file2, varname );
   
   if ischar(data1(1))
       %if the valures are strings
       if all(data1(:) == data2(:)) && all( isnan(data1(:)) == isnan(data2(:)) ) 
       else
           disp(['[Dismatch] Values of ' varname ])
           is_equal = false;
       end
       
   else
       % if the values are numbers
       if nansum(abs(data1(:)-data2(:))) == 0
       else
           disp(['[Dismatch] Values of ' varname ])
           is_equal = false;
       end
       
   end
   
end
    




