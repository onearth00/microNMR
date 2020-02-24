function T1T2analysisOI(indirname)
% Analyze T1T2 data from Maran using IRCPMG
% Perform 1d and 2d analysis and save result in mat file.
% 
% Syntax: T1T2analysisOI(dirname)
% The directory (dirname) should contain all data files in a T1T2 experiments.
% The recovery time is named D1.

%
% YS 2012, 2013
% 

if nargin == 0  % no input directory
    dirname = pwd;
else
    dirname = indirname;
end

[DATA2d,pp] = readOIT1T2set( dirname);

if isempty(DATA2d) || isempty(pp)
    fprintf(1,'No data is found. Quit.\n')
	return;
	end
%	
% find the longest tau times and assume they are equilibrium
data2d = DATA2d;

tau1 = pp.Tau1list;
[EqIndex] = find(tau1 == max(tau1));


eqData = mean(data2d(:,EqIndex),2);
data2d = data2d(:,:);
data2d = eqData * ones(1,size(data2d,2)) - data2d ;

data = real(data2d);
%%%%% clock %%%%%
initialtime = cputime;
%%%%% clock %%%%%    	


% T1 90 points
tau1=pp.Tau1list;
T1 = logspace(-3.5,1,90);

K1=exp(-tau1 * (1./T1));

%K1(:,end)=1;    % constant offset
[U1, S1, V1] = svds(K1, 12);

data1=data(1,:) ;
[T1spec,alpha_T1,T1fit] = FLI1d(data1,K1,0.01,U1,S1,V1);

figure(1)
semilogx(T1,T1spec)


%T2
tau2= [1:length(data(:,10))]'* (pp.EchoTime(2)-pp.EchoTime(1));
T2 = logspace(-3.5,1,100);
K2 = exp(-tau2 * (1./T2));
[U2, S2, V2] = svds(K2, 12);

data2 = data(1:end,2)';
[T2spec,alpha_T2,T2fit] = FLI1d(data2,K2,0.01,U2,S2,V2);
hold on
semilogx(T2,T2spec,'r')
%%
%2d
data2d = data;
theAlphalist = [ 100 10 1 0.1 0.01 0.001];
FEstlist = {};

for ii = 1:length(theAlphalist)
    [FEst,alpha2,Fit] = FLI2d(data2d,K1,K2,theAlphalist(ii) , U1,S1,V1,U2,S2,V2);
    FEstlist{ii}.f = FEst;
    FEstlist{ii}.alpha = alpha2.alpha;
    FEstlist{ii}.chi = alpha2.chi;
    FEstlist{ii}.Fit = Fit;
    
end

for ii = 1:length(theAlphalist)
    theChilist(ii) = FEstlist{ii}.chi;
    theChilist2 (ii) = sqrt(mean(mean((data2d - FEstlist{ii}.Fit) .^ 2)));
    
end

%%%%% clock %%%%%
endtime= cputime -initialtime;
fprintf(1, 'Time spent = %d\n',endtime);
%%%%%%%%%%%%%%%%%



figure(1)
datafile = dirname;


theIndex = 3;
FEst = FEstlist{theIndex}.f;
Fit = FEstlist{theIndex}.Fit;

subplot(321)
hold off
semilogx(T1,T1spec,'b-',T1,sum(FEst,1),'b-.')
hold on
semilogx(T2,T2spec,'r-',T2,sum(FEst,2),'r.-')
hold off
set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
xlabel ('T_1 (blue),T2 (red), s')
axis tight
title([datafile '/' ])

subplot(322)
hold off
semilogx(tau1,data1,'o',tau1,T1fit)
hold on
semilogx(tau2,data2,'-',tau2,T2fit)
hold off
set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
xlabel ('\tau_1,\tau_2')
axis tight

subplot(323)
loglog(theAlphalist,theChilist,'bo',theAlphalist,theChilist2,'rd')

subplot(324)
hold off
plot(mean(Fit-data2d))
hold on
plot(std(Fit-data2d) ./ sqrt(size(Fit,1)) ,'r-')
hold off
set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
xlabel ('\tau_1 second')
axis tight


subplot(325)
FLIPlot2dT1T2(T1,T2,FEst)

subplot(326)
datadiff = data2d - Fit;
semilogy(tau2,abs(data2d(:,end)),'-',tau2,std(datadiff(:,1:end-1),1,2))
set(gca, 'YTick', [ 1 10 1e2 1e3 1e4 1e5]);
xlabel ('\tau_2 second')
axis tight

figure(2)
for ii = 1:length(theAlphalist)
	subplot(2,3,ii)
	FLIPlot2dT1T2(T1,T2,FEstlist{ii}.f)
	theNoiseAmp = mean(std(data2d - FEstlist{ii}.Fit,1,2));
	title([num2str(FEstlist{ii}.alpha) '|' num2str(theNoiseAmp) '|' num2str(FEstlist{ii}.chi)])
	
end

Analysisdata = datestr(now);

outputfile = [dirname '_T1T2analysis.mat'];
save (outputfile)
