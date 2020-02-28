function startExpt(obj, expNum, NS)
% 
% start an NMR experiment
% Usage:
% startExpt(obj, expNum, NS)
% expNum: experiment index
% NS : number of scans, less than 256

NMR_job = 101;
code = mod(expNum,256)*256 + mod(NS,256);

%disp(code)

obj.write_1register(NMR_job,code);