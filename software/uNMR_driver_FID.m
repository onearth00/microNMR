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

p = pindex;

%
myNMR.setNMRparameters(p.i_T90,15);pause(0.1);
myNMR.setNMRparameters(p.i_T180,30);pause(0.1);


%% Find FID signal

NA=1;DS=0;
TD = 800;
RD = 1000000;
myNMR.setNMRparameters(p.i_RD, RD); pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 6); pause(0.5);

myNMR.setNMRparameters(p.i_na, NA); pause(0.5);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.5);

%LarmorFreq = myNMR.MagnetFreq(25,4);
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
        pause(0.1)
    end
    
    y = myNMR.read_NMR_data(x);
    datalist(:,ii) = y(:);
    
    
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
TD=200;
RD = 4000000;
myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_na, 1);pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 5);pause(0.5);
myNMR.setNMRparameters(p.i_RD, RD);pause(0.5);
myNMR.setNMRparameters(p.i_tuningcap, 4000);pause(0.5);
myNMR.setNMRparameters(p.i_T90, 17);pause(0.5);


nmrparams= myNMR.readparams()'

%
o1 = -60000
f0 = LarmorFreq +o1;
RD = 1000000;
myNMR.setNMRparameters(p.i_freq, f0);pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD);pause(0.1);


%nmrparams= myNMR.readparams();

mylist = (-10:10)*1000*0;
mylist = (12:4:50);    % T90 time
mylist = (100:400:4095);
mylist = 4090;
%
NMR_job = 101;
%code = hex2dec('0301'); 
code = hex2dec('0001'); 
code = hex2dec('0701');
datalist=[];

failure=0;
for ii=1:200
    
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
        hold on; plot(tau,imag(y-blc)*2.5/2^12,'.-'); hold off
        % fft
        subplot(223)
        [yf,w2] = (nmrfft(y-blc,nmrparams(p.i_dwell)/1000));
        nmrplot(yf,w2)
        h=axis;
        axis([-20 20 h(3:4)])
        
        subplot(224)
        plot(real(datalist(12,:)),'ro-')
        hold on
        plot(imag(datalist(12,:)),'bs-')
        hold off

        
        pause(5)
        
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

nmrplot(transpose(datalist(8,:)))

%% analysis

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
plot(mylist,peakhigh,'o-')
%axis([0 100 0 40])
xlabel('Tuning cap code 0-4095')
ylabel('Amplitude at peak')
title(['T90=' num2str(nmrparams(p.i_T90)) ' us'])
subplot(122)
plot(mylist,w2(peakindex),'o-')
%axis([0 100 0 5])
xlabel('experiments')
ylabel('Freq at peak')



%% plot datalist and check for phase consistency

nmrplot(transpose(datalist(10,:))-2500*(1+1i))


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
