function  uNMR_default_param()
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% 
global uNNR_serial;
global device;


global Delays;
global Pulses;
global PS;

% in unit of us
Delays = zeros(10,1);
Delays(1) = 1000000;
Delays(2) = 1000;

Pulses = zeros (10,1);
Pulses(1) = 10;
Pulses(2) = 20;
