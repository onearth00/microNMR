% uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:500
    try
        temp(ii) = myNMR.read_temp2();
    end
    if length(temp)>2
    plot(temp,'o-')
    end
    pause(5)
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

NA = 1;
DS = 0;
TE = 1000;
TD = 200;
p = pindex;
%% set the NMR parameters

% enum p_index

myNMR.setNMRparameters(p.i_na, 1); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);

%
%LarmorFreq = 22.95*10^6;
myNMR.setNMRparameters(p.i_freq, LarmorFreq);pause(0.1);

%
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
%
myNMR.setNMRparameters(p.i_T90,15);pause(0.1);



%% tuning


%% Find FID signal

NA=1;DS=0;
TD = 800;
RD = 1000000;
myNMR.setNMRparameters(p.i_RD, RD); pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 6); pause(0.5);

myNMR.setNMRparameters(p.i_na, NA); pause(0.5);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.5);

LarmorFreq = myNMR.MagnetFreq(25,4);
%LarmorFreq = (23-0.025)*10^6;       % HP pulse/func gen, 50MHz. Set to 23.9MHz

myNMR.setNMRparameters(p.i_freq, LarmorFreq);pause(0.5);

myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_T90,15);pause(0.5);
%%
NMR_job = 101;
%code = hex2dec('0301'); 
code = hex2dec('0001'); 
freq_offset = (-100:10:100)*1000;
freqlist = [];
datalist = [];

for ii=1:length(freq_offset)
    % set freq
    freqlist(ii) = LarmorFreq+freq_offset(ii);

    myNMR.setNMRparameters(p.i_freq, LarmorFreq+freq_offset(ii));pause(0.5);

    
    myNMR.write_1register(NMR_job,code);
    pause(2)
ii

%
    x=0;
    while x==0
        x = myNMR.readstatus();
        disp(['Number of data points to be transferred=',num2str(x)])
    end
    
    y = myNMR.read_NMR_data(x);
    real(y);
    imag(y);
    
    subplot(121)
    plot(freqlist,'o-')
    
    subplot(122)
    plot(real(y)*2.5/2^12,'rs-','markersize',1)
    hold on
    plot(imag(y)*2.5/2^12,'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    axis([h(1:2) 0 2.5])
    datalist(:,ii) = y(:);
end

[xd,i] = max(sum(abs(datalist),1))
f0 = freqlist(i);

%% find the max signal
TD=1000;
f0 = LarmorFreq ;
myNMR.setNMRparameters(p.i_freq, f0);pause(0.5);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_na, 1);pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 5);pause(0.5);
myNMR.setNMRparameters(p.i_RD, 10000);pause(0.5);

nmrparams= myNMR.readparams()'

%%
o1 = 10000;
f0 = LarmorFreq +o1;
%dw= 9;
myNMR.setNMRparameters(p.i_freq, f0);pause(0.5);
myNMR.setNMRparameters(p.i_recgain,5);pause(0.5);

nmrparams= myNMR.readparams();

o1list = (-10:10)*1000*0;
%
NMR_job = 101;
%code = hex2dec('0301'); 
code = hex2dec('0901'); 
datalist=[];

for ii=1:1
    
    myNMR.setNMRparameters(p.i_freq, f0);pause(0.5);

    myNMR.write_1register(NMR_job,code);
   pause(2)
ii
%
    x=0;
    while x==0
        x = myNMR.readstatus();
        disp(['Number of data points to be transferred=',num2str(x)])
    end
    pause(0.01)
    y = myNMR.read_NMR_data(x);
    datalist(:,ii)=y(:);

    blc=mean(y(TD-50:end));
    figure(1)
    subplot(211)
    plot(real(y-blc)*2.5/2^12,'r.-')
    hold on; plot(imag(y-blc)*2.5/2^12,'.-'); hold off
    % fft
    subplot(212)
    [yf,w2] = (nmrfft(y-blc,nmrparams(p.i_dwell)/1000));
    nmrplot(yf,w2)
    h=axis;
    axis([-10 10 h(3:4)])
end

[mxspec,i]=max(abs(yf-blc));
w2(i)
nmrparams(p.i_freq)-LarmorFreq
disp 'done'
%%
[dataf,w2] = nmrfft(datalist-blc,nmrparams(p.i_dwell)/1000);
figure(1)
plot(w2,abs(dataf))
xlabel('signal freq offset, kHz')
title('Different scans are with offset from -10 to 10kHz')
figure(2)
surf(abs(dataf))
xlabel('transmit freq offset')
ylabel('Larmor freq offset')

subplot(121)
[peakhigh,peakindex]=max(abs(dataf));
plot(peakhigh)
axis([0 100 0 40])
xlabel('experiments')
ylabel('Amplitude at peak')
subplot(122)
plot(w2(peakindex),'o-')
axis([0 100 0 5])
xlabel('experiments')
ylabel('Freq at peak')


%%  *******************************
% CPMG -- working, on Feb 6.
%   *******************************

TD = 800;
RD = 1000000;
myNMR.setNMRparameters(p.i_RD, RD); pause(0.5);


myNMR.setNMRparameters(p.i_na, NA); pause(0.5);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.5);

LarmorFreq = myNMR.MagnetFreq(25,4)
%LarmorFreq = (23-0.025)*10^6;       % HP pulse/func gen, 50MHz. Set to 23.9MHz

myNMR.setNMRparameters(p.i_freq, LarmorFreq);pause(0.5);


myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_T90,15);pause(0.5);


myNMR.setNMRparameters(p.i_TE,500);pause(0.5);
%%
NMR_job = 101;
code = hex2dec('0301'); 
%code = hex2dec('0001'); 

for ii=1:100
    % set freq
    myNMR.write_1register(NMR_job,code);
    pause(2)
ii

%
    x=0;
    while x==0
        x = myNMR.readstatus();
        disp(['Number of data points to be transferred=',num2str(x)])
    end
    
    y = myNMR.read_NMR_data(x);
    real(y);
    imag(y);
    subplot(111)
    plot(real(y)*2.5/2^12,'rs-','markersize',1)
    hold on
    plot(imag(y)*2.5/2^12,'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    axis([h(1:2) 0 2.5])
end



%%  *******************************
% FID -- working, on Feb 3.
%   *******************************

NMR_job=101;
code = hex2dec('0901');
%code = hex2dec('0001');
for ii=1:1
    myNMR.write_1register(NMR_job,code);
    pause(1)
ii
    x=0;
    while x==0
        x = myNMR.readstatus();
        disp(['Number of data points to be transferred=',num2str(x)])
        pause(1)
    end
    

    %
    x = myNMR.readstatus();
    if (x<1001)
    y = myNMR.read_NMR_data(x  );
    else
        y = myNMR.read_NMR_data(50  );
    end
    real(y);
    imag(y);
    figure(1)
    subplot(111)
    plot(real(y)*2.5/2^12,'rs-','markersize',1)
    hold on
    plot(imag(y)*2.5/2^12,'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    axis([h(1:2) 0 2.5])
end
