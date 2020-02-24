function [res] = write_1register(obj,reg,DATA)
% format: device, function, register address(2char), DATA (2char) 
% format: input data can be two numbers or one number.
%
% format: device, 06, {0,reg}, {DATA_hi, DATA_lo}
%
% serial connection to uNMR pcb
% YS nov 30, 2016 

 
if nargin <1
    disp 'Nothing to write.'
    return;
end

if isempty(obj.serial_port) 
    obj.init_serial();
end


if obj.serial_port.status(1)=='c'
    fopen(obj.serial_port);
end

if obj.serial_port.status(1)=='c'
    disp 'Could not open serial port'
    return;
end

% currently used for uNMR serial port
% CRC, for RTU mode, 8 bit data, binary
% input is not a string, but a decimal numbers
% also no ':'
% ASCII mode
% device = '01';
%sendstring = [':',device, '03', '00', '07','00', '01'];


    outstring=[];
    % commands
    command_read_reg = 3;
    command_write_1reg = 6;
    
    command_write_nreg = 16;    %write to multiple reg.
    %format: device, starting_reg_addr (2char),Nreg(2char),bytes(2byte per
    %           reg),DATA, crc
    
    reg_DAC = 3;
    
    reg_incr = 2;
    reg_temp = 7;

    reg_NMR = 100;

    usNRegs_NMR = 2;
    usAddress_FID = 1;
    
    which_command = command_write_1reg;
    which_reg = reg;
    Nreg = length(DATA)/2;
    %reg_return_char = 6;
    
    if length(DATA)==2  % input data is defined for two-bytes in hex value
        theDATA = DATA;
    else
        % just take the first data and turn it into two-byte hex
        theDATA(1) = floor(DATA(1)/256);
        theDATA(2) = mod(DATA(1),256);        
    end
    % I think the mode is specified by DataBits
    if obj.serial_port.DataBits==8

        % format 
        %sendstring = [ obj.device,which_command,0,which_reg,DATA(1),DATA(2)];
        sendstring = [ obj.device,which_command,0,which_reg,theDATA(1),theDATA(2)];

        % crc will be added
        ss = obj.append_crc(sendstring);

        % convert to hex code for the crc:
        % dec2hex(ss(end-1:end));
    end

    try 
        fwrite(obj.serial_port,ss)  ;
        %fprintf(obj.serial_port,ss)  ;
        %outstring = fscan(obj.serial_port);
    catch
        disp(['Try to send ' num2str(double(ss))])
        disp 'Error. Cannot send to serial port.'
    end

    outstring = fscanf(obj.serial_port,'%c',8);
    res = outstring;
    double(res);
   
    if obj.serial_port.Status(1)=='o'
        fclose(obj.serial_port);
    end
    

end
