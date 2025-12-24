function [start, count, xloc] = FUN_nc_varget_sub_genStartCount( x, xlimit )
%  [start, count, xloc] = FUN_nc_varget_sub_genStartCount( x, xlimit )
%
% Generate [start, count] for FUN_nc_varget_enhanced_region(filename,varname,start,counts,stride)
% xloc is the location of selected x based on xlimit: x(xloc);
%
% V1.44 by L. Chi
%   add support for unconstructed grids: if xlimit has more than 2 elements,
%      treat it as a list of explicit indexes (1-based) into x.
%      This allows non-contiguous reads from unconstructed grids.
%      If the elements in xlimit are not valid indices, an error is raised.
%      When xlimit is a list of explicit indices, start = nan and count > 1.
%
% V1.43 by L. Chi
%   Even if x is not monotonic, a warning message, instead of an errow, will
%      be triggered if x is monotonic within `xlimit`
%   Like v1.41, this is introduced to override some bugs in HYCOM data (e.g, exp 93.0)
% V1.42 by L. Chi
%   Return an error if xlimit(1) > xlimit(2).
% V1.41 by L. Chi
%   if x is always within xlimit, ignore the monotonic check. 
%      This is introduced to read some of HYCOM datasets. (e.g., expt_93.0) 
% V1.40 by L. Chi
%   x & xlimit will be forced as double type
% V1.30 by L. Chi
%   Add support for decresing x 
% V1.20 by L. Chi
%   Fix a but: In the older version, this function will return 
%              start = 0, count = 1, xloc = 1 when x is completely out of
%              the range defined by xlimit. 
% V1.10 by L. Chi
%   Add support for -inf, inf in xlimit
%   Add monotone check.
%
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

%%

% decide whether unconstructed grid or not 
% for unconstructed grid, xlimit may be a list of explicit indexes and it can be incontiguous
if ~isempty(xlimit) && numel(xlimit) > 2
    % unconstructed grid
    is_unsconstructed_grid = true;
else
    is_unsconstructed_grid = false;
end 

% ==========================================================================
% for unconstructed grids
% ==========================================================================
if is_unsconstructed_grid
    % If xlimit is provided as an explicit list of values (unstructured points),
    % return their locations directly so callers can handle non-contiguous reads.
    % Interpret a multi-element xlimit (>2 elements) as either a list of indices
    % (1-based integers) or as a list of axis values. For indices, use them
    % directly without tolerance. For explicit values, match by exact equality
    % (no nearest-match fallback).
    if ~isempty(xlimit) && numel(xlimit) > 2
        % candidate explicit list
        if all(xlimit == floor(xlimit)) && all(xlimit >= 1) && all(xlimit <= length(x))
            % treat xlimit as 1-based indices

            % remove nan
            tem_nanloc = isnan(xlimit);
            xlimit(tem_nanloc) = [];

            xloc = unique(xlimit(:).', 'stable');
            start = nan; % signal non-contiguous selection to callers
            count = length(xloc);
        else
            error('xlimit with more than 2 elements must be a list of valid 1-based indices into x.');
        end

    end

else
% ==========================================================================
% for normal cnodition (constructed grids)
% ==========================================================================


    % preparation: force x as double type

    x = double(x);
    xlimit = double(xlimit);

    if isempty( xlimit )
        xlimit = [-inf inf];
    end

    if xlimit(1) > xlimit(2)
    error('xlimit(2) >= xlimit(1) is required for all dimensions!') 
    end

    %
    if (  length(x) == 1  ) || all(  x(2:end)-x(1:end-1) > 0  )
        is_x_decrese = 0;
    elseif all(  x(2:end)-x(1:end-1) < 0  )
        is_x_decrese = 1;
        x = x(end:-1:1);
    else
    % the input x is not monotonic
    if all( x >= xlimit(1) & x <= xlimit(2)  )
        start = 0; % matrix begin with 0 in nc files.
        count = length(x);
        xloc = [1:length(x)];
        
        warning('x is not monotonic, however, data will still be loaded since the entire domain is within the required limit! Please be careful about the output' )
        return
    else
        
        ck_tem_ind = find( x >= xlimit(1) & x <= xlimit(2) );
        
        if all( diff(ck_tem_ind) == 1 ) 
            
            % Skip the error if the data is monotonic within the required limit.
            % This is introduced from reading HYCOM data (exp 93.0)
            
            %if all( diff( x(ck_tem_ind) ) > 0 )
            %     is_x_decrese = 0; 
            %elseif all( diff( x(ck_tem_ind) ) < 0 )
            %     is_x_decrese = 1;
            %     x = x(end:-1:1);
            %else
            %    error('Unexpected value!');
            %end
            
            if median( diff( x(ck_tem_ind) ) > 0 )
                    is_x_decrese = 0;
            
            elseif median( diff( x(ck_tem_ind) ) < 0 )
                    is_x_decrese = 1;
                    x = x(end:-1:1);
            else
                error('Unexpected value!');
            end
            
            warning(['x is not monotonic, however, it is monotonic within the inquired limit! Plase check its raw values!']);
            
        else          
            % x must be monotonic within the required limit.
            error('x must be monotonic.');
        end
    end
    end

    % Get location of start
    if isinf(xlimit(1))
        start_loc = 1;
    else
        tem = ( x - xlimit(1) ); 
        tem( tem<0 ) = nan; 
        
        if all( isnan(tem) )
            % All x is smaller than xlimit(1)
            start_loc = nan;
        else
            % at least one x >= xlimit(1)
            [~, start_loc] = min(tem);
        end
            clear tem
    end

    % Get location of end
    if isinf(xlimit(2))
        end_loc = length(x);
    else
        tem2 = ( x - xlimit(2) ); 
        tem2( tem2>0 ) = nan; 
        
        if all(isnan( tem2 ))
            % all x is larger than xlimit(2)
            end_loc = nan;
        else
            % At least one x <= xlimit(2) 
            [~, end_loc] = max(tem2);
        end
            clear tem2
    end

    % 
    if isnan( start_loc ) || isnan( end_loc )
        % x is completely out of the range defined by xlimit 
        start = nan;
        count = 0;
        xloc  = [];
    else 
        % At least one x is located in [ xlimit(1),  xlimit(2)]
        start = start_loc - 1; % matrix begin with 0 in nc files. 
        count = end_loc - start_loc + 1;
        xloc  = start_loc:end_loc;
    end


    % additional steps for decreasing x ---------------------------------------
    if is_x_decrese == 1
        start =  length(x) - end_loc  ;
        xloc  = start+1 : start+count;
    end
    % -------------------------------------------------------------------------

end

return