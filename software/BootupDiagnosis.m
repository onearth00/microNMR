function [y] = BootupDiagnosis(p,myNMR)
clf
subplot(2,1,1)
temp=[];
for ii=1:5
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
%
% magnet 1 => M2.1
% magnet 4 => high res
if isnumeric(avgTemp)
    
    LarmorFreq = myNMR.MagnetFreq(avgTemp,1);
    
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
RD = 1500000;
o1 = 0;

myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
LarmorFreq+o1
myNMR.setNMRparameters(p.i_recgain,2);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
disp 'parameters have been set.'
% observe RF pulses
pause(2)

disp 'Observe the RF pulse.'
disp ''

NMR_job = 101;
code = hex2dec('0501'); % run tuning command
%code = hex2dec('0901'); % run 20 acq only. no pulse seq
    % set freq
    
datalist=[];
phase_angle=[];
for ii=1:3
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
end

% get pulse amplitude
% pulse_ampl = mean(datalist(30:50,:),1); % calibrate to volt.
% if (abs(mean(pulse_ampl)) > 1) && (std(abs(pulse_ampl)) < 0.1)
%     disp ' '
%     disp 'Pulse amplitude normal.'
% else
%         disp ' '
%     disp ('Pulse amplitude is too low or unstable.')
% end
end

