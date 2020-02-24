function [s1 ] = uNMR_init_serial()
% serial connection to uNMR pcb
% Input: none
% Output: s1, used for future serial operation
%
% YS nov 30, 2016 -  
%
% 
global uNNR_serial;
global device;


device = 1;

%s1 = serial('/dev/tty.usbserial-FTYTWHRQ');
uNNR_serial = serial('/dev/cu.usbserial-FTZ6DV8U');  % port name is specific to the USB dongle

% currently used for uNMR serial port

% CRC, for RTU mode, 8 bit data, binary
% input is not a string, but a decimal numbers
% also no ':'


device = 1;

% ASCII mode
% device = '01';
%sendstring = [':',device, '03', '00', '07','00', '01'];


if ~isempty(uNNR_serial)
    set(uNNR_serial,'BaudRate',57600,'DataBits',8,'parity','even');
    set(uNNR_serial,'timeout',0.1);
    % Specify Terminator
    uNNR_serial.terminator='';

    if uNNR_serial.Status == 'closed'
        fopen(uNNR_serial);
    end
else
    %uNNR_serial
    fprintf(1, 'Serial device found (%s)\r',uNNR_serial.port)
end

s1 = uNNR_serial;
