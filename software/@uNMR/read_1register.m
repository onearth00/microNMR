function [res] = read_1register(obj,reg)
% function [res] = read_register(obj,reg)
% reg: register to receive the data
% 
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% 

    command_read_reg = 3;
    command_write_reg = 6;
    
if isempty(obj.serial_port) || (obj.serial_port.Status(1) == 'c')
    obj.init_serial();
end

if (nargin <1) || (nargin ~= 2)
    disp 'No register specified.'
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
    command_write_reg = 6;
    reg_return_char = 7;
    command_write_nreg = 16;
    
    reg_DAC = 3;
    
    reg_incr = 2;
    reg_temp = 7;

    reg_NMR = 100;

    usNRegs_NMR = 2;
    usAddress_FID = 1;
    
    
    which_command = command_read_reg;
    which_reg = reg;
   
    % I think the mode is specified by DataBits
    if 1 %s1.DataBits==8
        % command:
        % increment a counter. 
        % Read back double(outstring)= is     1     3     2     0    10    56    67
        % final send char:
        % sendstring = [ device, 3,0,2,0,1,37,202];

        % format
        sendstring = [ obj.device, which_command,0,which_reg,0,1];

        % crc will be added
        ss = obj.append_crc(sendstring);
        %disp(['Try to send ' num2str(double(ss))])
        %convert to hex code for the crc:
        dec2hex(ss(end-1:end));
    end

    

    try 
        fwrite(obj.serial_port,ss)  ;
        %fprintf(obj.serial_port,ss)    ;
        %outstring = fscanf(obj.serial_port);
    catch
        disp(['Try to send ' num2str(double(ss))])
        disp 'Error. Cannot send to serial port.'
    end

    try
        if reg_return_char ~=0
            outstring = fscanf(obj.serial_port,'%c',reg_return_char);  % return in char format, and 7 char
        %outstring = fscanf(obj.serial_port);       % this should work too,
                                                    % but take longer to wait for time out.
        else
            outstring = fscanf(obj.serial_port);
        end
    catch
        outstring = '';
        disp 'Error. Cannot read from serial port.'
    end

    if obj.serial_port.Status(1)=='o'
        fclose(obj.serial_port);
    end
    
    %disp(['Outstring='    num2str(double(outstring))])
    
    if isempty(outstring)
        disp 'No return characters'
        res = [];
    else
        res = outstring(4:end-2);
    end
   

end
