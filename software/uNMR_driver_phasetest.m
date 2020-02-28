% uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR


% test of phase conclusion. Feb 24, 2017
% It appears that the rec phase may have a 180 shift relative to the TX phase
%when the RF reference signal is turned off and turned on again. This is likely
% due to the reset of the RX 0/90 phase generator from the LO (2f) with an ambigurity
% of pi. 
% It will be the best to confirm this from reading the schematics of the
% ASIC.

%% test to read the board temp
temp=[];
for ii=1:5
    try
        temp(ii) = myNMR.read_temp2();
    end
    pause(1)
end
temp;
if length(temp)>2
    plot(temp)
else
    temp
end

avgTemp = mean(temp)
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,4)
else
    LarmorFreq = myNMR.MagnetFreq(25,4)      % room temp
    disp 'Assume room temp 25 C'
end

p = pindex;

%
myNMR.setNMRparameters(p.i_T90,15);pause(0.1);
myNMR.setNMRparameters(p.i_T180,30);pause(0.1);



%% find the max signal
TD=1000;
RD = 10000;
myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_na, 1);pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 5);pause(0.5);
myNMR.setNMRparameters(p.i_RD, RD);pause(0.5);
myNMR.setNMRparameters(p.i_tuningcap, 4000);pause(0.5);
myNMR.setNMRparameters(p.i_T90, 17);pause(0.5);
myNMR.setNMRparameters(p.i_dwell, 5);pause(0.5);

nmrparams= myNMR.readparams()'

%% run fid once
o1 = 30000;
f0 = LarmorFreq +o1;
RD = 1000000;
%
 myNMR.setNMRparameters(p.i_freq, f0);pause(0.1);
%
myNMR.setNMRparameters(p.i_TD, 1000);pause(0.1);
%
myNMR.setNMRparameters(p.i_dwell, 10);pause(0.1);
NMR_job = 101;
%code = hex2dec('0301'); 
code = hex2dec('0001'); 

for ii=1:1
myNMR.write_1register(NMR_job,code);

pause(4)

x = myNMR.readstatus(); pause(0.1)
y = myNMR.read_NMR_data(x);
%
nmrplot(y(3:end)-y(end-10))
%
    if 0
        nmrparams=myNMR.readparams()';
        if     nmrparams(p.i_TD)-nmrparams(p.i_acqiredTD) ~= 0
                disp (['acquisition error:' ...
                num2str(nmrparams(p.i_TD)-nmrparams(p.i_acqiredTD))])
                %failure = failure + 1;
        end
    end
    
end
    

%%
TD =2000;
o1 = 3000;
f0 = LarmorFreq +o1;
RD = 4000000;
myNMR.setNMRparameters(p.i_freq, f0);pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_na, 1);pause(0.1);



%nmrparams= myNMR.readparams();

%
NMR_job = 101;

code = hex2dec('0001'); 
%code = hex2dec('0701');
%code = hex2dec('0901');
datalist=[];
tic;
failure=0;
for ii=1:1
    
    %myNMR.setNMRparameters(p.i_tuningcap, mylist(ii));pause(0.1);

    myNMR.write_1register(NMR_job,code);
   pause(0.1)
ii
%
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(0.1)
    end
    
    if 1
        disp(['Number of data points to be transferred=',num2str(x)])
        y = myNMR.read_NMR_data(x);
        datalist(:,ii)=y(:);

        blc=mean(y(TD-50:end));
        figure(1)
        subplot(211)
        tau=(1:TD)*nmrparams(p.i_dwell)/1000;
        plot(tau,real(y-blc)*2.5/2^12,'r.-')
        hold on; 
        plot(tau,imag(y-blc)*2.5/2^12,'.-'); hold off
        ylabel('Signal, V')
        % fft
        subplot(223)
        [yf,w2] = (nmrfft(y-blc,nmrparams(p.i_dwell)/1000));
        nmrplot(yf,w2)
        h=axis;
        axis([-20 20 h(3:4)])
        title(datestr(now))
        
        subplot(224)
        plot(real(datalist(10,:)),'ro-')
        hold on
        plot(imag(datalist(10,:)),'bs-')
        hold off

        xlabel('Experiment number')
        title('500 FIDs, phase 90 deg')
        pause(10)
        
    end
    
    if 0
        nmrparams=myNMR.readparams()';
        if     nmrparams(p.i_TD)-nmrparams(p.i_acqiredTD) ~= 0
                disp 'acquisition error:'
                nmrparams(p.i_TD)-nmrparams(p.i_acqiredTD);
                failure = failure + 1;
        end
    end
end

disp 'done'

toc
subplot(211)
nmrplot(datalist)
title('FID scans, NO set freq 2f, On:Seq, NMR_init,gain,tuningcap')

%% test temp controller


%
y=[];
NMR_job = 101;


code = hex2dec('0901');

code = hex2dec('0701');

    myNMR.write_1register(NMR_job,code);
    x = myNMR.readstatus();
    y = myNMR.read_NMR_data(20);
    nmrplot(y)
    axis([0 20 0 300])
    disp 'done'
%%
    
nmrparams= myNMR.readparams()'
nmrparams(p.i_acqiredTD)
