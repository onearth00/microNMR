function test_2019_12_11()

% test of uNMR
% for temp

% note: nov 2019 YS. matlab 2014 ver does not seem to work.
%

clear

addpath('~/Work/MyAppSupportFiles/matlab_help_pre2020/uNMRdriver_current');

myNMR = boottest();


%%
% magnet 1 => M2.1
% magnet 4 => high res
    LarmorFreq = myNMR.MagnetFreq(22,3)      % room temp
    disp 'Assume room temp 22 C'
    %
p = pindex;
    DS = 0;
%  *******************************
% set parameters
%   *******************************
o1 = 40e3;

myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
LarmorFreq+o1

%%
NA = 4;
TD = 1000;
RD = 2e6;
rg = 11;
capbias = 3500;
t90 = 7;


myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);

myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);

myNMR.setNMRparameters(p.i_recgain,rg);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_tuningcap, capbias); pause(0.1);
%
disp 'parameters have been set.'
%% observe RF pulses
pause(2)

disp ' ---------------------- '
disp 'Observe the RF pulse and FID.'
disp ' ---------------------- '

timeaxis = [];
tic;
temp=[];
temp1=[];
peaklist = [];
nmrlist =[];
peakfreq = 0;
ii=1;
while (toc < 100+3600*24) 
    % ------- get temp from onboard sensor
    try
        temp1(ii) = myNMR.read_temp2();
        temp(ii) = myNMR.read_temp_24bit();
    end
    t1 = toc;
    timeaxis(ii) = t1;

    % ------- Start TX/RX self test
    %myNMR.startExpt(2,1);   % 5 is tuning
    [nmrdata,peakfreq] = getFID(myNMR);
    peaklist(ii) = peakfreq;
    disp ([' peak freq=' num2str(peakfreq)])
    
    if ~isnan(peakfreq) & (abs(peakfreq) < 5000)
        o1 = o1 - peakfreq*1e3;
    end
    
    myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
    
    
    nmrlist(:,ii) = nmrdata(:);
    
    % --------- END of experiment, now draw

    if(t1>3600)
        xunit = 3600;
    else
        xunit = 1;
    end
    
    ii=ii+1;
        
    figure(1)
    subplot(211)
    if length(temp)>0 | length(temp1)>0
        yyaxis left
        
        plot(timeaxis/xunit,temp,'ko-')
        hold on
        %plot(timeaxis/xunit,temp1,'k*-')
        hold off
        %h=axis;
        %axis([h(1:2) 20 30])

        ylabel('Temp in degC')
        
        yyaxis right
        plot(timeaxis/xunit,peaklist,'bs-')
        hold on
        %plot(timeaxis/xunit,imag(phase),'rs-')
        hold off
        ylabel('peak freq, kHz')
        axis tight
        
        title('onboard temperature sensor')
        if t1<3600
            xlabel('experiment time, s')
        else
            xlabel('experiment time, hr')
        end
    end
    

    
    subplot(2,2,3)
    y = nmrshift(nmrdata(:),4);
    nmrplot(y, 0.01)
    y = y.*exp(-(1:length(nmrdata))'/200);
    
    
   xlabel('FID aquisition time, ms ')
   
   subplot(224)

   [fy, w] = nmrfft(y,0.01);
   plot(w,abs(fy))
   h=axis;
   %axis([-20 20 h(3:4)])
   pause(1)
end

toc

%% try F19
% feb 21, 2020
%
% 
HLarm = 42.57e6;
FLarm = 40.052e6;
capbias = 1000;
NA = 4;
t90 = 7;

F19freq = (LarmorFreq+o1)/HLarm*FLarm;

myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);

myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);

myNMR.setNMRparameters(p.i_recgain,rg);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_tuningcap, capbias); pause(0.1);

myNMR.setNMRparameters(p.i_freq, F19freq);pause(0.1);
F19freq

[nmrdata,peakfreq] = getFID(myNMR);
figure(2)
nmrplot(nmrdata)
    
end



function [nmrdata, peakfreq] = getFID(myNMR)
    myNMR.startExpt(2,1);   % 5 is tuning; 6=>get full tuning curve
    disp 'starting ...'
        x=0;
        while x==0
            pause(1);
            fprintf(1,'waiting ... ')
            x = myNMR.readstatus();  
            pause(1);
        end

        disp(['FID Data to transfer=',num2str(x)])

        %
        pause(1)
        y = myNMR.read_NMR_data(x);
        nmrdata= y(:);
        
        ndata = length(nmrdata);
        blc = mean(nmrdata(floor(ndata*3/4):ndata));
        nmrdata = nmrdata ;
        
        
        L = size(y,1);
        y = nmrshift(nmrdata(:)-blc,4);
        y = y.*exp(-(1:length(nmrdata))'/200);            
        [p0, f] =nmrfft(y,0.01);
            
            [peak,n] = max(abs(p0));
            
            x = find(abs(p0)>peak*3/4);
            
            peakfreq = sum(f(x).*abs(p0(x)))/sum(abs(p0(x)));
            
            
        if 0
            subplot(2,1,1)
            nmrplot(y,0.01)
            xlabel('acquisition time, ms')
            ylabel('NMR signal')
           % title('FID data')

            subplot(2,1,2)

            plot(f,p0)
            xlabel('frequency in Hz')
            ylabel('FFT amplitude')
        end
        %sound(real(y)/5)
end
    