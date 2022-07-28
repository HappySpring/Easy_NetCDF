function varargout = FUN_codetool_retry( fun_hand, param, N_max_retry, pause_seconds, else_fun )
% varargout = FUN_retry( fun_hand, param, N_max_retry )
%
% Execute a command and retry if an error occurred
%
%
% INPUT:
%    fun_hand      : function handle
%    param         : parameters for fun_hand
%    N_max_retry   : max number of retry
%    pause_seconds : pause this seconds after an error. 
% 
% OUTPUT:
%    Same as the regular output from fun_hand

% V1.01 by L. Chi (L.Chi.Ocean@outlook.com)
%    Update counting strategy for retry
%    Fix a bug in handling "else_fun"
%
% V1.00 by L. Chi (L.Chi.Ocean@outlook.com)

% For debug: 
%       FUN_codetool_retry( @()reshape([1,2,3],2,2), [], 3, 1 )

%%
% =========================================================================
% # set default values
% =========================================================================

if ~exist('param','var')
    param = [];
elseif ~iscell(param) && ~isempty( param )
    param = {param};
end

if ~exist('param','var') || isempty( N_max_retry )
    N_max_retry = 10;
end

if ~exist('pause_seconds','var') || isempty( pause_seconds )
    pause_seconds = 30;
end


if ~exist('else_fun','var') || isempty( else_fun )
    else_fun = @()error(['Retry exceeds max limit! Exit!']); % Execute this if reaching max number of retry.
end

%%
% =========================================================================
% # execute the command
% =========================================================================

count_err = 0;

while count_err <= N_max_retry
    
    try
        if isempty(param)
            [varargout{1:nargout}] = feval( fun_hand ); 
        else 
            [varargout{1:nargout}] = feval( fun_hand, param{:} );         
        end
        count_err = inf;
        
    catch err_log
        fprintf('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n' );
        FUN_ErrorInfoDisp( err_log )
        
        count_err = count_err + 1;
        
        fprintf(' \n' );
        warning(['Err, retry count: ' num2str( count_err )] );
         
        if count_err >= N_max_retry %0 ">=" is adopted in case N_max_retry is set to 0.
            warning('>>>>>> Reach N_max_retry(=%i), stop <<<<<< \n', N_max_retry)
            % This will return an error message by default
            tem_n_out_elsefun = nargout(else_fun);
            
            if tem_n_out_elsefun > 0
                [varargout{1:tem_n_out_elsefun}] = else_fun();
            else
                else_fun();
            end
            
        else % sleep for a while before next try.
            
            fprintf('Wait for %.2f seconds ... \n', pause_seconds );
            pause(pause_seconds) %retry after 30 seconds
            
            fprintf('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n' );
            
        end
        
    end
end

if ~exist('varargout','var') 
    varargout = {[]};
end
            