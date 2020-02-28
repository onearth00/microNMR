% Yiqiao Tang 3/20/2018
% this function outputs predicted Larmor frequency at a given temperature
% and magnet

% index = 1,2,3 for magnet M2.1, M2.2 and M2.3
% T in C  

function [freqq,p] = magnet_temp(index, T)
%extrapolates Larmor frequency of the magnet (M2) as a function of
%temperature
%input in degrees celsius, output in MHz

database = [32	22.9132	23.3549	23.3388
50	22.7448	23.1969	23.1773
75	22.5145	22.97	22.9468
100	22.2775	22.7314	22.702
125	22.0323	22.4836	22.4555
150	21.7785	22.2288	22.195];

temp = database(:,1);
freq1 = database(:,2);
freq2 = database(:,3);
freq3 = database(:,4);

p(:,1) = polyfit(temp,freq1,2);
p(:,2) = polyfit(temp,freq2,2);
p(:,3) = polyfit(temp,freq3,2);

tem = -0:150;

freqp = p(1,index) .* tem .* tem + p(2,index).*tem + p(3,index);
freqq = p(1,index) .* T .* T + p(2,index).* T + p(3,index);
plot(temp,database(:,(index+1)),'gx',tem,freqp,'b',T,freqq,'ro')
end
