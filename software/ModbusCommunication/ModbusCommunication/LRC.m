function [report, string] = LRC(out,mode)
% [report, string] = LRC(out,mode)
% Calculate the Longitudinal redundnacy check of a series of hex numbers to
% be sent to Eaton PLC controller.  
%
% out is the string to either be checked (mode 1) or to have an LRC
% generated and appended (mode 2)
% Mode 1:  Report is 1 for LRC being correct, 0 for incorrect
% Mode 2: Report is 1 for no problems, 0 for error
%           string is the output to be written to the PLC
%
%  When the total addition in the LRC is greater then 8bits the LRC is
%  composed of the 2's complament of negation using the lowest 8 bits:

% LRC.m - The value appended to the end of each communication to assure 
% that the data received is not corrupted.  The LRC is the 2's compliment 
% negation of the sum.  When the total adition in the LRC constitutes a 
% number greater then 8bits only the lowest 8bits are used to compute the LRC. 
%  LRC.m has two modes, in mode 1 it compares the LRC received to one 
%  calculated and in mode 2 it calculates an LRC and appends it onto a 
%  string for outgoing communication.  LRC.m uses a try-catch structure 
%  to ensure that if an error occurs in calculating the LRC, possibly due 
%  to an unrecognized character being received, the program can continue.  
% 
% All Modbus communications are in Hex.  The modbus communication starts 
% with a ':' followed by the address of the device the communication is
%  meant for '01'.  Following the device number is the mode '02' 
%  (read multiple digital).  in the case of mode 2 this is followed by
%   the starting address '0800' and then the number of points to read 
%   '0028'  (40 points).  At the end of the communication is appended the 
%   Longitudinal Redundancy Check.
% 
% As mentioned previously, the included modbus programs were written for 
% a process control program to interface with specific variables on the PLC.  
% These addresses can be modified, however note that when changing any of 
% the strings to be sent to the PLC, the 2-byte Longitudinal redundancy 
% code must be updated.  This can be done using the code:
% [report,StringOut] = LRC(StringIn,2)
% where StringIn is the data to be written to the PLC without the LRC 
% i.e. [':','01','02','08','00','00','28']
% the returned variable StringOut contains the LRC appended string ':010208000028CD'.
% 




%Test Case: should return 1E
% out = ':01032021341A2C162D13240C8023281F401B5800000000000000000000000000000000';
% mode = 2;

% Check that the LRC of a message is valid
try

if mode == 1  % mode for checking if LRC is correct

    Lout = length(out);   % length of incoming string
    outLRC = out(Lout-3:Lout-2);  % last two characters are CR/LF
    outmess = out(1:Lout-4);  % message portion of the sting to analyze
    
    %Put each Hex set in a different row
    for j = 1:(length(outmess)-1)/2
        mes(j,:) = outmess(2*j:2*j+1);
    end

    decmes = hex2dec(mes);  % convert to dec
    sumdec = sum(decmes);  %sum the decimal values
    hexsum = dec2hex(sumdec,4); % generate a 4 digit hex number
    binsum = dec2bin(sumdec,8); % genearte 8bit binary number

    % Handle the number being large
    if length(binsum) > 8
        binsum = binsum(length(binsum)-7:length(binsum));  % grab the last 8 bit binary number
    end
    
	% Perform the inversion of 1's and 0's
    empbin = ['00000000'];  % start with an empty binary number
    firstfind = 0;
    for i = 1:length(binsum)
        if binsum(end+1-i) == '0'
            if firstfind == '0'
                %leave as 0			% leave first 0's found as 0
            elseif firstfind == 1
               empbin(end+1-i) = '1';    %swap a 1 for 0
            end
        elseif binsum(end+1-i) == '1'
            if firstfind == 0
                empbin(end+1-i) = '1';
                firstfind = 1;
            elseif firstfind == 1
                empbin(end+1-i) = '0';
            end
        else
                disp('Error in LRC calculation')
        end
    end

    CalcLRC = bin2dec(empbin);  % LRC calculated by the program
    
    if CalcLRC == hex2dec(outLRC)  % compare the caluclated and given LRC
        report = 1;  % LRC is correct
    else
        disp(['LRC Inconsistant, PLC gives: ',num2str(hex2dec(outLRC)),...
            ' Calculated LRC is: ',num2str(CalcLRC)])
        report = 0;
    end
    string = out;

    
% Calculate the LRC for a string: output is the string with LRC appended    
elseif mode == 2
    %Put each Hex set in a different row
    for j = 1:(length(out)-1)/2
        mes(j,:) = out(2*j:2*j+1);
    end

    decmes = hex2dec(mes);  % convert to dec
    sumdec = sum(decmes);  %sum the decimal values
    hexsum = dec2hex(sumdec,4); % generate a 4 digit hex number
    binsum = dec2bin(sumdec,8); % genearte 8bit binary number
    
    % Handle the number being large
    if length(binsum) > 8
        binsum = binsum(length(binsum)-7:length(binsum));
    end
    
    empbin = ['00000000'];  % start with an empty binary number
    
    firstfind = 0;
    for i = 1:length(binsum)
        if binsum(end+1-i) == '0'
            if firstfind == '0'
                %leave as 0
            elseif firstfind == 1
               empbin(end+1-i) = '1';    %swap a 1 for 0
            end
        elseif binsum(end+1-i) == '1'
            if firstfind == 0
                empbin(end+1-i) = '1';
                firstfind = 1;
            elseif firstfind == 1
                empbin(end+1-i) = '0';
            end
        else
                disp('Error in LRC calculation')
        end
    end

    CalcLRC = dec2hex(bin2dec(empbin),2);  % LRC calculated by the program
    Lout = length(out);
    out(Lout+1:Lout+2) = CalcLRC;
    string = out;
    report = 1;
else
    disp(['Improper selection of mode in LRC.m to: ',num2str(mode)])
    report = 0;
    string = '';
end
    
    
catch
    report = 0;
    string = [''];
    disp('Catch in LRC')
end

    
