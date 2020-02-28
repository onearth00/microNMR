% data analysis

function [T2,T1,FEst] = T1T2analysismicroNMR(datain,TE,dummy,TD,vd)
% do 1d and 2d analysis and save result in mat file.
    
tau1 = vd/1e6; %in seconds
data = datain;
[EqIndex] = find(tau1 == max(tau1));
[DataIndex] = find(tau1 < 100);

eqData = mean(data(:,EqIndex),2);
data = data(:,DataIndex);
data = eqData * ones(1,size(data,2)) - data ;

data2c = data(:);
sum_echoamp = sum(sum(abs(data2c).*data2c));
phase_factor = sum_echoamp./abs(sum_echoamp); 
data = phase_factor' .* data2c;
data = reshape(real(data),TD,length(vd));

% a = sum(eqData(1:50));
% 
% data = data .* (a' ./ norm(a));




% a = sum(eqData(1:50));
% data = data .* (a' ./ norm(a));
% 
% data = abs(data);
%%%%% clock %%%%%
initialtime = cputime;
%%%%% clock %%%%%       
 
 
%% T1 
tau1=vd(DataIndex)'/1e6;
T1 = logspace(-3,1,100);
costheta = -1;
%costheta = real(data(1,1)) ./ real(data(1,end));
%pulsecorrection = 1.06;
%K1=1/(1-costheta) - exp(-tau1 * (1./T1));
K1=exp(-tau1 * (1./T1));


%K1=(pulsecorrection - exp(-tau1 * (1./T1)))/pulsecorrection;
K1(:,end)=1;    % constant offset
[U1, S1, V1] = svds(K1, 12);

data1=data(1,:) ;
[T1spec,alpha_T1,T1fit] = FLI1d(data1,K1,0.05,U1,S1,V1);

% figure(1)
% semilogx(T1,T1spec)

 
%T2
tau2= (0+(1:length(data)))' *(1+dummy)*TE;
T2 = logspace(-3,1,100);
K2 = exp(-tau2 * (1./T2));
[U2, S2, V2] = svds(K2, 12);

data2 = data(1:end,1)';
[T2spec,alpha_T2,T2fit] = FLI1d(data2,K2,0.01,U2,S2,V2);

%2d
data2d = data;
theAlphalist = [1];
FEstlist = {};

for ii = 1:length(theAlphalist)
    %[FEst,alpha2,Fit] = FLI2d(data2d,K1,K2,theAlphalist(ii) , U1,S1,V1,U2,S2,V2);
    [FEst,alpha2,Fit] = FLI2d(data2d,K1,K2,theAlphalist(ii));
    
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

%outputfile = [datafile '_' num2str(expno) '.mat'];
%% save (outputfile)
% figure(1)
% 
 theIndex = 1;
 FEst = FEstlist{theIndex}.f;
 Fit = FEstlist{theIndex}.Fit;
% 
% subplot(321)
% hold off
% semilogx(T1,T1spec,'b-',T1,sum(FEst,1),'b-.')
% hold on
% semilogx(T2,T2spec*(1-costheta),'r-',T2,sum(FEst,2),'r.-')
% hold off
% set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
% xlabel ('T_1 (blue),T2 (red), s')
% axis tight
% % title([datafile '/' num2str(expno)])
% 
% subplot(322)
% hold off
% semilogx(tau1,data1,'o',tau1,T1fit)
% hold on
% semilogx(tau2,data2,'-',tau2,T2fit)
% hold off
% set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
% xlabel ('\tau_1,\tau_2')
% axis tight
% 
% subplot(323)
% loglog(theAlphalist,theChilist,'bo',theAlphalist,theChilist2,'rd')
% 
% subplot(324)
% hold off
% plot(mean(Fit-data2d))
% hold on
% plot(std(Fit-data2d) ./ sqrt(size(Fit,1)) ,'r-')
% hold off
% set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
% xlabel ('\tau_2 second')
% axis tight
% 
% subplot(325)
% FLIPlot2dFullT1T2(T2,T1,FEst',parula)
% 
% subplot(326)
% datadiff = data2d - Fit;
% 
% semilogy(tau2,abs(data2d(:,end)),'-',tau2,std(datadiff(:,1:end-1),1,2))
% set(gca, 'YTick', [ 1 10 1e2 1e3 1e4 1e5]);
% xlabel ('\tau_2 second')
% axis tight
% 
% figure(2)
% for ii = 1:length(theAlphalist)
%     subplot(3,2,ii)
%     FLIPlot2d(T1,T2,FEstlist{ii}.f)
%     theNoiseAmp = mean(std(data2d - FEstlist{ii}.Fit,1,2));
%     title([num2str(FEstlist{ii}.alpha) '|' num2str(theNoiseAmp) '|' num2str(FEstlist{ii}.chi)])
%     
% end
end


