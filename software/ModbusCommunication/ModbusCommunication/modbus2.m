function [Min, err] = modbus2(s,device,address)

% Modbus mode 2, read multiple coils (binary 1/0)
% Setup to read and interpret 40 sequential coils
% output Min contains a 1x40 logical matrix
% 
% Min is a 1x40 logical array of numbers consisting of 1 or 0, Min(1) 
%     corresponds to the first addressed memory
% err returns 1 if there is a communication error
% s is the serial port object associated with RS232 communication to a PLC
% device is the PLC device number for addressing multiple PLC
%     units on the same communication line, generally device='01';
%     note that device must be a 2 char array
% address is the starting address to be referenced as a 4 char HEX address
%     e.g. to address memory located at 02048 use address='0800'
% 


mode = 2;
inloop = 1;
loopcount = 0;
err = 0; 

% put together data to send to PLC
utosend =[':',device,'02',address,'00','28'];  %compile info to send  

[report, tosend] = LRC(utosend,2);  %append LRC to 


while inloop == 1;
    
    if loopcount == 3
        disp('Number of Retrys Exceeded by modbus2, Continuting with Program:')
        inloop = 0;  % exit the loop
        Min = zeros(1,40);  %assign an output of zeros
        err = 1;
    else
    
        % mode 2 Read M0-M40
        try
            fprintf(s,tosend)
            out = fscanf(s);
            pause(0.1)
        catch
            Min = zeros(1,40);
            err = 1;
            disp('Catch in modbus2')
        end

        %Check for an Empty output
        if isempty(out)  % no output leads to a retry and then simply moving on
            disp([datestr(now),'No signal returned to modbus2, Retrying...'])
            pause(0.1)
            loopcount = loopcount+1;

        else
            %LRC check and resend
            [LRCcheck, string] = LRC(out,1);
            %LRC Checking
            if LRCcheck == 0  % Check that the LRC is correct (0 is incorrect)
                disp([datestr(now),'LRC is not consistant in modbus2, Resending...'])
                pause(0.1)
                loopcount = loopcount+1;

            %Mode checking
            elseif hex2dec(out(4:5)) ~= mode  %check that the returned mode is not error
                errback = moderr(out,mode);  % if it is not == mode then get error report
                disp([datestr(now),'Improper mode returned to modbus2, Retrying...'])
                pause(0.1)
                loopcount = loopcount+1;

            else
                %obtain data from file: :0102050900000000EF
                B1 = dec2bin(hex2dec(out(8:9)),8);
                B2 = dec2bin(hex2dec(out(10:11)),8);
                B3 = dec2bin(hex2dec(out(12:13)),8);
                B4 = dec2bin(hex2dec(out(14:15)),8);
                B5 = dec2bin(hex2dec(out(16:17)),8);

                for i = 1:8
                    Mi(i) = B1(9-i);  % first byte M7-M0
                    Mi(8+i) = B2(9-i);  % second byte M15-M8
                    Mi(16+i) = B3(9-i);  % Third byte M23-M16
                    Mi(24+i) = B4(9-i);  % Fourth byte M31-M24
                    Mi(32+i) = B5(9-i);  % fifth byte M39-M32
                end

                for j = 1:length(Mi) % convert to a logical matrix
                    Min(j) = Mi(j) == '1';
                end
                inloop = 0;
            end
        end

    end
            
end

 


