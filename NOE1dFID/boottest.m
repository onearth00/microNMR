function [res] = boottest()
%
% initial test of the NMR PCB
% Return: true (1) the pCB is good. false (0): problem.

% test of uNMR
% for temp

% note: nov 2019 YS. matlab 2014 ver does not seem to work.
%

%%
AA = exist('uNMR');
if AA == 0
    addpath('~/Work/MyAppSupportFiles/matlab_help/uNMRdriver_current');
end

AA = exist('uNMR');
if AA == 0
    disp 'uNMR is not on the default search path. Pls add it'
    %res = 0;
    return
end

% uNMR driver
% YT July 2017 --
% implement mcbsp features
% bug fixed, 2019 nov, YS
% uNMR.m, init_serial.m, 

myNMR = findserialport();

if isempty(myNMR)
   disp 'Could not initialize uNMR'
   res = 0;
    return
else
    
end
%
% bootup diagnosis
figure(1)
%
% BootupDiagnosis(pindex,myNMR);
p = pindex;
clf
subplot(2,1,1)
temp=[];
for ii=1:10
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
        
    end
    pause(0.1)
end
avgTemp = mean(temp(1,2:end))


% set first and then check the parameters
    if checkparameters(myNMR) == 1
        disp ('Parameters set correctly')
    else
        disp 'Parameters cannot be set correctly'
    end

    if nargout == 1
        res = myNMR;
    end
end


function [res] = checkparameters(myNMR)
%%
% magnet 1 => M2.1
% magnet 4 => high res

    p = pindex;
    LarmorFreq = myNMR.MagnetFreq(25,1);      % room temp

    DS = 0;

    NA = 2;
    TD = 1000;
    RD = 2e6;
    o1 = 0e6;
    rg = 4;
    capbias = 3000;
%  *******************************
% set parameters
%   *******************************

    myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
    myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);
    myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);

    myNMR.setNMRparameters(p.i_recgain,rg);pause(0.1);
    myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
    myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
    myNMR.setNMRparameters(p.i_tuningcap, capbias); pause(0.1);

    disp 'Set parameters ...'
    disp 'Read parameters from the MCU.'

    temp = myNMR.readparams();
    for ii=1:length(temp)
        disp (num2str(temp(ii)));
    end

    res = temp(p.i_RD)== RD && ...
            temp(p.i_ds)==DS && ...
    temp(p.i_freq)== LarmorFreq+o1 &&  ...
    temp(p.i_recgain)== rg &&  ...
    temp(p.i_TD)== TD && ...
    temp(p.i_na)== NA && ...
    temp(p.i_tuningcap)== capbias ;


end


% do the tuning test to see if there is any RF pulses
function [res] = RFtest(myNMR)
disp ' ---------------------- '
disp 'Observe the RF pulse.'
disp ' ---------------------- '

    % ------- Start TX/RX self test
    myNMR.startExpt(5,1);   % 5 is tuning

    x=0;
    while x==0
        pause(1);
        x = myNMR.readstatus();      
    end
    disp(['Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x)*2.5/2^12;

    nmrplot(y)    

        ylabel('signal')

    xlabel('acq points (10us)')
    title(['TX/RX self-diagnosis : ' num2str(ii)])    
end




% find and initialize a serial port for uNMR
function myNMR = findserialport()

%
% to see the list of serial ports
x = seriallist;
for ii = 1:length(x)
    disp ([num2str(ii) ':' char(x(ii))])
end

nn = input('Choose a port: ');
% 
% 
%     if ispc
%     % PC serial ports are identified by 'COM1', 'COM2', etc
%     % COM6 for the laptop near the oven.
%     portName = 'COM6';
%     end
% 
%     if ismac
%     % for mac, use x = seriallist to look for serial ports
%         portName = '/dev/cu.usbserial-FT0GEBSB';
%     end

if nn > length(x)
    disp 'Not a valid port. Stop initialization'
    myNMR = [];
    return
end

    portName = char(x(nn));
    
    myNMR = uNMR(portName);

    if myNMR.serial_port.Status(1:4) == 'clos'
        disp 'Serial port does not open. Return'
        myNMR.serial_port
        return;
    else
        disp 'Serial port is open. Continue'
    end

end
    