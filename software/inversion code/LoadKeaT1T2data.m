function [data,TE1times,Params] = LoadKeaT1T2data(datadirectory, TE1filename)
%This function is used to load prospa data located in the input
%directory DATADIRECTORY which correspond to CPMG decays with diffusion
%editing times in the list TE1FILENAME.  The first folder in DATADIRECTORY
%corresponds to the dataset collected with a delay time equal to the first
%element in TE1FILENAME.  The data reading is done by LoadProspaData.m, a
%script provided by Magritek.  Ben Chapman 9/13/10

%OUTPUTS: 

%DATA has dimensions NumEchoes x 3 x NumTE1times.  First column is
%the acquisition time points, second column is the signal, third is noise
%channel.

%TE1times is a 1-d array that lists the diffusion editing times


%cd into location of TE1 text file
%cd D:\DOCUMENTS\AsphalteneProject\KEAdata

% YS nov 10, 2010
whereweare = pwd; % remember current directory
%cd(datadirectory);

%get experiment parameters
fileid = fopen([datadirectory filesep 'acqu.par']);
ExpPars = textscan(fileid, '%s', 'Delimiter', '\n');
Params = ExpPars{1}; 
fclose(fileid);

%Get TE1 times
fileid = fopen([datadirectory filesep TE1filename]);
if fileid ~= -1
    TE1timesstrct = textscan(fileid,'%f');
    fclose(fileid);
    TE1times = TE1timesstrct{1};
    NumTE1times = length(TE1times);
else
    TE1times = 0;
    NumTE1times = 1;
    disp 'No list of the delay time array'
end

%Get experimental data
%firstdecay = LoadProspaData([datadirectory filesep num2str(1)]); %Get data from 1st decay
firstdecay = LoadProspaData([datadirectory filesep 'data.3d']); %Get data from 1st decay
NumEchoes = length(firstdecay); %Determine # of echoes
%data = zeros(NumEchoes,3,NumTE1times); %allocate memory for remaining decays
data = squeeze(sum(firstdecay,1)); %record 1st decay

% for ii=2:NumTE1times %loop through remaining decays 
%     data(:,:,ii) = LoadProspaData([datadirectory filesep num2str(ii)]); %and record data
% end


acqtime = LoadProspaData([datadirectory filesep 'acqtime.1d']);
timeexp = LoadProspaData([datadirectory filesep 'exp.1d']);
time1= LoadProspaData([datadirectory filesep  'TE1arr.1d']);
if TE1times == 0
    TE1times = time1;
end

end