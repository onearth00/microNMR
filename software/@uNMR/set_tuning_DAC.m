function [res] = set_tuning_DAC(obj,value)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% 

if isempty(obj.serial_port)
    obj.init_serial();
end

if nargin <1
    disp 'Tuning DAC set to zero.'
    theValue = 0;
else
    fprintf(1,'Tuning DAC value %d',value);
    theValue = value;
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
    command_set_reg = 6;
    
    reg_DAC = 3;
    
    reg_incr = 2;
    reg_temp = 7;

    reg_NMR = 100;

    usNRegs_NMR = 2;
    usAddress_FID = 1;
    
    command = command_set_reg;
    which_reg = reg_NMR;
    reg_return_char = 6;
    usNRegs = usNRegs_NMR;
    usAddress = usAddress_FID;

    
    % I think the mode is specified by DataBits
    if 1 %s1.DataBits==8
        % command:
        % increment a counter. 
        % Read back double(outstring)= is     1     3     2     0    10    56    67
        % final send char:
        % sendstring = [ device, 3,0,2,0,1,37,202];

        % format
        sendstring = [ obj.device, command,0,reg_temp,0,1];

        % crc will be added
        ss = obj.append_crc(sendstring)

        %convert to hex code for the crc:
        dec2hex(ss(end-1:end));
    end

    return

    try 
        fwrite(obj.serial_port,ss)    
    catch
        disp(['Try to send ' num2str(double(ss))])
        disp 'Error. Cannot send to serial port.'
    end

    try
        outstring = fscanf(obj.serial_port,'%c',7);  % return in char format, and 7 char
        %outstring = fscanf(obj.serial_port);       % this should work too,
                                                    % but take longer to wait for time out.

    catch
        outstring = '';
        disp 'Error. Cannot read from serial port.'
    end

    x= dec2hex(double(outstring(4:5)))';
    x=x(:)';
   
    res = hex2dec(x)*0.03125;
   

end
