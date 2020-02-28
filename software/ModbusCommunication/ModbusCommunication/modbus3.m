function [Din, err] = modbus3(s,device,address)

% Modbus mode 3, read multiple poisitive integers "words"
% Setup to read and interpret 16 sequential words 
% output Din contains a 1x16 array
% 
% Din is a 1x16 array of numbers the memory is mapped such that 
%     Din(1) corresponds to first memory addressed in the PLC
% err returns 1 if there is a communication error
% s is the serial port object associated with RS232 communication to a PLC
% device is the PLC device number for addressing multiple PLC
%     units on the same communication line, generally device='01';
%     note that device must be a 2 char array
% address is the starting address to be referenced as a 4 char HEX address
%     e.g. to address memory located at 02048 use address='0800'
% 

mode = 3;
inloop = 1;
loopcount = 0;
err = 0;


while inloop == 1;
 
    if loopcount == 3
        disp('Number of Retrys Exceeded for modbus3.m, Continuting with Program:')
        inloop = 0;  % exit the loop
        Din = zeros(1,16);   % assign an output of zeros
        err = 1;
        pause(0.1)
    else

        % mode 3 read holding registers D0-D15
      try
          rawstring = [':',device,'03',address,'00','10'];  
          [report, string] = LRC(rawstring,2);
          fprintf(s,string)
            
            out=fscanf(s);
            pause(0.1)
        % Output is in oder D0, D1 etc...

        %Check for an Empty output
        if isempty(out)  % no output leads to a retry and then simply moving on
            disp([datestr(now),'No signal returned to modbus3, Retrying...'])
            out = out;
            pause(0.1)
            loopcount = loopcount+1;

        else
            %LRC check and resend
            [LRCcheck, string] = LRC(out,1);
            %LRC Checking
            if LRCcheck == 0  % Check that the LRC is correct (0 is incorrect)
                disp([datestr(now),'LRC is not consistant, Resending...'])
                pause(0.1)
                loopcount = loopcount+1;

            %Mode checking
            elseif hex2dec(out(4:5)) ~= mode  %check that the returned mode is not error
                errback = moderr(out,mode);  % if it is not == mode then get error report
                disp([datestr(now),'Improper mode returned to modbus3, Retrying...'])
                pause(0.1)
                loopcount = loopcount+1;

            else
                %obtain data from file:
                outshort = out(5:end-4);
                for k = 1:16
                    Din(k) = hex2dec(outshort(4*k:4*k+3));
                end
                inloop = 0;
            end
        end

      catch
            Din = zeros(1,16);
            err = 1;
            disp('Catch in modbus3')
      end
    end
            
end

  


