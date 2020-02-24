function [Dout, err] = modbus16(s,device,address,Dout)
% 
% Modbus mode 16, write multiple poisitive integers "words"
% Setup to write and 16 sequential words contained in Dout
% as a 1x16 array
% 
% Dout is a 1x16 array of positive integers the memory is mapped such that 
%     Din(1) corresponds to first memory addressed in the PLC
% err returns 1 if there is a communication error
% s is the serial port object associated with RS232 communication to a PLC
% device is the PLC device number for addressing multiple PLC
%     units on the same communication line, generally device='01';
%     note that device must be a 2 char array
% address is the starting address to be referenced as a 4 char HEX address
%     e.g. to address memory located at 02048 use address='0800'
% 
% 

mode = 16;
inloop = 1;
loopcount = 1;
err = 0;  

while inloop == 1;
    
    if loopcount == 3
        disp('Number of Retrys Exceeded in modbus16, Continuting with Program:')
        inloop = 0;  % exit the loop
        Dout = zeros(1,16);   % assign an output of zeros
        err = 1;
    else
        
        % Generate Bytes to write to the device        
        Dout = abs(Dout);
        B(1:4) = dec2hex(round(Dout(1)),4);
        for i = 1:(length(Dout)-1)
            B(4*i+1:4*i+4) = dec2hex(round(Dout(i+1)),4);
        end

        % device, mode, address, Num of Registers Hi,Lo, Byte count,
        % Data(B)
        rawstring = [':',device,'10',address,'00','10','20',B];


        [report, string] = LRC(rawstring,2);

        if report == 0
            disp([datestr(now),'Error obtaining an LRC for modbus16, Retrying...'])
            pause(0.1)
            loopcount = loopcount+1;
        else

        % mode 16 preset multiple registers 
            try
                fprintf(s,string)
                out = fscanf(s);
                pause(0.2)
            catch
                out = '';
                disp([datestr(now),'Catch in modbus16'])
            end


        end


        %Check for an Empty output
        if isempty(out)  % no output leads to a retry and then simply moving on
            disp([datestr(now),'No signal returned to modbus16, Retrying...'])
            pause(0.1)
            loopcount = loopcount+1;

        else
            %LRC check and resend
            [LRCcheck, string] = LRC(out,1);
            %LRC Checking
            if LRCcheck == 0  % Check that the LRC is correct (0 is incorrect)
                disp([datestr(now),'LRC is not consistant in modbus16, Resending...'])
                pause(0.1)
                loopcount = loopcount+1;

            %Mode checking
            elseif hex2dec(out(4:5)) ~= mode  %check that the returned mode is not error
                errback = moderr(out,mode);  % if it is not == mode then get error report
                disp([datestr(now),'Improper mode returned to modbus16, Retrying...'])
                pause(0.1)
                loopcount = loopcount+1;

            else
                % report no errors
                err = 0;
                inloop = 0;
            end
        end

    end
            
end



