function [res1] = download_NMR_seq(obj,seq)
% Send pulse sequence to uNMR chip
% YS nov 2017
%
% download the NMR seq 
% pulse seq is 64 copies of 64 bits data: 
% => seq = a 64*2 matrix, seq(:,1) is the high 32 bits, seq(:,2) the low
% bits
%
 
% print out the first 5
%  | width(24) | amp(5) | phase(5) | space(24) | q(3) | acq(1) | ls(1) | le(1) |
    disp 'pulse length(us), delay(us)'
    for ii=1:64
        if seq(ii,1)+seq(ii,2) ~=0
        fprintf (1,'%d:%d,\t\t%d\n',ii,bitshift(seq(ii,1),-8)/15, bitshift(seq(ii,2),-6)/15)
        end
    end

    if length(seq)~=64
        disp 'Input pulse sequence should be of length 64.'
        res1=0;
        return
    end
        
    % chunk size
k=16;

    for ii=1:4
        k=ii-1;
        y0 = download1seqchunk(obj,seq((1+16*k):16*ii,:) );  % write 16 pulses, each is 2 32-bits
        ii;
        double(y0);
        
    end

    if obj.serial_port.Status(1)=='o'
        fclose(obj.serial_port);
    end

    
    


end

% read less than chunksize
% return data is a vector of uint16
function res = download1seqchunk(obj,seq)
% reg_code corresponds to the C program 
% // Modbus error codes
% eMBErrorCode eMBRegHoldingCB

% number of pulse segments to download = 16, each is a 16-bits
% 
% reg_code = 110 is set for read/download seq
reg_code = 110;
k = 16;
% reformat the 32-bit number into 2 16 bits
if length(seq) ~=16
    disp 'Input pulse seq should be of length 16'
    res = 0;
    return;
end

DATA = [bitand(bitshift(seq(:,1),-16),2^16-1) bitand(seq(:,1),2^16-1)...
    bitand(bitshift(seq(:,2),-16),2^16-1) bitand(seq(:,2),2^16-1)...
];

    DATA = DATA';
    y = obj.write_registers(reg_code,DATA(:));    % return two chars per register
    pause(0.005);
    res =y;
    
end
