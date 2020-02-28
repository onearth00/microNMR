function [s] = serialstart(opt)
% Funtion for initializing a serial interface in matlab for interfacing
% with modbus Eaton ELC PLC controllers over RS-232 serial connections
%
% mode 1 initializes the connection using the com port specified in
% opt.serial
%
% Functions using the serial port must be passed the serial port object
% s in order for the serial port to be acessable.  

if nargin == 0
    mode = 1; 
    opt.serial = 'COM15';
end

% Initialize serial port on specified com port
s = serial(opt.serial);

% Specify connection parameters
set(s,'BaudRate',9600,'DataBits',7,'StopBits',1,'Parity','even','Timeout',3);

%Open serial connection
fopen(s);

% Specify Terminator
s.terminator='CR/LF';

% Set read mode
set(s,'readasyncmode','continuous');


