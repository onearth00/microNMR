% uNMR driver
% YS Dec 2016 --
% measure circuit peak

% uNMR parameters
% start by initializing 
clear
myNMR = uNMR('COM6')

%
% test to read the board temp
clf
subplot(2,1,1)
temp=[];
for ii=1:200
    try
        temp(ii) = myNMR.read_temp2();
    end
   
    if length(temp)>2 
        plot(temp(1,2:end),'o-')
        h=axis;
        axis([1 200 20 35])
        xlabel('number of temp readings')
        ylabel('Temp in degC')
        title('onboard temperature sensor')
        hold on
    end
    pause(0.1)
end
avgTemp = mean(temp(1,2:end))
hold off
%
% magnet 1 => M2.1
% magnet 4 => high res
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,1);
else
    LarmorFreq = myNMR.MagnetFreq(25,1)      % room temp
    disp 'Assume room temp 25 C'
end
%%
NA = 1;
DS = 0;
TE = 1000;
TD = 200;
p = pindex;
%
cap=4000;
myNMR.setNMRparameters(p.i_tuningcap, cap); pause(0.5);


%  *******************************
% set parameters
%   *******************************

TD = 1000;
RD = 1500000;
o1 = 0;

myNMR.setNMRparameters(p.i_tuningcap,4000); pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
LarmorFreq+o1
myNMR.setNMRparameters(p.i_recgain,4);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);

disp 'parameters have been set.'
% % observe RF pulses

pause(2)

disp 'Observe the RF pulse.'
disp ''

NA=4;
NMR_job = 101;

%code = hex2dec('0301'); % CPMG
code = hex2dec('0101'); % run tuning command
%code = hex2dec('0901'); % run 20 acq only. no pulse seq
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
    % set freq
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);

datalist=[];
phase_angle=[];
for ii=1:1
    myNMR.write_1register(NMR_job,code);
   pause(.5)
ii

%
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x)*2.5/2^12;
    datalist(:,ii) = y;
    real(y);
    imag(y);
    subplot(2,1,2)
    plot(real(y),'rs-','markersize',1)
    hold on
    plot(imag(y),'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    %axis([h(1:2) 0 2.5])
    xlabel('acq points (10us)')
     title('TX/RX self-diagnosis')
    
    
%     subplot(212)
%     phase_angle(ii)=atan2(imag(mean(y(30:50))),real(mean(y(30:50))));
%     plot(phase_angle,'o-')
%     h=axis;
%     axis([h(1:2) -pi pi])
%     pause(.1)
    
end

%nmrplot(datalist(:))

% get pulse amplitude
pulse_ampl = mean(datalist(30:50,:),1); % calibrate to volt.
if (abs(mean(pulse_ampl)) > 1) && (std(abs(pulse_ampl)) < 0.1)
    disp ' '
    disp 'Pulse amplitude normal.'
else
        disp ' '
    disp ('Pulse amplitude is too low or unstable.')
end
%

%% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
disp 'Try FID by freq scanning.'
disp 'Make sure sample is in the magnet !'
pause(2);
LarmorFreq = 23.0268*1000000; %in hertz
NA=1;
o1 = 0;
RD = 1000000;
TD= 1000;
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, 15); pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,8);pause(0.1);

NMR_job = 101;
code1 = hex2dec('0001'); % run FID command

fidlist=[];
fidlist0=zeros(1000,7);

o1list=(-6:0)*10000;
for ii=1:length(o1list)
    % set freq
    o1 = o1list(ii)
    myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
        
    myNMR.write_1register(NMR_job,code1);

    x=0;
    while x==0
        pause(1)
        x = myNMR.readstatus();
        
    end
    disp(['FID Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x);
    fidlist(:,ii) = y;
    subplot(211)
    nmrplot(y,0.01)
    
    xlabel('acquisition time, ms')
    ylabel('NMR signal')
    title('One-shot FID data')
    
    subplot(212)
    nmrplot(fidlist0(:),1)
    axis([0 7000 1500 3500])
    hold all
    nmrplot(fidlist(:),1)
    xlabel('acquisition points')
    ylabel('NMR signal')    
    title('frequency sweeping data')
end
hold off
%% FID
clf
code1 = hex2dec('0001'); % run FID command
o1 = -20000;

myNMR.setNMRparameters(p.i_recgain,9);pause(0.1);
myNMR.setNMRparameters(p.i_TD, 500); pause(0.1);
myNMR.setNMRparameters(p.i_na, 2); pause(0.1);
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1); pause(0.1);
myNMR.setNMRparameters(p.i_T90, 30); pause(0.1);

for ii=1:1
myNMR.write_1register(NMR_job,code1);
   pause(2)

    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['FID Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x);

    
    %
    subplot(2,1,1)
    nmrplot(y,0.01);
    xlabel('time in ms')
    ylabel('Signal amplitude')
    title('phase-cycled data, NA=2')
    
end

% CPMG
% code = hex2dec('0001'); % run FID command
code = hex2dec('0301');     % CPMG
%o1 = -20000;
TE = 3000;
TD = 3000;

myNMR.setNMRparameters(p.i_recgain,8);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_na, 1); pause(0.1);
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1); pause(0.1);
myNMR.setNMRparameters(p.i_RD, 10*1000000); pause(0.1);

myNMR.setNMRparameters(p.i_T90,25);pause(0.1);
myNMR.setNMRparameters(p.i_T180,50);pause(0.1);


myNMR.setNMRparameters(p.i_TE,TE);pause(0.1);

caplist = 4000;

fidlist = [];
for ii=1:1 %length(caplist)
    
    myNMR.setNMRparameters(p.i_tuningcap,caplist(ii) ); pause(0.1);
    myNMR.write_1register(NMR_job,code);
    
    pause(10)
    

    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['relaxation Data to transfer=',num2str(x)])
    
    y2 = myNMR.read_NMR_data(x);
    fidlist(:,ii) = y2(:);
    
    %
    subplot(2,1,2)
    nmrplot(y2,0.02);
    xlabel('time in ms')
    ylabel('Signal amplitude')
    title('One-shot relaxation experiment, 20 echos')
end
    
% %%
% y2p = reshape(y2(1:6987),51,137);
% y2p = y2p(1:50,:)    
%     
% nmrplot(y2p(:),0.01)
% 
%     xlabel('time, ms')
%     ylabel('Signal amplitude')
%     
%     hold all
%     nmrplot(y,0.01)

    
%      nmrplot(y(1:6850)+y2p(:),0.01)
 
%
% npts = 25;
%     necho = floor(2000/npts);
% echoData = reshape(y(1:npts*necho),npts,necho);
% plot(abs(echoData))
