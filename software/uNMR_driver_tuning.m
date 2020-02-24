% uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR

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

NA = 1;
DS = 0;
TE = 1000;
TD = 200;
p = pindex;






%% Find FID signal
o1=30000
NA=1;DS=0;
TD = 1000;
RD = 1000000;
myNMR.setNMRparameters(p.i_RD, RD); pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 6); pause(0.5);

myNMR.setNMRparameters(p.i_na, NA); pause(0.5);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.5);

myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.5);

myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_T90,15);pause(0.5);


%% find the max signal
TD=1000;
f0 = LarmorFreq +o1;
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

varactorbias = (0:100:4090);
%
NMR_job = 101;
%code = hex2dec('0301'); 
code = hex2dec('0001'); 
datalist=[];

for ii=1:length(varactorbias)
    
    myNMR.write_1register(3,varactorbias(ii));pause(0.1);
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
plot(abs(dataf(:)))
xlabel('signal freq offset, kHz')
title('Different scans are with offset from -10 to 10kHz')
figure(2)
surf(abs(dataf))
xlabel('transmit freq offset')
ylabel('Larmor freq offset')

subplot(121)
[peakhigh,peakindex]=max(abs(dataf));
plot(varactorbias,peakhigh)
h=axis;
axis([h(1:2) 0 60])
xlabel('Varactor bias code (0-4095)')
ylabel('Amplitude at peak')
subplot(122)
plot(w2(peakindex),'o-')
axis([0 100 0 5])
xlabel('experiments')
ylabel('Freq at peak')

% varactor bias of 3400 seems to be good.



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
