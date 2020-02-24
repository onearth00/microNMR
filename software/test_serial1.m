% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% 

% this is the dongle for Yiqiao
s1 = serial('/dev/tty.usbserial-FTYTWHRQ');

% this is the one for David's 
%s1 = serial('/dev/cu.usbserial-FTZ6DV8U');  % port name is specific to the USB dongle

%get (s1);

% currently used for uNMR serial port

% CRC, for RTU mode, 8 bit data, binary
% input is not a string, but a decimal numbers
% also no ':'

device = 1;

% ASCII mode
%sendstring = [':',device, '03', '00', '07','00', '01'];
% for ascii mode, use the following:
% device = '01';




set(s1,'BaudRate',57600,'DataBits',8,'parity','even');
set(s1,'timeout',0.1);
%
% Specify Terminator
s1.terminator='';
get (s1);

%% 

fopen(s1);

%%
% commands
command_read_reg = 3;
reg_incr = 2;
reg_read_ADC = 6;
reg_temp = 7;

reg_NMR = 100;

which_command = reg_temp;

% I think the mode is specified by DataBits
if 1 %s1.DataBits==8
    % command:
    % increment a counter. 
    % Read back double(outstring)= is     1     3     2     0    10    56    67
    % final send char:
    % sendstring = [ device, 3,0,2,0,1,37,202];

    sendstring = [ device, command_read_reg,0,reg_incr,0,1];
    sendstring = [ device, command_read_reg,0,which_command,0,1];
    
    % crc will be added
    ss = append_crc(sendstring)

    %convert to hex code for the crc:
    dec2hex(ss(end-1:end))
end

templist = [];

tic
for ii=1:1*3600

    try 
        fprintf(s1,[ss])    
    catch
        disp(['Try to send ' num2str(double(sendstring))])
        disp 'Error. Cannot send to serial port.'
    end

    try
        outstring = fscanf(s1,'%c',7);  % return in char format, and 7 char
        %outstring = fread(s1); % this one works too.

        double(outstring);
        %pause(1)
    catch
        outstring = '';
        disp 'Error. Cannot read from serial port.'
    end

    
    % convert temp
    % the original data in in binary integer. Transmitted as hex.
    % LSB = 0.03125 deg C
    x= dec2hex(double(outstring(4:5)))';
    x=x(:)';
   
    templist(ii) = hex2dec(x);
    %fprintf(1,'%d.',ii);
    if mod(ii,1000)==0
        fprintf(1,'%d.',ii);
    end
    if mod(ii,10000)==0
        fprintf(1,'\r');
    end
    
    pause(1);
end
fprintf(1,'\r')

templist';
plot(templist*0.03125)

% if s1.Status == 'open'
%     fclose(s1)
% end

toc