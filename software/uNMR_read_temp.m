function [res] = uNMR_read_temp(whichone)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% 
global uNNR_serial;
global device;

if isempty(uNMR_serial)
    uNMR_init_serial();
end

if nargin <1
    disp 'onboard temp sensor'
else
    fprintf(1,'temp sensor %d',whichone);
end


% currently used for uNMR serial port

% CRC, for RTU mode, 8 bit data, binary
% input is not a string, but a decimal numbers
% also no ':'



% ASCII mode
% device = '01';
%sendstring = [':',device, '03', '00', '07','00', '01'];


%%
% commands
command_read_reg = 3;
reg_incr = 2;
reg_temp = 7;

reg_NMR = 100;


% I think the mode is specified by DataBits
if 1 %s1.DataBits==8
    % command:
    % increment a counter. 
    % Read back double(outstring)= is     1     3     2     0    10    56    67
    % final send char:
    % sendstring = [ device, 3,0,2,0,1,37,202];

    sendstring = [ device, command_read_reg,0,reg_temp,0,1];
    
    % crc will be added
    ss = append_crc(sendstring)

    %convert to hex code for the crc:
    dec2hex(ss(end-1:end));
end

return

try 
    fprintf(uNNR_serial,[ss])    
catch
    disp(['Try to send ' num2str(double(ss))])
    disp 'Error. Cannot send to serial port.'
end

try
    outstring = fscanf(uNNR_serial,7);
    
catch
    outstring = '';
    disp 'Error. Cannot read from serial port.'
end

x = outstring(4:5);
res = x';
res = double(x(:)');


