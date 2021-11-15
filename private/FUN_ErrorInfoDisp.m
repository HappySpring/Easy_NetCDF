function FUN_ErrorInfoDisp( errinfo )
% disp error information from "try ... catch" 
% By L Chi

    disp(['Error Message: ' errinfo.message])
    disp(['From: ' errinfo.identifier])
    disp([' '])

for ii = 1: length(errinfo.stack)
    disp([ 'err at line: ' num2str(errinfo.stack(ii).line) '; (file: ' errinfo.stack(ii).file ')'])
    disp(errinfo.message)
end