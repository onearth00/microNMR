function [T1,y] = T1analysismicroNMR(datain,vd)
% Analyze T1 data from microNMR using IR
% 
% Syntax: T1analysismicroNMR(datain,vd)
% datain is the FID amplitude minus FID amplitude at maximum vd.
% vd is the array of encoding times.

DATA1d = datain;
necho = size(vd,2);
SI = 1;

data = sum(reshape(DATA1d,SI,necho),1);

% rotate data, use all data. May be better to use only the data with
% significant siganl

normdata = sum(data)'/abs(sum(data));
data = data * normdata;
%%


if isempty(data)
    fprintf(1,'No data is found. Stop the analysis.\n')
	return;
	end

data2 = real(data);
%%%%% clock %%%%%
initialtime = cputime;
%%%%% clock %%%%%    	


%T2 inversion - set up kernel and run FLI1d
tau2= vd';
T2 = logspace(-3,1.3,100);
K2 = exp(-tau2 * (1./T2));
[U2, S2, V2] = svds(K2, 12);


% run through a range of alpha
%theAlphalist = [100 10 1 0.1 0.01 0.001];
theAlphalist = 0.001;

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


[T2spec,alpha_T2,T2fit] = FLI1d(data2,K2,-2,U2,S2,V2);

figure('rend','painters','pos',[10 10 900 250])
subplot(1,2,1)
semilogx(T2,FEstlist{1}.f,'r')
xlim([min(T2) max(T2)])
ylim([0 max(FEstlist{1}.f)])
xlabel('T_1 in seconds')
ylabel('a.u.')
subplot(1,2,2)
semilogy(tau2,abs(DATA1d),'o')
xlabel('time in seconds')
ylabel('a.u.')

%

%%%%% clock %%%%%
endtime= cputime -initialtime;
fprintf(1, 'Time spent = %d\n',endtime);
y = FEstlist{1}.f
%%%%%%%%%%%%%%%%%
