% uNMR driver
% YT July 2017 --
% implement mcbsp features
clear
myNMR = uNMR('COM3')
% bootup diagnosis
BootupDiagnosis(pindex,myNMR);
%% read sequence from TI 
myNMR.readstatus()
seq=myNMR.read_NMR_seq();

seq(1,2) = 0;
seq
% download sequenc to TI
%seq_1 = seq*0;
myNMR.readstatus();
myNMR.download_NMR_seq(seq)

myNMR.readstatus() %check the sequence downloaded
seq = myNMR.read_NMR_seq();

% make sequence and download to TI
myNMR.pseq(1,:) = myNMR.PlsGenDelay(1000000);
myNMR.pseq(2,:) = myNMR.PlsGenPulse(100,30,0,0);
myNMR.pseq(3,:) = myNMR.PlsGenDelay(10);
%myNMR.pseq(4,:) = myNMR.PlsGenACQ(10, 1000);

temp = myNMR.pseq;

% readout:
nonzeros(bitshift(temp(:,1),-6)/15)
nonzeros(bitshift(temp(:,2),-8)/15)

% swap the two columns:
temp2(:,2) = temp(:,1);
temp2(:,1) = temp(:,2);

myNMR.readstatus() %check the sequence downloaded
myNMR.download_NMR_seq(temp2)

myNMR.readstatus() %check the sequence downloaded
seq=myNMR.read_NMR_seq();
%% FID 
infreq = 23.4268*1000000 + 4e4 - 10600; %in hertz
% infreq = 23.3368*1000000 + 4e4 - 10600; %in hertz
RD = 1e6;
TD = 500;
t90 = 25;
tune = 3500;
NA = 2;
p = pindex;
dummyscan = 0;
myNMR.setNMRparameters(p.i_RD, 2.5e6); pause(0.1);
[y,f,p0] = FID(infreq, RD, tune,TD,t90,NA,dummyscan,p,myNMR) %f is the frequency base and p0 the fft amplitude
%% frequency tuning
box = 5; %define the box size
fftmean = zeros(size(f,2)-box+1,1);
for i = 1:(size(f,2)-box)
    fftmean(i) = mean(p0(i:(i+box))); %calculate the moving averages
end
[M,index] = max(fftmean);
index = index + floor(box/2); 
2*(infreq -f(index))
infreq = infreq - f(index); % update frequency
FID(infreq, RD, tune,TD,t90,NA,dummyscan,p,myNMR) %confirm the tuning results. % only when using onboard PLL 

%% nutation exp 
% 2/14/2018 Ray Tang

t90 = 10:5:80;
tune = 3500;

y = FIDnut(infreq, RD, tune,TD,t90,NA,dummyscan,p,myNMR) %confirm the tuning results.

plot(-imag(y(:)))
xlabel('no. of points')
ylabel('signal amplitude')
title('nutation experiment')
legend(['from ' num2str(t90(1)) ' to ' num2str(t90(end)) ' us, divided by ' num2str((t90(end) - t90(1))/(length(t90)-1))])
%% generate the window sum table for data compression
% this program is to calculate the number of averagings at each data index
% during a window sum executation in firmware

N = 200;%total number of recorded data pts
M = 3000; %total number of 180 pulses
n = 50;% reserved index for the first n pts, without data compression
x = 1.03027;

% calculated through: NSolve[Sum[x^ii, {ii, 1, 150}] == 2950, x, Reals] in
% Mathematica

table = ones(N,1)
%
for i = 1:(N-n)
    table(i+n) = round(x^i)
end

sum(table(1:end));  
table(N) = table(N)+1;
%% CPMG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% new feature: set echoshape               
% echoshape = 1, record and save echoshape  
% echoshape = 0, only save echo amplitude  
% Ray Tang, 8/23/2017     
%
% new feature: set window sum (or not) 
% window sum returns 200 floating points 
% while no. of echos = 3000. Use a new variable, ws:
% ws = 1, data compression in firmware and uncompress 
% in Matlab; ws = 0, no compression
% Ray Tang, 1/30/2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TE = 1000; %echo time in us
echoshape = 0;
dummyecho = 1;

ws = 0; %window sum yes/no

myNMR.setNMRparameters(p.i_ws, ws); pause(0.1);


if echoshape == 1
    TD = 7000; %only use with int16 data
    dummyecho = 0; %when recording echo shapes, set dummy echo to zero.
elseif ws == 1
    TD = 200;
else
    TD = 4300; % run into a bug when TD > 4500. Need investigation. 1/30/2018
end

NA = 4;
RD = 15e6;%for full mud
t90 = 25;
t180 = 50;
dummyscan = 0;
p = pindex;
totexpt = NA*(RD + (t90+TE/2+TD*(TE+t180)*(1+dummyecho)))/1e6/60; %total experiment time
X = sprintf('the estimated total experiment time is %d mins:',totexpt);
fprintf(X)

if ws == 1
    [y2] = CPMGacq_ws(echoshape,infreq*2,RD,TE, TD, t90,t180,NA,dummyscan,dummyecho,p,myNMR);% % for echoshape = 0
    y3=y2;
    y2c = [];
    temp = y2(1:200)./table(:);
% recover to uncompressed data
    for i=1:200
        for j = 1:table(i)
            y2c = [y2c temp(i)];
        end
    end
    clear y2; y2 = y2c'; 
else 
    [y2] = CPMGacq(echoshape,infreq*2,RD,TE, TD, t90,t180,NA,dummyscan,dummyecho,p,myNMR);% % for echoshape = 0
end

subplot(1,2,1)
if ws == 1
    time = (1:3000)*(TE+t180)*(1+dummyecho)/1e3;
else
    time = (1:TD)*(TE+t180)*(1+dummyecho)/1e3;
end
plot(time,imag(y2),'.-')
hold all
plot(time,real(y2),'.-')
hold off
xlabel('time in ms')
ylabel('echo amplitude in a.u.')
subplot(1,2,2)
semilogy(time,abs(y2)/max(abs(y2)),'r-') %this is with pts160 directly into asic

% hold on
% semilogy(time,abs(y2)/max(abs(y2)),'b-') %this is with hmc832
xlabel('time in ms')
ylabel('a.u.')
legend('HMC832 + PX570')
hold off
% T2 inversion
TE = (TE + t180)/1e6;
[T2,T2dist] = T2analysismicroNMR(y2',TE,dummyecho,TD)
%% for echoshape = 1
TE = 3 %in ms
t180 = 80e-3 % in ms

row = 149;
col = 46;
y2p = y2(1:row*col);
nmrplot(y2p,1)
y2p = reshape(y2p,row,col);
y2p_red = y2p(2:row,1:col);
plot(real(y2p_red(:)),'.-')
hold on
plot(imag(y2p_red(:)),'.-')
time = (1:row-1)*1 % in us
hold off
%
figure(101)
for i = 1:col
    plot(time,real(y2p_red(:,i)),time,imag(y2p_red(:,i)))
    hold on
%   pause
end
hold off
xlabel('time in us')
ylabel('overlay first 46 echoes')
% for echoshape = 1, plot echo amplitude over time
plot((TE+t180)*(1:col),sum(real(y2p_red(73:82,:)),1))
hold all
plot((TE+t180)*(1:col),sum(imag(y2p_red(73:82,:)),1))
xlabel('time in ms')
ylabel('echo strength')
%% FID Scan of input frequency
startfreq = 23.4268*1000000 + 2e4;
NoScan = 5;
step = 1e4;
RD = 5e6;
TD = 500;
t90 = 40;
NA = 2;
p = pindex;
dummyscan = 0;
[y]=FIDscan(startfreq,NoScan,step,RD, TD,t90,NA,dummyscan,p,myNMR)
%% T1
clear y
RD = 15e6;
TD = 500;
t90 = 40;
t180 = 80;
NA = 2;
vd = [5e3,5e4,1e5,5e5,1e6,2e6,3e6,5e6,8e6,1e7,2e7]; %variable delay for T1 encoding
dummyscan = 0;
p = pindex;
totexpt = NA*(RD*size(vd,2)+sum(vd)+(t90+t180+TD*10)*size(vd,2))/1e6/60; %10 us for dwell time
X = sprintf('the estimated total experiment time is %d  mins:',totexpt);
fprintf(X)
[y] = T1acq(RD, TD,t90,t180,NA,dummyscan,vd,p,myNMR)
% T1 analysis
signs = sign(real(y(10,:)))'; %phase determination
%signs = [1,1,1,1,1,-1,-1,-1,-1,-1]'
absy = abs(y).*signs'; %signed FID
subplot(211)
plot(absy(:))
ampy = mean(absy(10:30,:),1);
ylabel('FID')
xlabel('# of pts')
subplot(212)
semilogy(vd,(ampy-ampy(end))/(ampy(1)-ampy(end)),'o')
ylabel('FID amplitude - FID amplitude at ET = 20 s')
xlabel('encoding time (ET) in us')
%
T1analysismicroNMR((ampy-ampy(end))/(ampy(1)-ampy(end)),vd/1e6)
%% T1T2 pulse sequence
clear y
TE = 200;
dummyecho = 1;
TD = 4300;
NA = 4;

t90 = 25;
t180 = 50;

dummyscan = 0;
p = pindex;

%vd = [5e3,5e4,1e5,5e5,1e6,2e6,3e6,5e6,8e6,1e7,1.5e7]; %variable delay for T1 encoding for water
%vd = [1e3,5e3,3e4,5e4,8e4,1e5,3e5,5e5,8e5,1e6,3e6,8e6,15e6]; %variable delay for T1 encoding for mud and cream
%vd = [1e3,3e3,5e3,1e4,3e4,5e4,8e4,3e5,1e6,5e6,10e6]; %variable delay for T1 encoding for honey
vd = round(logspace(log10(1e3),log10(10e6),2));

RD = vd(end);

totexpt = NA*(RD*size(vd,2)+sum(vd)+(t180+t90+TD*(TE+t180)*(1+dummyecho))*size(vd,2))/1e6/60; %total experiment time
X = sprintf('the estimated total experiment time is %d in mins:',totexpt);
fprintf(X)
%
[y,timelapce] = IRCPMGacq(RD, TE, TD, t90, t180, NA, dummyscan, dummyecho,vd,p,myNMR);
%
signs = sign(mean(real(y(2:5,:))))
ysign = y.*signs;
figure(99)
plot(imag(y))
xlabel('# of pts')
ylabel('echo amplitude')
% T1T2 analysis
% TE = 100;
TE = (TE + t180)/1e6; % in seconds
[T2,T1,FEst] = T1T2analysismicroNMR(y,TE,dummyecho,TD,vd)

% save data
pp.TE = TE*1e6; %in us 
pp.dummyecho = dummyecho;
pp.TD = TD;
pp.NA = NA;
pp.RD = RD;
pp.t90 = t90;
pp.t180 = t180;
pp.dummyscan = dummyscan;
pp.vd = vd; %variable delay for T1 encoding for honey
pp.data = y;
pp.T2 = T2; % for inversion
pp.T1 = T1; % for inversion
pp.FEst = FEst; % t1t2 map

save pp