function [] = RCADedit()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process Dedit data (DT2 on static gradient) from RCA spectrometer. Fits for first     %
% gradients and first echoes. Makes no normalization of data.%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data is in the current directory
% Results are saved in the .mat files.
% The pulse sequence: Dedit

%
% Ben Chapman, Agnes, 2010-2011
% YS 2012
% Zhixiang Luo, 20130629




%% define parameters 

NumT2Bins = 99; % defining the components in T2 and D; Use slightly different numbers so you know when it is transposed.
NumDBins = 100;

T2minp = -4; T2maxp = 1; % define the range of the inversion. T2 from 1ms to 1s.
Dminp = -8; Dmaxp = -3; % diffusion coefficient in cm^2/s 

T2 = logspace(T2minp,T2maxp,NumT2Bins);
D = logspace(Dminp,Dmaxp,NumDBins)';

Do = 2.12e-5; %diffusion coefficient Do of water in cm^2/s for 22C
Grad=86; % G/cm
makedata = 0;

%% get data

datadir = pwd;

Params = LoadProspaParameters(datadir);
%determine which DT2 sequence was run (and thus which kernel to use)
if(strcmp(Params.experiment,'Dedit_V2'))
    display('Processing data from unipolar stimulated echo D-T2 sequence...');
    kernfac = 1;
else
    error('D-T2 data not found...Is current directory correct?');
end

rawdata = LoadProspaData([datadir filesep 'data.3d']);
AcqTime = LoadProspaData([datadir filesep 'AcqTime.1d']); % number of points in one echo and the time (points times dwell time), time in us.
MExpTime = LoadProspaData([datadir filesep 'ExpTime.1d']); % number of echoes and the T2 time ( echo time times echo number). time in us.
TELArray = LoadProspaData([datadir filesep 'TELarr.1d']); % diffusion editing time (ms).
TELArray=TELArray*1e-6; % change diffusion editing time from us to s.
% TELArray = 0.95*TELArray;     % Gradient calibration on October 12th 2011

% ExpTime = MExpTime*1e-6;
ExpTime =(MExpTime - MExpTime(1) + (MExpTime(2)-MExpTime(1)))*1e-6;     % change T2 time to second. ExpTime(n)=n*echotime. Normalizes the initial time of T2, so there's no extrapolation
% rawdata = rawdata(:,:,:);
NumEchoes = length(ExpTime);
ComplexPts = length(AcqTime);
NumTEL = length(TELArray);


% delta = 2; %ms
% DELTA = 30; %ms



%gamma = 0.425e8/1e4; %%gama/2*pi
gamma = 2.67513e8/1e4; %this value for gamma is taken from the source below, in units of
%rads/(T*s), so the division by 1e4 is to convert to T to gauss.
%p. 40 of Mohr, Peter J.; Taylor, Barry N.; Newell, David B. (2008). 
%"CODATA Recommended Values of the Fundamental Physical Constants: 2006". Rev. Mod. Phys. 80: 633–730. 


%% extract avg echo shape

startecho = min(NumEchoes,3); 
endecho = min(25,NumEchoes);
%weight echoes from each delay time by 
GradWeights = reshape(sqrt(sum(sum(real(rawdata(:,startecho:endecho,:)),2).^2 +...% first sum (inner most) sum over 3-25 echoes.
    sum(imag(rawdata(:,startecho:endecho,:)),2).^2,1)),NumTEL,1); % obtain the echo intensity as function of gradient.

AvgEchoShape = reshape(sum(rawdata(:,startecho:endecho,:),2),ComplexPts,NumTEL)*...% average echo shape is complex. 
    GradWeights;
AvgEchoShape = AvgEchoShape/norm(AvgEchoShape);  %normalized

% figure; plot(real(AvgEchoShape)); hold on;
% plot(imag(AvgEchoShape),'r--'); %check that shape makes sense

%% integrate data

IntegratedData = zeros(NumEchoes,NumTEL);
for ii = 1:NumTEL
    IntegratedData(:,ii) = (AvgEchoShape'*rawdata(:,:,ii))';
end

%exclude 1st echo
IntegratedData = IntegratedData(2:end,:);
ExpTime = ExpTime(2:end);
NumEchoes = 999;

%normalize
%IntegratedData = 1/max(real(IntegratedData(:)))*IntegratedData;

figure; 
subplot(121)
plot(ExpTime*1000,real(IntegratedData(:,1:4:end))); % change time from s to ms
title('CPMG real');
subplot(122)
plot(ExpTime*1000,imag(IntegratedData(:,1:4:end)));
title(['CPMG imaginary']);
xlabel('echo time (ms)')


%% noise 
IntegratedDataSNR = 1/max(real(IntegratedData(:)))*IntegratedData;   %Integrate data to calculate noise
stdout = mean(std(imag(IntegratedDataSNR),0,2)); 

%% define data for inversions
data1 = real(IntegratedData(1,:));
data2 = real(IntegratedData(:,1));
data2d = real(IntegratedData); 
%% build some ideal data
% if(makedata)
%     idealT2 = 180e-3; %120 ms converted into seconds
%     NumIdEchoes = 1;
%     NumIdGrads = 8;
%     idealGmax = 10;
%     noisemag = 0;
% 
%     idealTau = 0%linspace(0,4*idealT2,NumIdEchoes)';
%     idealg = linspace(0,idealGmax,NumIdGrads);
% 
%     kernelsproduct = @(t,g) exp(-t/idealT2)*exp(-Do*(gamma*g*delta*1e-3)^2*kernfac*(DELTA-delta/3)*1e-3); %convert time to s
%     idealData = zeros(NumIdEchoes,NumIdGrads);
% 
%     for ii = 1:NumIdGrads
%         idealData(:,ii) = kernelsproduct(idealTau,idealg(ii));
%     end
%     NoisyIdealData = idealData + noisemag*randn(size(idealData));
%     NumTEL = NumIdGrads;
%     NumEchoes = NumIdEchoes;
%     ExpTime = idealTau;
%     TELArray = idealg;
% 
%     data1 = NoisyIdealData(1,:);
%     data2 = NoisyIdealData(:,1);
%     data2d = NoisyIdealData; 
% %figure; plot(idealTau,NoisyIdealData); %check that ideal data is right
% end

 %% lin fit to Dif data
 %%
 % 
 % $$e^{\pi i} + 1 = 0$$
 % 
 b = (Grad*gamma)^2*TELArray.^3/12; 
 pcs = polyfit(b(1:25)',log(abs(data1(1:25))),1);
 
 figure; semilogy(b,data1,'o'); hold on; plot(b,exp(b*pcs(1)+pcs(2)),'r-');
 xlabel('b value')
 title(['duffusion const cm2/s:' num2str(pcs(1))]);
 pcs(1)
saveas(gcf,'Dlinfits');
%% 1-d inversion of kernel 1 (D)

K1fun = @(b) exp(-D*b); %convert time to s
K1 = K1fun(b').'; %
[U1, S1, V1] = svds(K1, 14);

%  [FofD,alpha_T1,Dfit] = FLI1d(data1,K1,-2,U1,S1,V1);
% 
%  figure; semilogx(D,FofD) %check inversion

%% 1-d inversion of kernel 2 (T_2)

K2fun = @(t) exp(-t * (1./T2));
K2 = K2fun(ExpTime);
[U2, S2, V2] = svds(K2, 14);


% [FofT2,alpha_T2,T2fit] = FLI1d(data2.',K2,-2,U2,S2,V2);

% figure; semilogx(T2,FofT2); %check inversion 

%% 2-d inversion

AlphaLength = 5;
theAlphalist = logspace(-2,2,AlphaLength);
FEstlist = cell(AlphaLength,1); %define cell array FEstlist
theIndex = 3;

for ii = 1:length(theAlphalist) %loop through alphas and do inversion for each value
    [FEst,alpha2,Fit] = FLI2d(data2d,K1,K2,theAlphalist(ii),U1,S1,V1,U2,S2,V2);
    FEstlist{ii}.f = FEst;
    FEstlist{ii}.alpha = alpha2.alpha;
    FEstlist{ii}.chi = alpha2.chi;
    FEstlist{ii}.Fit = Fit; %combined into two loops
    FEstlist{ii}.chi2 = sqrt(mean(mean((data2d - FEstlist{ii}.Fit) .^ 2)));
end

FEst = FEstlist{theIndex}.f;
Fit = FEstlist{theIndex}.Fit;

save('DT2analysis');

% plotting routines
%% T2 fits

startgrad = 1; endgrad = min(4,NumTEL);
figure;
semilogx(ExpTime,sum(real(data2d(:,startgrad:endgrad)),2)/(endgrad-startgrad+1),'k'); hold on;
semilogx(ExpTime,sum(FEstlist{theIndex}.Fit(:,startgrad:endgrad),2)/(endgrad-startgrad+1),'r');
ylabel('signal [a.u.]'); xlim([ExpTime(1) ExpTime(end)]);
title(['T_2 Fit: signal averaged over gradients ' num2str(startgrad) ' to ' num2str(endgrad)]);
xlabel('time [s]');
% ylim([0 1]);


saveas(gcf,'T2fits');

%% D fits
b = (Grad*gamma)^2.*TELArray.^3/12;
figure; 
semilogx(b,real(sum(data2d(startecho:endecho,:)))/(endecho-startecho+1),'ko','MarkerFaceColor','k'); hold on;
semilogx(b,sum(FEstlist{theIndex}.Fit(startecho:endecho,:))/(endecho-startecho+1),'r');
ylabel('signal [a.u.]');
title(['D Fit: signal averaged over echoes ' num2str(startecho) ' to ' num2str(endecho)]); 
% ylim([0 1]);
xlabel('b=(\gamma g)^2 TEL^3/12');

saveas(gcf,'Dfits');

%% 2-d maps
% dc_alkane = 0.9e-5 * T2;  

if 0
    set(gca, 'XScale', 'log', 'YScale', 'log','FontSize',16) ; hold on;
    for ii = 1:AlphaLength
        f = (FEstlist{ii}.f).';
        figure; 
        subplot(3,3,[1 2 4 5]); %make the 2-d plot
        contour(T2,D,f,64); set(gca,'xscale','log','yscale','log'); shading interp;
        xlimz = xlim;
        hold on; plot(xlimz,Do*[1 1],'k--');
       % hold on; loglog(T2,dc_alkane,'--g','LineWidth',2)
       % dc_alkane = 5e-10/Do * x;         % alkane line (from martin's SPWLA 49, 438573U)
       % dc_alkane = (8.75e-10)/Do * x; % 'alkane' line for crude oils (chris straley)
       % dc_alkane =  (8.5e-10)/Do * x;   % 'alkane' line for Ben and Philip's %Saudi oils m2/s2


        ylabel('D [cm^2/s]'); set(gca,'XTickLabel',[]);

        ab=(log(T2(2))-log(T2(1)))*((log(D(2))-log(D(1)))*sum(f));
        normamplitT2= ab/(sum(ab));
        ac= (log(D(2))-log(D(1)))*((log(T2(2))-log(T2(1)))*sum(f'));
        normamplitD= ac/(sum(ac));


        subplot(3,3,[7 8]); %make the T-2 projection
        semilogx(T2,sum(f));
        xlabel('T_2 [s]');

        subplot(3,3,[3 6]);
        semilogy(sum(f,2),D);
        xlimz = xlim;
        hold on; plot(xlimz,Do*[1 1],'k--');
        set(gca,'YTickLabel',[]);

        subplot(3,3,9);
        axis([0 1 0 1]);
        axis off;
        text(.3,1,['\alpha = ' num2str(theAlphalist(ii))]);
        text(.3,.9,['T_{2 LM} = ' num2str(1e3*exp(sum(log(T2)*normamplitT2.')),3) ' ms']);
        text(.3,.8,['D_{LM} = ' num2str(exp(sum(log(D).'*normamplitD.')),3) ' cm^2/s']);  
        text(.3,.7,['BDelta = ' num2str(DELTA) ' ms']);  
        text(.3,.6,['ldelta = ' num2str(1e-3*Params.lDelta) ' ms']); 
        text(.3,.5,['q = ' num2str(Params.qAmp) ' G/cm']);  
        text(.3,.4,['SNR = ' num2str(1/stdout)]);


        saveas(gcf,['DT2mapAlpha' num2str(log10(theAlphalist(ii)))]);
    end
else
    figure

    FLIPlot2dFullDT2(D,T2,FEstlist{3}.f);
    saveas(gcf,['DT2mapAlpha' num2str(log10(theAlphalist(3)))]);
end 
    

data.RLV2= T2; 
data.RLV1= D;
data.FEst=(FEstlist{theIndex}.f).';
% save('data' );
params= Params;
% save('params' );
sample_name= params.expName;
% save('sample_name' );
save('DT2_results','data','params','FEstlist','sample_name');





end
