function [data,Params] = LoadKeaT2data(datadirectory)
%This function is used to load prospa data located in the input
%directory DATADIRECTORY which correspond to CPMG decays data.  
%
% OUTPUTS: CPMG data and Parameters,
% The echo shape is summed to give the amplitude.


% YS Aug 31, 2012

%get experiment parameters
Params=LoadProspaParameters(datadirectory);

%Get experimental data
firstdecay = LoadProspaData([datadirectory filesep 'data.2d']); %Get data from 1st decay

data = squeeze(sum(firstdecay,1)); %FLAT filter: sum the echo shape

% 
% acqtime = LoadProspaData([datadirectory filesep 'acqtime.1d']);
% timeexp = LoadProspaData([datadirectory filesep 'exp.1d']);


end