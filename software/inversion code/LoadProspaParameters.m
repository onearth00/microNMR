function [parameters] = LoadProspaParameters(parpath)

% function [parameters] = LoadProspaParameters(parpath)
%
% A function for loading in a *.par file from Prospa into Matlab.
%
% The stucutre 'parameters' contains fields with the same name as the .par
% file with the exception of name that start with a number, for example
% '180Amplitude' becomes 'Amplitude180'.
%
% parpath can either be relative or absolute, and can either be the name of
% the file directly (including the .par extension) or a directory. If the directory
% contains only one .par file, that particular file is loaded. If the
% directory contains multiple .par files, no file is loaded and a list of
% available files is printed in the command line. In this case the file
% name must be given directly.
%
% If no input arguments are specified the current working directory is
% used.
%
%
%  USAGE
%
% >> parameters = LoadProspaParameters('d:\data\1')
% parameters = 
%           saveData: 'true'
%           incExpNr: 'no'
%              expNr: 1
%            expName: 'LongEcho'
%      dataDirectory: 'D:\MOLE 081023'
%          dispRange: 400
%            freqMag: 'no'
%     showFreqDomain: 'yes'
%            timeMag: 'no'
%         filterType: 'sinebellsquared'
%             filter: 'no'
%            acqTime: 0.26214
%      usePhaseCycle: 'yes'
%         accumulate: 'yes'
%          bandwidth: 488.28
%            nrScans: 4
%      bandwidthFile: 2.048
%             nrPnts: 128
%            rxPhase: 106
%             rxGain: 40
%           echoTime: 400
%        pulseLength: 16.2
%       Amplitude180: -10
%        Amplitude90: -16
%              nrExp: 5000
%            repTime: 2500
%             b1Freq: 5.116
%           position: [929 902]
%         experiment: 'stabilityecho'
%         windowSize: 'small'
%
% (c) magritek 2010 
%
% Mark Hunter 24/06/2010



parameters = [];

%if there are no input parameters use the current working directory
if nargin == 0;
    w = what;
    parpath = w(1).path;
end

if isempty(parpath)
        w = what;
    parpath = w(1).path;
end
    
%check to see if data path is 
f = dir(parpath);

[m,n] = size(f);

if m == 0
    str = ['''' parpath ''' does not exist'];
    error(str);
end
    

%=============loading the parameter file



if f(1).isdir
    %datapath is a directory test to see if there is a .par file


    for i = 1:1:length(f)
        if length(f(i).name)>4
            i;
            testpar(i) = sum( '.par' == f(i).name((length(f(i).name)-3):length(f(i).name)) ) == 4;
   
        end
    end

    if sum(testpar) > 1
        II = find(testpar);
        parfname = f(II(1)).name;
        str = ['More than one .par file in ''' parpath ''''];
        disp(str)
        
        for j = 1:1:length(II)
        str = f(II(j)).name;
        disp(str);
        end
        disp('no parameter file loaded')
        return
    end

    if sum(testpar) == 1
        II = find(testpar);
        parfname = f(II(1)).name;
    end
    
    if sum(testpar) == 0
        str = ['There is no .par file in ''' parpath ''''];
        error(str)
    end
    
    %parpath_and_fname = [parpath '\' parfname];
    parpath_and_fname = [parpath filesep parfname]; % YS 2012.1
else
    parpath_and_fname = parpath;

end






%loading the parameter file
parameters = [];
if ~isempty(parpath_and_fname)

fid = fopen(parpath_and_fname,'r','ieee-le'); %YS 2012.1 add ieee-le

if fid == -1;    
    str = ['Cannot open file ''' parpath_and_fname ''''];
    error(str);
end
    

str = fgetl(fid);

while str~=-1
    
    %need to replace " with '
    str(find(str == '"')) = '''';

    %need to rename variables that start with a number
    k = 1;
    while ~isempty(str2num(str(k)))&(str2num(str(k))~=1i)
        k = k+1;
    end

    equalI = find(str == '=');
    
    if k >1
    str = [str(k:equalI-2) str(1:k-1) str(equalI-1:length(str))];
    end
    
    %load the data into a strucure
    str2 = ['parameters.' str ';'];
    try
    eval(str2);
    catch
        str3 = ['unable to process .par entry ''' str ''''];
        error(str3)
    end
    str = fgetl(fid);
end

fclose(fid);

end