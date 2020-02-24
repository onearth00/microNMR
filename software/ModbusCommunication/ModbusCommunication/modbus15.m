 function [Mout, err] = modbus15(s,device,address,Mout)

% Modbus mode 15, write multiple coils (binary 1/0)
% Setup to write 40 sequential coils from Mout, a 1x40
% array of 1 and 0's or a logical array.
% 
% Mout is a 1x40 array or logical array of numbers consisting of 1 or 0, Mout(1) 
%     corresponds to the first addressed memory
% err returns 1 if there is a communication error
% s is the serial port object associated with RS232 communication to a PLC
% device is the PLC device number for addressing multiple PLC
%     units on the same communication line, generally device='01';
%     note that device must be a 2 char array
% address is the starting address to be referenced as a 4 char HEX address
%     e.g. to address memory located at 02048 use address='0800'
%     
%     


mode = 15;
inloop = 1;
loopcount = 1;
err = 0;  

while inloop == 1;
    
    if loopcount == 3  %number of times to retry
        disp('Number of Retrys Exceeded in modbus15, Continuting with Program:')
        inloop = 0;  % exit the loop
        Mout = zeros(1,40);   % assign an output of zeros
        err = 1;
    else
       
        % Generate Bytes to write to the device        
        for i = 1:8
           B1(9-i) = Mout(i);   % first byte M48-M41     
           B2(9-i) = Mout(i+8); % second byte M56-M49        
           B3(9-i) = Mout(i+16);% Third byte M64-M50        
           B4(9-i) = Mout(i+24); % Fourth byte M72-M65         
           B5(9-i) = Mout(i+32); % fifth byte M80-M73        
        end

        %rawstring is device, mode, starting address Hi, Lo, Quantity of
        %outputs Hi, Lo, Number of bytes (5)
        rawstring = [':',device,'0F',address,'00','28','05',...
            dec2hex(bin2dec(num2str(B1)),2),dec2hex(bin2dec(num2str(B2)),2),...
            dec2hex(bin2dec(num2str(B3)),2),dec2hex(bin2dec(num2str(B4)),2),...
            dec2hex(bin2dec(num2str(B5)),2)];
 

        [report, string] = LRC(rawstring,2);  %append LRC to rawstring

        % mode 15 force multiple coils M41-M81
        if report == 0  % if LRC return an error
            disp([datestr(now),'Error obtaining an LRC for modbus15, Retrying...'])
            pause(0.1)
            loopcount = loopcount+1;
        else

        try
            fprintf(s,string)
            out = fscanf(s);
            pause(0.2)
        catch
            out = '';
            disp([datestr(now),'Catch in modbus15'])
        end

        end


        %Check for an Empty output
        if isempty(out)  % no output leads to a retry and then simply moving on
            disp([datestr(now),'No signal returned to modbus15, Retrying...'])
            pause(0.1)
            loopcount = loopcount+1;

        else
            %LRC check and resend
            [LRCcheck, string] = LRC(out,1);
            %LRC Checking
            if LRCcheck == 0  % Check that the LRC is correct (0 is incorrect)
                disp([datestr(now),'LRC is not consistant modbus15, Resending...'])
                pause(0.1)
                loopcount = loopcount+1;

            %Mode checking
            elseif hex2dec(out(4:5)) ~= mode  %check that the returned mode is not error
                errback = moderr(out,mode);  % if it is not == mode then get error report
                disp([datestr(now),'Improper mode returned to modbus15, Retrying...'])
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




