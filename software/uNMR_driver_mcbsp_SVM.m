% uNMR driver
% YT July 2017 --
% implement mcbsp features
% clear
cd 'C:\Users\ytang12\OneDrive - Schlumberger\01_Working folder\programming-serial'
myNMR = uNMR('COM6')
% bootup diagnosis
BootupDiagnosis(pindex,myNMR);
%% FID 
infreq = 23.4268*1000000 + 4e4 - 10600; %in hertz
% infreq = 23.3368*1000000 + 4e4 - 10600; %in hertz
RD = 1e6;
TD = 500;
t90 = 25;
tune = 3500;
NA = 2;
p = pindex;

dummyscan = 0;
tic
myNMR.setNMRparameters(p.i_RD, 2.5e6); pause(0.1);
toc
[y,f,p0] = FID(infreq, RD, tune,TD,t90,NA,dummyscan,p,myNMR) %f is the frequency base and p0 the fft amplitude
%% CPMG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% new feature: set echoshape               
% echoshape = 1, record and save echoshape  
% echoshape = 0, only save echo amplitude  
% Ray Tang, 8/23/2017     
%
% new feature: set window sum (or not) 
% window sum returns 200 floating points 
% while no. of echos = 3000. Use a new variable, ws:
% ws = 1, data compression in firmware and uncompress 
% in Matlab; ws = 0, no compression
% Ray Tang, 1/30/2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TE = 400; %echo time in us
echoshape = 0;
dummyecho = 2;

ws = 0; %window sum yes/no

myNMR.setNMRparameters(p.i_ws, ws); pause(0.1);


if echoshape == 1
    TD = 7000; %only use with int16 data
    dummyecho = 0; %when recording echo shapes, set dummy echo to zero.
elseif ws == 1
    TD = 200;
else
    TD = 4300; % run into a bug when TD > 4500. Need investigation. 1/30/2018
end

NA = 4;
RD = 10e6;%for full mud
t90 = 25;
t180 = 50;
dummyscan = 0;
p = pindex;
totexpt = NA*(RD + (t90+TE/2+TD*(TE+t180)*(1+dummyecho)))/1e6/60; %total experiment time
X = sprintf('the estimated total experiment time is %d mins:',totexpt);
fprintf(X)

if ws == 1
    [y2] = CPMGacq_ws(echoshape,infreq*2,RD,TE, TD, t90,t180,NA,dummyscan,dummyecho,p,myNMR);% % for echoshape = 0
    y3=y2;
    y2c = [];
    temp = y2(1:200)./table(:);
% recover to uncompressed data
    for i=1:200
        for j = 1:table(i)
            y2c = [y2c temp(i)];
        end
    end
    clear y2; y2 = y2c'; 
else 
    [y2] = CPMGacq(echoshape,infreq*2,RD,TE, TD, t90,t180,NA,dummyscan,dummyecho,p,myNMR);% % for echoshape = 0
end

subplot(1,2,1)
if ws == 1
    time = (1:3000)*(TE+t180)*(1+dummyecho)/1e3;
else
    time = (1:TD)*(TE+t180)*(1+dummyecho)/1e3;
end
plot(time,imag(y2),'.-')
hold all
plot(time,real(y2),'.-')
hold off
xlabel('time in ms')
ylabel('echo amplitude in a.u.')
subplot(1,2,2)
semilogy(time,abs(y2)/max(abs(y2)),'r-') %this is with pts160 directly into asic

% hold on
% semilogy(time,abs(y2)/max(abs(y2)),'b-') %this is with hmc832
xlabel('time in ms')
ylabel('a.u.')
legend('HMC832 + PX570')
hold off
% T2 inversion
TE = (TE + t180)/1e6;

% y21 = y2;
% load y2
% y22 = y21 - y2
[T2,T2dist] = T2analysismicroNMR(y2',TE,dummyecho,TD)

% save y2
%% T1T2 pulse sequence, running once and invert, get calibration coefficient.
clear y

seq = 2;
[tau1list,tau2list,TD,TE,vd,NA,tau2,dummyecho] = getExpParameters_uNMR(seq);
                                                                                                                                                                                                                                 
TE = TE*1e3; %in sec
%dummyecho = 1;
%TD = 4300;
%NA = 4;
t90 = 25;
t180 = 50;
dummyscan = 0;
p = pindex;

%vd = [5e3,5e4,1e5,5e5,1e6,2e6,3e6,5e6,8e6,1e7,1.5e7]; %variable delay for T1 encoding for water
%vd = [1e3,5e3,3e4,5e4,8e4,1e5,3e5,5e5,8e5,1e6,3e6,8e6,15e6]; %variable delay for T1 encoding for mud and cream
%vd = [1e3,3e3,5e3,1e4,3e4,5e4,8e4,3e5,1e6,5e6,10e6]; %variable delay for T1 encoding for honey
vd = vd*1e3;

% runtime = NA*(sum(vd)+(t180+t90+TD*(TE+t180)*(1+dummyecho))*size(vd,2))/1e6 %total experiment time
   
RD = 10e6;

totexpt = NA*(RD*size(vd,2)+sum(vd)+(t180+t90+TD*(TE+t180)*(1+dummyecho))*size(vd,2))/1e6/60; %total experiment time
X = sprintf('the estimated total experiment time is %d in mins:',totexpt);
fprintf(X)
%
[y] = IRCPMGacq(RD, TE, TD, t90, t180, NA, dummyscan, dummyecho,vd,p,myNMR);
%
signs = sign(mean(real(y(2:5,:))))
ysign = y.*signs;
figure(99)
plot(imag(y))
xlabel('# of pts')
ylabel('echo amplitude')
% T1T2 analysis
% TE = 100;
TE = (TE + t180)/1e6; % in seconds

[T2,T1,FEst] = T1T2analysismicroNMR(y,TE,dummyecho,TD,vd)

%%
% load pp.mat
% y = pp.data;

data2c = y(:,end);
sum_echoamp = sum(sum(abs(data2c).*data2c));
% Calculate the phase factor: phase_factor = exp{i phi}, where phi is the
% echo  phase
phase_factor = sum_echoamp./abs(sum_echoamp); 
data2_phased = phase_factor' .* y(:);
data = reshape(real(data2_phased)./(mean(real(data2_phased((2+(length(vd)-1)*TD):(3+(length(vd)-1)*TD))))),TD,length(vd));


plot(data(:))

%  a = 1-data(2,1)/data(2,20)

tem2 = svdstr(seq).u1' * data' * svdstr(seq).u2;
    %%%%%%%%%%%%%% classify
FluidType = predict(SVMmachines(seq).svd,tem2(:)')
%%
% make a folder named after the data acquisition time 
c = clock;
result = strcat(num2str(c(2)),num2str(c(3)),num2str(c(4)),num2str(c(5)));
MainFolder = 'C:\Users\YTang12\OneDrive - Schlumberger\Desktop\';

CurrentFolder = [MainFolder result];
mkdir(CurrentFolder)
cd(CurrentFolder)
%%%%

pp.seq = seq; %seq used
pp.TE = TE; %in s 
pp.dummyecho = dummyecho;
pp.TD = TD;
pp.NA = NA;
pp.RD = RD;
pp.t90 = t90;
pp.t180 = t180;
pp.dummyscan = dummyscan;
pp.vd = vd; %variable delay for T1 encoding for honey
pp.data = y;
%pp.fluidtype = FluidType;
pp.T2 = T2; % for inversion
pp.T1 = T1; % for inversion
pp.FEst = FEst; % t1t2 map

save pp

%% T1T2 pulse sequence, running continuously
n = 2;
expno = 190;
seq = 2;

while n>1
    close all
    clear y pp
   % pp.seq = seq;
    folder = ['C:\Users\ytang12\OneDrive - Schlumberger\02_Reference\Data\SVM on uNMR\data\drilling fluids\' num2str(expno)];%folder 
    %seq = 3;
    [tau1list,tau2list,TD,TE,vd,NA,tau2,dummyecho] = getExpParameters_uNMR(seq);

    TE = TE*1e3; %in us
    t90 = 25;
    t180 = 50;
    dummyscan = 0;
    p = pindex;

    vd = vd*1e3; % in us
    RD = 10e6; % in us
     
    totexpt = NA*(RD*size(vd,2)+sum(vd)+(t180+t90+TD*(TE+t180)*(1+dummyecho))*size(vd,2))/1e6/60; %total experiment time
    X = sprintf('the estimated total experiment time is %d in mins:',totexpt);
    fprintf(X)
    %
    [y] = IRCPMGacq(RD, TE, TD, t90, t180, NA, dummyscan, dummyecho,vd,p,myNMR);
    
    %%%%%%%%%%%%%% T1T2 analysis
    TE = (TE + t180)/1e6; % in sec
    [T2,T1,FEst] = T1T2analysismicroNMR(y,TE,dummyecho,TD,vd)

    %%%%%%%%%%%%%% phase the data
    
    data2c = y(:,end);
    sum_echoamp = sum(sum(abs(data2c).*data2c));
    % Calculate the phase factor: phase_factor = exp{i phi}, where phi is the
    % echo  phase
    phase_factor = sum_echoamp./abs(sum_echoamp); 
    data2_phased = phase_factor' .* y(:);
    data = reshape(real(data2_phased)./(mean(real(data2_phased((2+(length(vd)-1)*TD):(3+(length(vd)-1)*TD))))),TD,length(vd));
    
    figure
    plot(data(:))
    title(['this is the ', num2str(expno), ' run'])
    
    %%%%%%%%%%%%%% data compression, prediction, seq selection

     
%     tem2 = svdstr(seq).u1' * data' * svdstr(seq).u2;
%     %%%%%%%%%%%%%% classify
%     FluidType = predict(SVMmachines(seq).svd,tem2(:)')
% 
%     seq = FluidType;
%     
    %%%%%%%%%%%%%%% save data
    mkdir(folder) %folder 
    cd(folder)
    
    pp.TE = TE; %in s 
    pp.dummyecho = dummyecho;
    pp.TD = TD;
    pp.NA = NA;
    pp.RD = RD;
    pp.t90 = t90;
    pp.t180 = t180;
    pp.dummyscan = dummyscan;
    pp.vd = vd; %variable delay for T1 encoding for honey
    pp.data = y;
   % pp.fluidtype = FluidType;
    pp.T2 = T2; % for inversion
    pp.T1 = T1; % for inversion
    pp.FEst = FEst; % t1t2 map

    save pp

    expno = expno + 1;      
    pause(60*60-totexpt*60); %acq every 
end