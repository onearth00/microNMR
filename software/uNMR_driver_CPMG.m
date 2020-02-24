% uNMR driver
% YS Dec 2016 --

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:5
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
% CPMG -- working, on Feb 6.
%   *******************************

TD = 1000;
RD = 1500000;
o1 = 3000;
TE=500;
NA=1;
myNMR.setNMRparameters(p.i_tuningcap,4000); pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);

myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS);pause(0.1);

%LarmorFreq = myNMR.MagnetFreq(avgTemp,4)

myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
myNMR.setNMRparameters(p.i_recgain,5);pause(0.1);

myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_T90,15);pause(0.1);
myNMR.setNMRparameters(p.i_T180,30);pause(0.1);

myNMR.setNMRparameters(p.i_TE,TE);pause(0.1);
%%
o1 = 35000;
TD = 2000;
RD = 1000000;
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
myNMR.setNMRparameters(p.i_na, 1); pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);

NMR_job = 101;
code = hex2dec('0301'); 
code = hex2dec('0001'); 

datalist=[];
for ii=1:1
    % set freq
    myNMR.write_1register(NMR_job,code);
    pause(2)
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
    subplot(111)
    plot(real(y)*2.5/2^12,'rs-','markersize',1)
    hold on
    plot(imag(y)*2.5/2^12,'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    %axis([h(1:2) 0 2.5])
    xlabel('Echo time')
    pause(5)
end
%% plot the result of one scan
figure(1)
a=25;
b=floor(length(y)/a);
y1 = reshape(y(1:a*b),a,b);
tau1=(0:24)*10;
tau2=(1:TD/a)*TE/1000;
subplot(211)
pcolor(tau2(2:end),tau1,real(y1(:,2:end))),shading flat
xlabel('Echo time, ms')
ylabel('Detection time within echo, us')
title('Water, at High res magnet, 200 echoes, TE=0.5ms')

subplot(212)
pcolor(tau2(2:end),tau1,imag(y1(:,2:end))),shading flat
xlabel('Echo time, ms')
ylabel('Detection time within echo, us')

figure(2)
subplot(111)
nmrplot(y1(:,2:end),10)
xlabel('Detection time, us')
title('Water, CPMG, real and imag, high res magnet')

%% compare all different scans
yy = reshape(datalist,a,b,200);
yy1 = squeeze(sum(yy(13,:,:),1));

plot(real(yy1(:)),'r')
hold on
plot(imag(yy1(:)),'b')

hold off

