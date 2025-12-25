function fun_disp_percent_update(percent, is_backspace)




% Prepare the new string
msg = sprintf('%06.2f%%', percent);

prevLength = length(msg);

if is_backspace
    % Print backspaces to erase the previous message
    fprintf(repmat('\b', 1, prevLength));
end

% Step 2: Print the new message
fprintf('%s', msg);

