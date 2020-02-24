% uNMR driver
% YS Dec 2016 --
% measure circuit peak

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];

for ii=1:20000
    try
        temp(ii) = myNMR.read_temp2();
    end
   
    if length(temp)>2
        
        plot(temp,'o-')
    end
    pause(1)
    
end

avgTemp = mean(temp)
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,4)
else
    LarmorFreq = myNMR.MagnetFreq(25,4)      % room temp
    disp 'Assume room temp 25 C'
end

NA = 1;
DS = 0;
TE = 1000;
TD = 200;
p = pindex;

cap=4000;
myNMR.setNMRparameters(p.i_tuningcap, cap); pause(0.5);

%%  *******************************
% set parameters
%   *******************************

TD = 1000;
RD = 1500000;
o1 = 30000;

NA=2;
myNMR.setNMRparameters(p.i_tuningcap,4000); pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);

myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);

myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
myNMR.setNMRparameters(p.i_recgain,4);pause(0.1);

myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
disp 'parameters set'
%%
NA=4;
NMR_job = 101;
code = hex2dec('0301'); % CPMG
code = hex2dec('0101'); % run tuning command
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);

datalist=[];
phase_angle=[];
for ii=1:100
    % set freq
    myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
    myNMR.write_1register(NMR_job,code);
   pause(1)
ii

%
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x);
    datalist(:,ii) = y;
    real(y);
    imag(y);
    subplot(211)
    plot(real(y)*2.5/2^12,'rs-','markersize',1)
    hold on
    plot(imag(y)*2.5/2^12,'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    %axis([h(1:2) 0 2.5])
    xlabel('Echo time')
    
    subplot(212)
    phase_angle(ii)=atan2(imag(mean(y(30:50))),real(mean(y(30:50))));
    plot(phase_angle,'o-')
    h=axis;
    axis([h(1:2) -pi pi])
    pause(1)
    
end

%
nmrplot(datalist(:))
%% make figure
subplot(211)
title('Acq during the pulse')

subplot(212)
pdata = mean(datalist(30:50,:),1);
phase_angle=atan2(imag(pdata),real(pdata));
plot(phase_angle)
xlabel('Experiment number')
ylabel('phase in radian')

%saveas(gcf,'circuit_response_phase_jump.fig')
%saveas(gcf,'circuit_response_phase_jump.png')

%% another test : doing phase and nmr signal to see if they in sync
% Feb 28, 2017
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NA=1;
o1 = 30000;
RD = 1000000;
TD=500;
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, 15); pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);


NMR_job = 101;
code1 = hex2dec('0001'); % run FID command
code2 = hex2dec('0101'); % run tuning command

datalist=[];
fidlist=[];
phase_angle=[];
for ii=1:1000
    % set freq
    myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
        
    myNMR.setNMRparameters(p.i_na, 1); pause(0.1);
    myNMR.setNMRparameters(p.i_T90, 15); pause(0.1);
    myNMR.setNMRparameters(p.i_RD, 1000000); pause(0.1);
    myNMR.setNMRparameters(p.i_TD, 400); pause(0.1);

    myNMR.write_1register(NMR_job,code1);
   pause(1)
   ii
   
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['FID Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x);
    fidlist(:,ii) = y;
    subplot(221)
    nmrplot(y)
    pause(1)
    xlabel('acquisition time, points')
    ylabel('NMR signal')
    
    % run tuning
    myNMR.setNMRparameters(p.i_na, 4); pause(0.1);
    myNMR.write_1register(NMR_job,code2);
    pause(1)
   
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['Circuit Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x);
    datalist(:,ii) = y;
    subplot(222)
    nmrplot(y)
    xlabel('acquisition time, points')
    ylabel('Circuit pulse signal')
    
    
    subplot(223)
    nmrplot(transpose(fidlist(10,:)))
    xlabel('experiment number')
    ylabel('NMR signal at 10th pt')
    
    subplot(224)
    phase_angle(ii)=atan2(imag(mean(y(30:50))),real(mean(y(30:50))));
    plot(phase_angle,'o-')
    h=axis;
    axis([h(1:2) -pi pi])
    xlabel('experiment number')
    ylabel('rf pulse phase angle')
    
    
end

%%
    subplot(221)
    
    xlabel('acquisition time, points')
    ylabel('NMR signal')
    
    subplot(222)
    xlabel('acquisition time, points')
    ylabel('Circuit pulse signal')
    
    
    subplot(223)
    xlabel('experiment number')
    ylabel('NMR signal at 10th pt')
    
    subplot(224)
    xlabel('experiment number')
    ylabel('rf pulse phase angle')
    
    saveas(gcf,'NMR_RFphase_jump.png')
    saveas(gcf,'NMR_RFphase_jump.fig')
    
    
    
    %% check the change sync
    figure(2)
    x1=find(imag(fidlist(10,:))>2800);
    x1(1)
    x=find(phase_angle<0);
    x(1)
    xxx = (650:680);
    subplot(211)
    plot(xxx,imag(fidlist(10,xxx)))
    title('FID signal, imag')
    subplot(212)
    plot(xxx,phase_angle(xxx))
    title('RF pulse phase, radian')
    xlabel('Experiment number')
    hold off
    
    saveas(gcf,'phase_jump_closeup.png')
    