%%%%%%%%%%%%%%% spm5.m
while true
   try spm_rmpath; catch break; end     % remove spm path
end
addpath D:\spm8;                        % add spm5 path
spm;                                    % run spm5