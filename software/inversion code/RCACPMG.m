function [xdata] = RCACPMG(datain)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [data,Params] = RCACPMG(inAlpha)
%
% Process CPMG data from RCA spectrometer - Magritek. 
% Makes no normalization of data.
%
% Use: go to the data directory. Then execute the function.
% input parameter:
% inAlpha: if one input, then used for inversion. Default:-2, use t1heel method
% 
% Output:
% xdata  -- results
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
% YS Jan 2013.
%

% rawdata = datain;
% datadir = pwd;
% Params = LoadProspaParameters(datadir);
% theAlpha = -2;  % use t1heel method

if nargin == 2
    theAlpha = inAlpha;
    rawdata = datain;
    datadir = pwd;
    Params = LoadProspaParameters(datadir);
elseif nargin == 1  %put in only data
    rawdata = datain;
    datadir = pwd;
    Params = LoadProspaParameters(datadir);
    theAlpha = -2;  % use t1heel method
else
    datadir = pwd;
    Params = LoadProspaParameters(datadir);
%determine which DT2 sequence was run (and thus which kernel to use)
    if(strcmp(Params.experiment,'CPMG') || strcmp(Params.experiment,'ZL-CPMG'))
        display('Processing data from CPMG sequence...');
        kernfac = 2;
    else
        error('CPMG data not found...Is current directory correct?');
        return;
    end

    rawdata = LoadProspaData([datadir filesep 'data.2d']);
    theAlpha = -2;  % use t1heel method
end
%% define parameters 

NumT2Bins = 99;
NumDBins = 100;

T2minp = -5; T2maxp = -1; 

T2 = logspace(T2minp,T2maxp,NumT2Bins);

makedata = 0;

%% get data

% ExpTime = MExpTime*1e-6;
EchoTime = Params.echoTime*10^-6;

ExpTime =(1:Params.nrEchoes)*EchoTime*(1+Params.nrDummies);     %Normalizes the initial time of T2, so there's no extrapolation
ExpTime=ExpTime(1:end);
% rawdata = rawdata(:,:,:);
NumEchoes = Params.nrEchoes;

%% extract avg echo shape

startecho = min(NumEchoes,3); 
endecho = min(25,NumEchoes);
%weight echoes from each delay time by 
AvgEchoShape = sum(rawdata(:,startecho:endecho),2);



AvgEchoShape = AvgEchoShape/norm(AvgEchoShape);

% figure; plot(real(AvgEchoShape)); hold on;
% plot(imag(AvgEchoShape),'r--'); %check that shape makes sense

%% integrate data

IntegratedData =  (AvgEchoShape'*rawdata(:,:)).';
IntegratedData =  IntegratedData(1:end);


%exclude 1st echo
%IntegratedData = IntegratedData(2:end,:);

%normalize
%IntegratedData = 1/max(real(IntegratedData(:)))*IntegratedData;

%figure; plot(ExpTime,real(IntegratedData)); hold on; plot(ExpTime,imag(IntegratedData),'--');

% signal and noise 
theSignal = mean(real(IntegratedData(1:5)));   %Integrate data to calculate noise
theNoiseStd = mean(std(imag(IntegratedData(1:end)),0,1)); 
theSNR = theSignal./theNoiseStd;
disp(['SNR ~ ' num2str(theSNR)]);

%% define data for inversions
data1 = real(IntegratedData(1,:));
data2 = real(IntegratedData(:,1));
data2d = real(IntegratedData); 


%% 1-d inversion of kernel 2 (T_2)


K2 = exp(-ExpTime'*(1./T2) );
[U2, S2, V2] = svds(K2, 10);


 [FofT2,alpha_T2,T2fit] = FLI1d(data2.',K2,theAlpha,U2,S2,V2);

 figure; 
 subplot(121)
 semilogx(T2,FofT2);
 axis tight %check inversion 
 xlabel('T2, sec')
 ylabel(['T2 distribution, alpha=' num2str(alpha_T2.alpha)])
 title([Params.expName ', ExpNr=' num2str(Params.expNr)]);
 
subplot(122)
semilogx(ExpTime,data2,'sb',ExpTime,T2fit,'r',[min(ExpTime) max(ExpTime)],[0 0],'k')
axis tight
title(['T2 decay fitting, SNR~' num2str(theSNR)]);
 xlabel('\tau_2, sec')
 ylabel(['Echo amplitude, rxGain=' num2str(Params.rxGain) ', nrScans=' num2str(Params.nrScans)])
saveas(gcf,'T2fits');



data.RLV2= T2; 
data.FEst=FofT2;

sample_name= Params.expName;
save('CPMG_results','data','Params','sample_name');

% plotting for final figure
 figure; 
 subplot(121)
 semilogx(T2,FofT2);
 axis tight %check inversion 
 xlabel('T2, sec')
 ylabel(['T2 distribution'])
 title([Params.expName]);
 
subplot(122)
semilogx(ExpTime,data2,'sb',ExpTime,T2fit,'r',[min(ExpTime) max(ExpTime)],[0 0],'k')
axis tight
title(['T2 decay fitting' ]);
 xlabel('\tau_2, sec')
 ylabel(['Echo amplitude '])
saveas(gcf,'T2fits');

save('CPMGanalysis');

if nargout ==1
    xdata = load('CPMG_results');
end



end
