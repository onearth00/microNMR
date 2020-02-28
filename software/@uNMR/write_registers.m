function [res] = write_registers(obj,reg,DATA)
% format: device, function, register address(2char), DATA (2char)
% format: starting register, nreg: number of reg
% format: input data DATA: nreg number of dec data.
%
% format: device, 16, {0,reg}, nreg, 
%
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% 
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

 nreg = length(DATA);
 if nreg < 2
     disp 'this function is for nreg > 2.'
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
    
    
    command_write_nreg = 16;    %write t omultiple reg.
    %format: device, starting_reg_addr (2char),Nreg(2char),bytes(2byte per
    %           reg),DATA, crc
    
%     reg_DAC = 3;
%     
%     reg_incr = 2;
%     reg_temp = 7;
% 
%     reg_NMR = 100;
% 
%     usNRegs_NMR = 2;
%     usAddress_FID = 1;
    
    which_command = command_write_nreg;
    which_reg = reg;
    Nreg = length(DATA);
    %reg_return_char = 6;
    
    % I think the mode is specified by DataBits
    if obj.serial_port.DataBits==8

        % format 
        %sendstring = [ obj.device,which_command,0,which_reg,DATA(1),DATA(2)];
        sendstring = [ obj.device,which_command,0,which_reg,0,Nreg,Nreg*2,obj.number2Twobytes(DATA)];

        % crc will be added
        % Notice a problem. When one element is 10, transmit as 0
        % check to see if casting make a diff
        %ss = cast( obj.append_crc(sendstring), 'uint32')
        ss = obj.append_crc(sendstring);
        % convert to hex code for the crc:
        % dec2hex(ss(end-1:end));
    end

    try 
        %fprintf(obj.serial_port, ss)  ;
        fwrite(obj.serial_port, ss)  ;
        %outstring = fscan(obj.serial_port);
    catch
        disp(['Try to send ' num2str(double(ss))])
        disp 'Error. Cannot send to serial port.'
    end
    %pause(0.01);
%     if obj.serial_port.Status(1)=='o'
%         disp 'port open at write_registers'
%     else
%         disp 'port close at write_registers'
%     end
    
    outstring = fscanf(obj.serial_port,'%c',8);
    res = outstring;
    double(res);
   
%     if obj.serial_port.Status(1)=='o'
%         fclose(obj.serial_port);
%     end
    
    %pause(0.01)
end
