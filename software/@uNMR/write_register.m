function [res] = write_register(obj,reg,usNReg,usAddress)
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


if obj.serial_port.status=='closed'
    fopen(obj.serial_port);
end

if obj.serial_port.status=='closed'
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
    
    which_command = command_write_reg;
    which_reg = reg;
    reg_return_char = 6;
 
    
    % I think the mode is specified by DataBits
    if obj.serial_port.DataBits==8
        % command:
        % increment a counter. 
        % Read back double(outstring)= is     1     3     2     0    10    56    67
        % final send char:
        % sendstring = [ device, 3,0,2,0,1,37,202];

        % format 
        sendstring = [ obj.device,which_command,0,which_reg,0,1];

        % crc will be added
        ss = obj.append_crc(sendstring);

        % convert to hex code for the crc:
        % dec2hex(ss(end-1:end));
    end

    try 
        fwrite(obj.serial_port,ss)  ;
        %fprintf(obj.serial_port,ss)    
    catch
        disp(['Try to send ' num2str(double(ss))])
        disp 'Error. Cannot send to serial port.'
    end


   

end
