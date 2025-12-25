% V1.00 by L. Chi

close all
clear all
clc


%%

filelist = dir('*.m');


%% current folder info
fn0      = mfilename("fullpath");
[fn0_path, fn0_name, fn0_ext] = fileparts( fn0 ); 


%% Loop for each file
for ii = 1:length( filelist )

    % current file
    fn = fullfile( filelist(ii).folder, filelist(ii).name );
    [path_now ,fn1,~] = fileparts( fn );

    % all files sharing same filename in matlab searching path
    fn_search = which( fn1, '-all' );
    

    % find the first one excluding the files in the current folder
    jj_sel = 0;
    for jj = 1:length( fn_search )
        
        
        fn_test = fn_search{jj} ;
        [path_test ,~,~] = fileparts( fn_test );
        
        % check: in current folder?
        if ispc
            is_ignore = strcmpi( path_test, fn0_path );
        else
            is_ignore = strcmpi( path_test, fn0_path );
        end
        
        % same results
        if  is_ignore
            % skip 
        else
            jj_sel = jj;
            break
        end

    end

    % print and apply changes
    fprintf(' %s \n ', fn1)

    for jj = 1:length( fn_search )
        
        if jj == jj_sel
            fprintf('    ->|  %s ', fn_search{jj})
            copyfile( fn_search{jj}, fn )
            fprintf(' [Overwrite Done!] \n')

        else
            fprintf('     |  %s \n', fn_search{jj})
        end

    end

    
end