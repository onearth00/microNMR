function [freqq] = magnetFreq(obj,T,magn)
%extrapolates Larmor frequency of the magnet (M2) as a function of
%temperature 
%   input T in degrees celsius, 
%   output in MHz

% From Ray, Feb 1, 2017
% This is for M2.1

if nargin <3
    which_magnet = 1;
else
    which_magnet = magn;
end


% Three magnets: sn01, sn02, sn03. magnet 4 is the high res one
% Magnet frequency calibrtion data from Marcus.
magnets=[
         32     22.9132	23.3549	23.3388
         50     22.7448	23.1969	23.1773
         75     22.5145	22.97	22.9468
         100	22.2775	22.7314	22.702
         125	22.0323	22.4836	22.4555
         150	21.7785	22.2288	22.195
         ];


if which_magnet ~= 4

    temp = magnets(:,1);
    freq = magnets(:,1+which_magnet);
    p = polyfit(temp,freq,2);

    freqq = floor(polyval(p, T) *10^6);
else
    %
    % use the magnet 1 for temperature dependence and scale to 
    % the room temperature field/freq of 21.8593 MHz.
    % MAgnet1 at 25 deg C is 22973879 Hz.
    % 
    temp = magnets(:,1);
    freq = magnets(:,2);
    p = polyfit(temp,freq,2);
    freqq = floor(polyval(p, T)/22.973879.*21.8593*10^6);

end

