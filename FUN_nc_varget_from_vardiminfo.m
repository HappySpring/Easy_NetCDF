% =========================================================================
% ## This is a internal function to read data from pre-prepared
% var_dim_info
% =========================================================================

function data = FUN_nc_varget_from_vardiminfo( fn, varname, var_dim_info )
% data = FUN_nc_varget_from_vardiminfo( fn, varname, var_dim_info )
% read data from the var_dim_info prepared by other functions in this toolbox.
% V1.00 by L. Chi

% Check for non-contiguous dimensions (start is nan)
    
    loc_dim_ic = isnan([var_dim_info(:).start]) & ( [var_dim_info(:).count] > 0 ); %loc of incontinuous dimensions
    if any(loc_dim_ic)
        is_contain_incontinous_dim = true;
        ind_dim_ic = find(loc_dim_ic);                 %ind of incontinuous dimensions
        [var_dim_info(:).is_incontinuous] = deal(false);
        [var_dim_info(loc_dim_ic).is_incontinuous] = deal(true);

    else
        is_contain_incontinous_dim = false;
    end
    
    start = [var_dim_info.start];
    count = [var_dim_info.count];
    stride = ones(size(start));

    if ~is_contain_incontinous_dim
        %% 
        % =================================================================
        % All contiguous: read the whole block
        % =================================================================

        stride = ones(size(start));
        data = FUN_nc_varget_enhanced_region( fn, varname, start, count, stride );

    else
        %% 
        % =================================================================
        % read incontinuous blocks
        % =================================================================
        

        % -----------------------------------------------------------------
        % prepare each blocks to be reach
        % -----------------------------------------------------------------

        % loc_dim_ic = [var_dim_info(:).is_incontinuous]; %loc of incontinuous dimensions
        % ind_dim_ic = find(loc_dim_ic);                 %ind of incontinuous dimensions

        ndims    = length(var_dim_info);
        ndims_ic = length(ind_dim_ic);
        
        for ii = 1:length(var_dim_info)
            if var_dim_info(ii).is_incontinuous
                [tem_start, tem_counts, ~, tem_desk_ind] = FUN_group_incontinuous_indices(var_dim_info(ii).ind);
                var_dim_info(ii).ind_gstart   = tem_start-1;  % start of each continuous ind block, convert from 1-based to 0-based system.
                var_dim_info(ii).ind_gcount   = tem_counts; % count of each continuous ind block
                var_dim_info(ii).ind_desk_0 = [cellfun(@min,tem_desk_ind)]; % count of each continuous ind block
                var_dim_info(ii).ind_desk_1 = [cellfun(@max,tem_desk_ind)]; % count of each continuous ind block
            else
                % var_dim_info(ii).ind_gstart = var_dim_info(ii).start;  % start of each continuous ind block
                % var_dim_info(ii).ind_gcount = var_dim_info(ii).count; % count of each continuous ind block
                % var_dim_info(ii).ind_desk_0 = 1; % count of each continuous ind block
                % var_dim_info(ii).ind_desk_1 = var_dim_info(ii).count; % count of each continuous ind block
            end
        end
        
        cells_start  = arrayfun(@(d) d.ind_gstart, var_dim_info(loc_dim_ic), 'UniformOutput', false);
        cells_count  = arrayfun(@(d) d.ind_gcount, var_dim_info(loc_dim_ic), 'UniformOutput', false);
        cells_desk_0 = arrayfun(@(d) d.ind_desk_0, var_dim_info(loc_dim_ic), 'UniformOutput', false);
        cells_desk_1 = arrayfun(@(d) d.ind_desk_1, var_dim_info(loc_dim_ic), 'UniformOutput', false);


        % [tot_list_start{1:length(var_dim_info)}] = ndgrid(cells_start{:});
        % [tot_list_count{1:length(var_dim_info)}] = ndgrid(cells_count{:});
        % [tot_list_desk_0{1:length(var_dim_info)}] = ndgrid(cells_desk_0{:});
        % [tot_list_desk_1{1:length(var_dim_info)}] = ndgrid(cells_desk_1{:});
        
        if ndims_ic > 1
            % more than one incontinuous dimension found
            [tot_list_start{1:ndims_ic}] = ndgrid(cells_start{:});
            [tot_list_count{1:ndims_ic}] = ndgrid(cells_count{:});
            [tot_list_desk_0{1:ndims_ic}] = ndgrid(cells_desk_0{:});
            [tot_list_desk_1{1:ndims_ic}] = ndgrid(cells_desk_1{:});
        else
            % only one incontinuous dimension found. skip ngdgrid.
            tot_list_start  = cells_start;
            tot_list_count  = cells_count;
            tot_list_desk_0 = cells_desk_0;
            tot_list_desk_1 = cells_desk_1;
        end

        % -----------------------------------------------------------------
        % open & read from netcdf file 
        % -----------------------------------------------------------------

        % read path from strucutre (if applicable)
        % if isstruct( fn )
        %     if isfield( fn, 'folder' ) && isfield( fn, 'name' )
        %         fn = fullfile( fn.folder, fn.name );
        %     elseif isfield( fn, 'name' )
        %         fn = fn.name;
        %     else
        %         error('Unknown input filename format')
        %     end    
        % end

        ncid = netcdf.open(fn,'NOWRITE');
        varid = netcdf.inqVarID(ncid,varname);
        
        % ---- handle inf counts ------------------------------------------
        if any( isinf(count))
            count = FUN_nc_get_counts_from_inf( ncid, varid, count, start);
        end
        

        % ---- initial data array -----------------------------------------
        tot_size = count;
        tot_size(loc_dim_ic) = [var_dim_info(loc_dim_ic).count];
       
        data = nan([tot_size,1]);
        sub_dest = repmat({':'}, 1, ndims);

        nblocks = numel(tot_list_start{1});
        
        if ndims_ic == 1
            % single incontinuous dimension, avoid cellfun for performance
            for ii = 1:nblocks
                start_dim_ic = tot_list_start{1}(ii);
                count_dim_ic = tot_list_count{1}(ii);

                ind_dest_0   = tot_list_desk_0{1}(ii);
                ind_dest_1   = tot_list_desk_1{1}(ii);

                start(loc_dim_ic) = start_dim_ic;
                count(loc_dim_ic) = count_dim_ic;

                for jj = 1:ndims_ic
                    sub_dest{ind_dim_ic(jj)} = ind_dest_0(jj):ind_dest_1(jj);
                end

                data(sub_dest{:}) = netcdf.getVar(ncid, varid, start, count, stride );
            end

        elseif ndims_ic > 1
            % multi incontinuous dimension
            for ii = 1:nblocks
                start_dim_ic = cellfun( @(x) x(ii), tot_list_start);
                count_dim_ic = cellfun( @(x) x(ii), tot_list_count);

                ind_dest_0 = cellfun( @(x) x(ii), tot_list_desk_0);
                ind_dest_1 = cellfun( @(x) x(ii), tot_list_desk_1);

                start(loc_dim_ic) = start_dim_ic;
                count(loc_dim_ic) = count_dim_ic;

                for jj = 1:ndims_ic
                    sub_dest{ind_dim_ic(jj)} = ind_dest_0(jj):ind_dest_1(jj);
                end

                data(sub_dest{:}) = netcdf.getVar(ncid, varid, start, count, stride );

            end
        else
            error
        end
            
        % -----------------------------------------------------------------
        % Post process data
        % -----------------------------------------------------------------        

        % ---- get format -------------------------------------------------
        data_format = whos('data');
        data_format = data_format.class;
        
        % ---- handle nan & scale factor ----------------------------------
        var_info = ncinfo(fn,varname);
        Nan_loc = false( size(data) ) ;

        % If the data is single & FillValue is double, then the FillValue must be
        % converted into signle format to make sure nan can be detected correctly.
        %
        scale_factor = 1;

        for ii = 1:length(var_info.Attributes)
            if strcmp( var_info.Attributes(ii).Name, 'FillValue')
                nan_val = netcdf.getAtt(ncid,varid,'FillValue');
                eval( ['nan_val = ' data_format '(nan_val);'] );
                Nan_loc = ( Nan_loc | data == nan_val );
                clear nan_val
            elseif strcmp( var_info.Attributes(ii).Name, '_FillValue')
                nan_val = netcdf.getAtt(ncid,varid,'_FillValue');
                eval( ['nan_val = ' data_format '(nan_val);'] );
                Nan_loc = ( Nan_loc | data == nan_val );
                clear nan_val
            elseif strcmp( var_info.Attributes(ii).Name, 'missing_value')
                nan_val = netcdf.getAtt(ncid,varid,'missing_value');
                eval( ['nan_val = ' data_format '(nan_val);'] )
                Nan_loc = ( Nan_loc | data == nan_val );
                clear nan_val
            elseif strcmp( var_info.Attributes(ii).Name, 'mask_value')
                nan_val = netcdf.getAtt(ncid,varid,'mask_value');
                eval( ['nan_val = ' data_format '(nan_val);'] )
                Nan_loc = ( Nan_loc | data == nan_val );
                clear nan_val
            elseif strcmp( var_info.Attributes(ii).Name, 'scale_factor')
                scale_factor = netcdf.getAtt(ncid,varid,'scale_factor');
            end
        end
        %clear ii

        data = double(data);
        data( Nan_loc ) = nan; 
        
        data = data .* double( scale_factor );

        % ---- add offset -------------------------------------------------
         offset = 0 ;
        
         for ii = 1:length(var_info.Attributes)
            if strcmp( var_info.Attributes(ii).Name, 'add_offset')
                offset = netcdf.getAtt(ncid,varid,'add_offset');
            end
         end
    
        data = data + double( offset ) ;

        netcdf.close(ncid)

end % END OF FUNCTION
