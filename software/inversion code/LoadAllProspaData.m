function [M, parameters] = LoadAllProspaData(datadir,expno)
% [M, parameters] = LoadAllProspaData(datadir,expno)
%
% Read all data files within one KEA directory
% such as filename/1/data.1d, data.2d, data.3d, data.4d, and data.csv
% Read parameter file, acqu.par
% YS 111020

parameters = [];

theDataFiles = dir([datadir filesep num2str(expno)]);
M1=0;
M2=0;
M3=0;
M4=0;
M5=0;
for ii = 3:size(theDataFiles)
    thefile = theDataFiles(ii).name;
    size(thefile);
    if strcmp(thefile, 'data.1d')
        M1 = LoadProspaData([datadir filesep num2str(expno) filesep thefile]);
    end
    
    if strcmp(thefile, 'data.2d')
        M2 = LoadProspaData([datadir filesep num2str(expno) filesep thefile]);
    end
    
    if strcmp(thefile, 'data.3d')
        M3 = LoadProspaData([datadir filesep num2str(expno) filesep thefile]);
    end
    
    if strcmp(thefile, 'data.4d')
        M4 = LoadProspaData([datadir filesep num2str(expno) filesep thefile]);
    end
    
    if strcmp(thefile,'data.csv')
        M5 = load([datadir filesep num2str(expno) filesep thefile],'-ascii');
    end
end
    M = {M1 M2 M3 M4 M5};
    
%get experiment parameters and convert to numbers
fileid = fopen([datadir filesep num2str(expno) filesep 'acqu.par']);
if fileid ~= -1
    ExpPars = textscan(fileid, '%s', 'Delimiter', '\n');
    fclose(fileid);

    parameters.acqu = ExpPars{1}; 

    pp=char(ExpPars{1});
    pp = reshape(pp',1,prod(size(pp))); % format pp into a single row
    
    parameters.na=GetToken(pp,'nrScans =',1);
    parameters.dw=GetToken(pp,'bandwidthFile =',1);
    parameters.bw=GetToken(pp,'bandwidth =',1);
    parameters.tE=GetToken(pp,'echoTime =',1);
    parameters.t90=GetToken(pp,'90pulseLength =',1);
    parameters.Ampl90=GetToken(pp,'90Amplitude =',1);
    parameters.f1=GetToken(pp,'b1Freq =',1);
    parameters.pts=GetToken(pp,'nrPnts =',1);
    parameters.nchoes=GetToken(pp,'nrEchoes =',1);
    parameters.rg=GetToken(pp,'rxGain =',1);
    
    k=findstr(pp, 'experiment');
    parameters.expt = pp(k:k+62);
    
else
    disp 'Could not open acqu.par'
end

    
    
end




%%%%%%%%%%%%

function [value] = GetToken(string, matchstr, howmany)
% find the token by its name and convert to its values.
% specific for Bruker parameter files.

% Find the variable
	 k = findstr(string, matchstr);
	 
	if (~isempty(k) )
			l = length(matchstr);
            value = sscanf(string(k+l :end),'%g', howmany);
    else
        value = 0;
    end

end