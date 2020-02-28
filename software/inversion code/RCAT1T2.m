function [] = RCAT1T2(data2)
%
% function [] = RCAT1T2()
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process T1T2 data from RCA spectrometer. Fits for first echoes%
% and first waiting times. Makes no normalization of data.      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Use current data directory
% 

%
% Ben, Agnes. 
% YS 2012
%

NumT1Bins = 99;
NumT2Bins = 100;


T1minp = -5; T1maxp = 0; 
T2minp = -5; T2maxp = 0; 

T1 = logspace(T1minp,T1maxp,NumT1Bins);
T2 = logspace(T2minp,T2maxp,NumT2Bins);
noisemag = .08;
%% get data

datadir = pwd;

Params = LoadProspaParameters(datadir);
%rawdata = LoadProspaData([datadir filesep 'data.3d']);
rawdata = data2;
acqtime = LoadProspaData([datadir filesep 'acqtime.1d']);
timeexp = LoadProspaData([datadir filesep 'exp.1d']);
time1= LoadProspaData([datadir filesep 'TE1arr.1d']);

% ExpTime = timeexp*1e-6;
ExpTime =(timeexp - timeexp(1) + (timeexp(2)-timeexp(1)))*1e-6;     %Normalizes the initial time of T2, so there's no extrapolation
AcqTime = acqtime*1e-3;
time1 = time1*1e-6;

NumEchoes = length(ExpTime);
ComplexPts = length(AcqTime);
NumT1Times = length(time1);
NumLongDelays = round(NumT1Times/10);
NumDelayTimes = NumT1Times-NumLongDelays;

KeaData = rawdata; %reshape data

%% get average echo shape
%extract and average fully polarized data
FPdata = 1/(NumLongDelays)*...
    sum(KeaData(:,:,(NumDelayTimes+1):NumT1Times),3); 

%subtract fully polarized data from partially polarized data
CorrectedData = KeaData(:,:,1:NumDelayTimes) - repmat(FPdata,[1,1,NumDelayTimes]);

startecho = 2; endecho = min(25,NumEchoes);

%weight echoes from each delay time by 
DelayTimeWeights = reshape(sqrt(sum(sum(real(CorrectedData(:,startecho:endecho,:)),2).^2 +...
    sum(imag(CorrectedData(:,startecho:endecho,:)),2).^2,1)),NumDelayTimes,1);

AvgEchoShape = reshape(sum(CorrectedData(:,startecho:endecho,:),2),ComplexPts,NumDelayTimes)*...
    DelayTimeWeights;
AvgEchoShape = AvgEchoShape/norm(AvgEchoShape);

%ask what this does...
Shapes  = reshape(sum(CorrectedData(:,startecho:endecho,:),2),ComplexPts,NumDelayTimes)...
    .*sum(AvgEchoShape)';
%% extract amplitude for each echo and normalize

IntegratedData = zeros(NumEchoes,NumDelayTimes);
for ii = 1:NumDelayTimes
    IntegratedData(:,ii) = (AvgEchoShape'*CorrectedData(:,:,ii))';
end
tempdata = IntegratedData;

MaxSig = max(max(real(tempdata)));
NormIntegratedData = 1/MaxSig*tempdata;

%% estimate noise
% std deviation of out of phase channel.
stdout = mean(std(imag(NormIntegratedData),0,2));  

%% check raw echoes
plotinds = round(linspace(1,NumDelayTimes,6));
figure; 
for ii = 1:6
    subplot(3,2,ii); pcolor(ExpTime,AcqTime,real(CorrectedData(:,:,plotinds(ii)))); shading flat;
    set(gca,'TickDir','out');
    if ii > 4
        xlabel('Expt Time Axis [s]'); 
    end
    if mod(ii,2)
        ylabel('Acquisition Time Axis [{\mu}s]');
    end
end

saveas(gcf,'RawData');
%% check echo shapes
SuperEchoes = squeeze(sum(repmat(max(real(CorrectedData)),ComplexPts,1).*CorrectedData,2));
figure; plot(AcqTime,real(SuperEchoes(:,:))); hold on;
plot(AcqTime,imag(SuperEchoes(:,plotinds)),'--'); hold on;
plot(AcqTime,real(sum(FPdata.*repmat(max(real(FPdata)),ComplexPts,1),2)),'k') %%% why is there a minus in front of real (sum....
xlabel('Acquisition Time Axis [{\mu}s]'); ylabel('Signal from Summed Echoes [a.u.]');
legend(num2str(time1(plotinds)));
%saveas(gcf,'SuperEchoes');

maxsig = max(max(real(SuperEchoes)));
ScaledSuperEchoes = repmat(maxsig./max(real(SuperEchoes)),ComplexPts,1)...
    .*real(SuperEchoes);

figure; plot(AcqTime,ScaledSuperEchoes(:,plotinds)); 
hold on; plot(AcqTime,maxsig/max(real(AvgEchoShape))*AvgEchoShape,'k--'); %plot avg. echo shape
xlabel('Acquisition Time Axis [{\mu}s]'); ylabel('Signal from Summed Echoes [a.u.]');
legend(num2str(time1(plotinds)));
%saveas(gcf,'ScaledSuperEchoes');
%% display raw data as decay curves
data2d = real(IntegratedData);
T1spc = 1; tauspc = 1;
scfactors = repmat(1./mean(data2d(1:endecho,:)),NumEchoes,1).*data2d;
figure; plot(ExpTime(1:tauspc:end),data2d(1:tauspc:end,1:T1spc:end));
xlabel('Time [s]'); ylabel('Magnetization [a.u. where M{_{0}} = 1]'); 
title('Decay Curves for Different TE1, in ms');
legend(num2str(round(1e3*time1(1:T1spc:end))));
% xlim([0 ExpTime(end)]); ylim([0 1]);
saveas(gcf,'DecayCurves');

% figure; semilogy(ExpTime(1:tauspc:end),data2d(1:tauspc:end,1:T1spc:end));
% xlabel('Time [s]'); ylabel('Magnetization [a.u. where M{_{0}} = 1]'); 
% title('Normalized Decay Curves for Different TE1, in ms');
% legend(num2str(round(1e3*time1(1:T1spc:end))));
% xlim([0 ExpTime(end)]); ylim([0 1]);
% saveas(gcf,'LogDecayCurves');

%% building ideal data
% 
% idealT2 = 180e-3; %180 ms converted into seconds
% idealT1 = 190e-3;
% idealDataFun = @(t,time1) exp(-1/idealT2*t).*exp(-1/idealT1*time1);
% idealData = zeros(NumEchoes,NumDelayTimes);
% for ii = 1:NumDelayTimes
%     idealData(:,ii) = idealDataFun(ExpTime,time1(ii));
% end
% NoisyIdealData = idealData + noisemag*randn(size(idealData));

%% 1-d inversion of kernel 1 (T1)
T1 = logspace(T1minp,T1maxp,NumT1Bins);
K1=exp(- time1(1:NumDelayTimes) * (1./T1));
[U1, S1, V1] = svds(K1, 14);

% data1=real(NormIntegratedData(2,:));
% % data1=real(NoisyIdealData(5,:));
% [FofT1,alpha_T1,T1fit] = FLI1d(data1,K1,-2,U1,S1,V1);
% figure; semilogx(T1,FofT1);
% xlabel('T1 [s]'); ylabel('Signal [a.u.]'); 
% title('1D inversion of T1');

%% 1-d inversion of kernel 2 (T_2)

T2 = logspace(T2minp,T2maxp,NumT2Bins);
K2 = exp(- ExpTime * (1./T2));
[U2, S2, V2] = svds(K2, 14);

% data2 = real(NormIntegratedData(:,1)).';
% [FofT2,alpha_T2,T2fit] = FLI1d(data2,K2,-2,U2,S2,V2);
% figure; subplot(211); plot(ExpTime,data2,'o',ExpTime,T2fit,'r'); subplot(212); semilogx(T2,FofT2);
% xlabel('T2 [s]'); ylabel('Signal [a.u.]'); 
% title('1D inversion of T2');

%% 2d inversion
data2d = real(IntegratedData); %make 2d dataset
AlphaLength = 6;
theAlphalist = [ 100 10 1 0.1 0.01 0.001]; %generate list of alphas
FEstlist = cell(AlphaLength,1); %define cell array FEstlist
theChilist = zeros(AlphaLength,1);
theChilist2 = theChilist;

for ii = 1:length(theAlphalist) %loop through alphas and do inversion for each value
    [FEst,alpha2,Fit] = FLI2d(data2d,K1,K2,theAlphalist(ii),U1,S1,V1,U2,S2,V2);
    FEstlist{ii}.f = FEst;
    FEstlist{ii}.alpha = alpha2.alpha;
    FEstlist{ii}.chi = alpha2.chi;
    FEstlist{ii}.Fit = Fit; %combined into two loops
    theChilist(ii) = FEstlist{ii}.chi;
    theChilist2 (ii) = sqrt(mean(mean((data2d - FEstlist{ii}.Fit) .^ 2)));
end

theIndex = find(theAlphalist==10); %choose alpha index to plot
FEst = FEstlist{theIndex}.f;

save('T1T2analysis');

data.RLV2= T2; 
data.RLV1= T1;
data.FEst=(FEstlist{theIndex}.f).';
% save('data' );
params= Params;
% save('params' );
sample_name= params.expName;
% save('sample_name' );
save('T1T2_results','data','params','FEstlist','sample_name');


%% compare T2 fits
startitime = 1;
enditime = 20;

figure;
semilogx(ExpTime,real(sum(IntegratedData(:,startitime:enditime),2)),'k'); hold on;
semilogx(ExpTime,sum(FEstlist{theIndex}.Fit(:,startitime:enditime),2),'r');
ylabel('signal [a.u.]'); xlim([ExpTime(1) ExpTime(end)]);
title(['T_2 fits for inversion times ' num2str(startitime) ' through ' num2str(enditime)]);
xlabel('time [s]');

saveas(gcf,'T2fits');
%% T1 fits
startecho = min(3,NumEchoes); endecho = min(25,NumEchoes);

figure;
semilogx(time1(1:NumDelayTimes),real(sum(IntegratedData(startecho:endecho,:))),'ko','MarkerFaceColor','k'); hold on;
semilogx(time1(1:NumDelayTimes),sum(FEstlist{theIndex}.Fit(startecho:endecho,:)),'r');
ylabel('signal [a.u.]');
title(['T_1 fits for echoes ' num2str(startecho) ' through ' num2str(endecho)]);
xlabel('delay time [s]');
saveas(gcf,'T1fits');


%% 2-d maps
if 0
    for ii = 1:AlphaLength
        f = (FEstlist{ii}.f).';
        figure; 
        subplot(3,3,[1 2 4 5]); %make the 2-d plot
        contour(T2,T1,f,64); set(gca,'xscale','log','yscale','log'); shading interp;
        ylabel('T_1 [s]'); set(gca,'XTickLabel',[]);

        ab=(log(T2(2))-log(T2(1)))*((log(T1(2))-log(T1(1)))*sum(f));
        normamplitT2= ab/(sum(ab));
        ac= (log(T1(2))-log(T1(1)))*((log(T2(2))-log(T2(1)))*sum(f'));
        normamplitT1= ac/(sum(ac));

        h = line([min(T2) max(T2)], [min(T1) max(T1)]);
        set(h, 'Color', 'k', 'LineStyle', '--');
        h = line([min(T2) max(T2)], [2*min(T1) 2*max(T1)]);
        set(h, 'Color', 'r', 'LineStyle', '--');


        subplot(3,3,[7 8]); %make the T-2 projection
        semilogx(T2,sum(f));
        xlabel('T_2 [s]');

        subplot(3,3,[3 6]);
        semilogy(sum(f,2),T1);
        set(gca,'YTickLabel',[]);

        subplot(3,3,9);
        axis([0 1 0 1]);
        axis off;
        text(.3,1,['\alpha = ' num2str(theAlphalist(ii))]);
        text(.3,.85,['T_{2 LM} = ' num2str(1e3*exp(sum(log(T2)*normamplitT2.')),3) ' ms']);
        text(.3,.65,['T_1_{LM} = ' num2str(1e3*exp(sum(log(T1)*normamplitT1.')),3) ' ms']);    
        text(.3,.5,['SNR = ' num2str(1/stdout)]);

        saveas(gcf,['T1T2mapAlpha' num2str(log10(theAlphalist(ii)))]);
        pause
    end

else
    figure

    FLIPlot2dFullT1T2(T1,T2,FEstlist{3}.f);
    saveas(gcf,['T1T2mapAlpha' num2str(log10(theAlphalist(3)))]);
end

end