% test of uNMR
% for temp

% note: nov 2019 YS. matlab 2014 ver does not seem to work.
%

clear

addpath('~/Work/MyAppSupportFiles/matlab_help/uNMRdriver_current');


% uNMR driver
% YT July 2017 --
% implement mcbsp features
% bug fixed, 2019 nov, YS
% uNMR.m, init_serial.m, 


% to see the list of serial ports
% x = seriallist

if ispc
% PC serial ports are identified by 'COM1', 'COM2', etc
% COM6 for the laptop near the oven.
portName = 'COM6';
end

if ismac
% for mac, use x = seriallist to look for serial ports
    portName = '/dev/cu.usbserial-FT0GEBSB';
end

myNMR = uNMR(portName);
%

if myNMR.serial_port.Status(1:4) == 'clos'
    disp 'Serial port does not open. Return'
    myNMR.serial_port
    return;
else
    disp 'Serial port is open. Continue'
end
%%
% bootup diagnosis
figure(1)
%
% BootupDiagnosis(pindex,myNMR);
p = pindex;
clf
subplot(2,1,1)
temp=[];
for ii=1:50
    try
        temp(ii) = myNMR.read_temp2();
    end
   
    if length(temp)>2 
        plot(temp(1,2:end),'o-')
        h=axis;
   %     axis([1 200 20 35])
        xlabel('number of temp readings')
        ylabel('Temp in degC')
        title('onboard temperature sensor')
        hold on
    end
    pause(0.1)
end
avgTemp = mean(temp(1,2:end))
hold off
%%
% magnet 1 => M2.1
% magnet 4 => high res
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,3);
    
else
    LarmorFreq = myNMR.MagnetFreq(25,1)      % room temp
    disp 'Assume room temp 25 C'
end
DS = 0;
%  *******************************
% set parameters
%   *******************************

NA = 2;
TD = 1000;
RD = 2e6;
o1 = 1e6;

myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
LarmorFreq+o1
myNMR.setNMRparameters(p.i_recgain,3);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_tuningcap, 4000); pause(0.1);

disp 'parameters have been set.'
% observe RF pulses
pause(2)

disp ' ---------------------- '
disp 'Observe the RF pulse.'
disp ' ---------------------- '

    phase = [];
    timeaxis = [];
    temp = [];
tic;
t1=toc;
ii=1;
while (toc < 1) 
    % ------- get temp from onboard sensor
    try
        temp(ii) = myNMR.read_temp2();
    end
    t1 = toc;
    timeaxis(ii) = t1;

    % ------- Start TX/RX self test
    myNMR.startExpt(5,1);   % 5 is tuning

    x=0;
    while x==0
        pause(1);
        x = myNMR.readstatus();      
    end
    disp(['Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x)*2.5/2^12;
    y1 = mean(y(25:45));
    phase(ii)  = y1;

    % --------- END of self test

    if(t1>3600)
        xunit = 3600;
    else
        xunit = 1;
    end
    
    ii=ii+1;
        
    figure(1)
    subplot(211)
    if length(temp)>2 
        yyaxis left
        plot(timeaxis/xunit,temp,'o-')
        h=axis;
        %axis([h(1:2) 20 35])

        ylabel('Temp in degC')
        
        yyaxis right
        plot(timeaxis/xunit,real(phase),'bs-')
        hold on
        plot(timeaxis/xunit,imag(phase),'rs-')
        hold off
        ylabel('phase, rad')
        
        title('onboard temperature sensor')
        
    end
    
    if t1>3600
                xlabel('time of readings, hr')
    else
                xlabel('time of readings, s')
    end
    
    pause(0.5)
    
    subplot(2,1,2)
    plot(real(y),'rs-','markersize',1)
    hold on
    plot(imag(y),'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    axis([h(1:2) -1 1])
    xlabel('acq points (10us)')
    title(['TX/RX self-diagnosis : ' num2str(ii)])    
end

toc


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% try NOE1dFID

showAll = 1;    % show all messages

HLarm = 42.57e6;
FLarm = 40.052e6;

disp 'FID by freq scanning.'
disp 'Make sure sample is in the magnet !'

%pause(2);
%LarmorFreq = 23.0268*1000000; % M2.1 at room temperature
%LarmorFreq = 23.4268*1000000
%RD = 5e6;
%TD = 500;
 

%% do regular FID
myNMR.read_temp2()  % somehow this command kick start the serial port

infreq = myNMR.MagnetFreq(20,3); % using magnet 3

% Current fw in my board probably does not support Nint and Nfrac. Will
% update
% YS nov 2019

myNMR.setNMRparameters(p.i_nint, infreq*FLarm/HLarm);
pause(0.1);
 
 myNMR.setNMRparameters(p.i_freq, infreq);pause(0.1);
 
 
 
 
    %
%%
 
 tune = 1000;
 t90=10;
 dummyscan = 0;
 NA = 4;
 RD = 1*10^6;
 
myNMR.setNMRparameters(p.i_tuningcap, tune); pause(0.1);   
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,9);pause(0.1);
myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);

%
if showAll
    disp 'Show parameters pulled the MCU.'

    temp = myNMR.readparams();
    for ii=1:length(temp)
        disp (num2str(temp(ii)))
    end
end

NMR_job = 101;
code1 = hex2dec('0201'); % run FID_mcbsp command
% code for NOE1dFID

    if showAll    
        disp('now execute pp')    ;
    end
    myNMR.write_1register(NMR_job,code1);

   tic
    x=0;
    while x==0
        pause(1)
        x = myNMR.readstatus();
        
    end
    toc
    if showAll 
        disp(['FID Data to transfer=',num2str(x)])
    end
    y = myNMR.read_NMR_data(x);
    if showAll 
        nmrplot(y)
    end
    
 
 % do NOE1dFID, exp index = 100
 