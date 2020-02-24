function T2analysisOI(indirname)
% Analyze T2 data from Maran using CPMG
% Perform 1d analysis and save result in mat file.
% 
% Syntax: T2analysisOI(dirname)
% The dirname contains all data files in a T2 experiments.
% All data files are listed and one is choosen to be analyzed.
%
% The result is stored in a file with the original name appended by
% '_T2analysis.mat'.

% YS 2012, 2013
% 

if nargin == 0  % no input directory
    dirname = pwd;
else
    dirname = indirname;
end

filelist = dir([dirname filesep '*.RiDat']);
numberOffiles = length(filelist);


% show the list of files
fprintf('\r Available files\r')
for ii=1:numberOffiles
fprintf('%d: %s\r',ii, filelist(ii).name)
end

% get a file by its number:

ii = input('\r select a file for processing:')

theFILE = filelist(ii).name;

filename = [dirname filesep filelist(ii).name];
[DATA1d, echotimes, AcqParms, crdate, status] = readDRXRiDat(filename);

necho = AcqParms.App.NECH;
SI = AcqParms.App.SI;

if length(DATA1d)/AcqParms.App.SI ~= necho
    disp 'number of data points is not consistent with NECH & SI'
end

% should also check the pulse seq

data = sum(reshape(DATA1d,SI,necho),1);
data = data;
TE = (echotimes(SI+1)-echotimes(1))/10000000;

% rotate data, use all data. May be better to use only the data with
% significant siganl

normdata = sum(data)'/abs(sum(data));
data = data * normdata;

nmrplot(data,TE)

%


if isempty(data)
    fprintf(1,'No data is found. Quit.\n')
	return;
	end

data2 = real(data);
%%%%% clock %%%%%
initialtime = cputime;
%%%%% clock %%%%%    	


%T2 inversion - set up kernel and run FLI1d
tau2= [1:length(data)]'* (TE);
T2 = logspace(-4,1,100);
K2 = exp(-tau2 * (1./T2));
[U2, S2, V2] = svds(K2, 12);


[T2spec,alpha_T2,T2fit] = FLI1d(data2,K2,-2,U2,S2,V2);

semilogx(T2,T2spec,'r')
%
% run through a range of alpha
theAlphalist = [ 100 10 1 0.1 0.01 0.001];
FEstlist = {};

for ii = 1:length(theAlphalist)
    [T2spec,alpha_T2,T2fit] = FLI1d(data2,K2,theAlphalist(ii),U2,S2,V2);
    FEstlist{ii}.f = T2spec;
    FEstlist{ii}.alpha = alpha_T2.alpha;
    FEstlist{ii}.chi = alpha_T2.chi;
    FEstlist{ii}.Fit = T2fit;
    
end

for ii = 1:length(theAlphalist)
    theChilist(ii) = FEstlist{ii}.chi;
    theChilist2 (ii) = sqrt(mean(mean((data2' - FEstlist{ii}.Fit) .^ 2)));
    
end

%%%%% clock %%%%%
endtime= cputime -initialtime;
fprintf(1, 'Time spent = %d\n',endtime);
%%%%%%%%%%%%%%%%%


%
figure(1)
datafile = theFILE;


theIndex = 3;

FEst = FEstlist{theIndex}.f;
Fit = FEstlist{theIndex}.Fit;

subplot(311)
hold off
semilogx(T2,T2spec,'r-')
hold off
set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
xlabel ('T2 (red), s')
axis tight
title([datafile '/' ])

subplot(312)
hold off
hold on
semilogx(tau2,data2,'-',tau2,T2fit,'r')
semilogx([min(tau2) max(tau2)],[0 0])
hold off
set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
xlabel ('\tau_2, second, log')
axis tight

subplot(313)
loglog(theAlphalist,theChilist,'bo',theAlphalist,theChilist2,'rd')


Analysisdata = datestr(now);

outputfile = [dirname filesep theFILE '_T2analysis.mat'];
save (outputfile)
