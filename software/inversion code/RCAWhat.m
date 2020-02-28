function [pp] = RCAWhat(filedir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read data from RCA spectrometer. 
% Display the parameters
% 
% function [p] = RCAWhat(filedir)
%
% If the input is empty, then use current directory.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 1
    datadir = filedir;
else    
    datadir = pwd;  
end

p = LoadProspaParameters(datadir);


fprintf(1,'expName = %s\n',p.expName)

fprintf(1,'NMR experiment = %s\n',p.experiment)

if nargout ==1
    pp = p;
end

end
