% test LRC and CRC

% currently used for uNMR serial port

% CRC, for RTU mode, 8 bit data, binary
% input is not a string, but a decimal numbers
% also no ':'
device = 1;
%sendstring = [ device, 3,0,2,0,1,37,202];
sendstring = [ device, 3,0,2,0,1];
ss = append_crc(sendstring)

sendstring = [ device, 3,0,7,0,1];
ss = append_crc(sendstring)
dec2hex(ss(end-1:end))

return




% Use LRC, probably for 7 bit data, ascii mode
%try the string
device='01';
sendstring = [ device, '03', '00', '02', '01'];

[r,ss]=LRC(sendstring,2)


