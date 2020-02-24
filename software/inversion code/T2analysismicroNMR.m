function [T2,y,tau2,T2fit] = T2analysismicroNMR(datain,TE,dummy,TD)
% Analyze T2 data from microNMR using CPMG
% Perform 1d analysis and save result in mat file.
% 
% Syntax: T2analysismicroNMR(dirname)
% The dirname folder could contain many data files listed in number.
% Select one data for import and analysis.

%DATA1d = KeaData;
DATA1d = datain;
necho = TD;
SI = 1;
% TE = Params.echoTime/1000000;
% dummy = Params.nrDummies;


% ------ CHECKING 
% fprintf('Necho=%d; SI= %d; Data length=%d\r',necho,SI,length(DATA1d))
% if length(DATA1d)/SI ~= necho
%     disp 'number of data points is not consistent with NECH & SI'
% end

% should also check the pulse seq
% fprintf('Pulse seq: %s\r', Params.experiment);

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
tau2= [1:length(data)]'* (TE*(dummy+1));
T2 = logspace(-5,0,100);
K2 = exp(-tau2 * (1./T2));
[U2, S2, V2] = svds(K2, 12);


% run through a range of alpha
%theAlphalist = [100 10 1 0.1 0.01 0.001];
theAlphalist = 0.01;

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

% figure('rend','painters','pos',[10 10 900 250])
% subplot(1,2,1)
% semilogx(T2,FEstlist{1}.f,'r')
% xlim([min(T2) max(T2)])
% ylim([0 max(FEstlist{1}.f)])
% xlabel('T_2 in seconds')
% ylabel('a.u.')
% subplot(1,2,2)
% plot(tau2,real(DATA1d),tau2,imag(DATA1d))
% xlim([0 max(tau2)])
% xlabel('time in seconds')
% ylabel('a.u.')



%%%%% clock %%%%%
endtime= cputime -initialtime;
fprintf(1, 'Time spent = %d\n',endtime);
y = FEstlist{1}.f
%%%%%%%%%%%%%%%%%

%%
% figure(2)
% datafile = '1';
% 
% 
% subplot(221)
% hold off
% semilogx(T2,T2spec,'r-')
% hold off
% set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
% xlabel ('T2 (red), s')
% axis tight
% title([datafile '- alpha=' num2str(alpha_T2.alpha) ])
% 
% subplot(222)
% 
% hold off
% semilogx(T2,T2spec,'r-'); hold on
% 
% for ii=1:length(FEstlist)
%     semilogx(T2,FEstlist{ii}.f);
% end
% hold off
% title(['alpha range: ' num2str((FEstlist{1}.alpha)) '-' num2str(FEstlist{end}.alpha)])
% xlabel('T2, second')
% 
% 
% 
% % -------- Fit and Error
% subplot(223)
%  
% semilogx(tau2,data2,'.k',tau2,T2fit,'-r')
% hold on;semilogx([min(tau2) max(tau2)],[0 0])
% hold off
% set(gca, 'XTick', [1e-5 1e-4 1e-3 1e-2 1e-1 1 10]);
% xlabel ('tau_2, second, log')
% axis tight
% 
% subplot(224)
% loglog(theAlphalist,theChilist,'bo-',theAlphalist,theChilist2,'rd-')
% title('RED: total chi-sq; Blue: cvec-Chi-sq')
% xlabel('alpha')
% ylabel('chi-sq')
% 
% 
% Analysisdata = datestr(now);
% 
% outputfile = [dirname '_T2analysis.mat'];
% %save (outputfile)
