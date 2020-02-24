function [res] = read_NMR_data(obj,howmany)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% read the NMR data


if isempty(obj.serial_port) || (obj.serial_port.Status(1) == 'c')
    obj.init_serial();
end

if (nargin <1)
    disp 'Number of data points not specified.'
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
    reg_incr = 2;
    reg_temp = 7;

    reg_NMR = 100;
    reg_read_NMR_data = 104;


    % I think the mode is specified by DataBits
    if 1 %s1.DataBits==8
        % command:
        % increment a counter. 
        % Read back double(outstring)= is     1     3     2     0    10    56    67
        % final send char:
        % sendstring = [ device, 3,0,2,0,1,37,202];

        sendstring = [ obj.device, command_read_reg,0,reg_read_NMR_data,0,howmany];

        % crc will be added
        ss = obj.append_crc(sendstring)

        %convert to hex code for the crc:
        dec2hex(ss(end-1:end));
    end

    set(obj.serial_port,'timeout',2);

    try 
        fprintf(obj.serial_port,ss)    
    catch
        disp(['Try to send ' num2str(double(ss))])
        disp 'Error. Cannot send to serial port.'
    end

    try
        outstring = fscanf(obj.serial_port,'%c',5+2*howmany);  % return in char format, and 7 char
        %outstring = fscanf(obj.serial_port);       % this should work too,
                                                    % but take longer to wait for time out.

    catch
        disp(double(outstring))
        %outstring = '';
        disp 'Error. Cannot read from serial port.'
    end

    double(outstring);
    if isempty(outstring)
        res = [];
        disp 'Error. Does not read from serial port.'
    else
        
        ndata_read = double(outstring(3)); % max 252 numbers
        if (ndata_read > 1) & (ndata_read < 120)
           res = outstring(4:(4+ndata_read-1 ) );
        else
            res = [];
        end
    end
end
