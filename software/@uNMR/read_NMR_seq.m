function [res1] = read_NMR_seq(obj)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% read the NMR seq 
% seq is 64 copies of 64 bits data: 
% => 256 of 16-bits words to be acquired.


howmany = 64; % number of pulses
k=16;
y = [];

for ii=1:4

    y0 = read1seqchunk(obj,k);  % read 16, each is 8bytes
    y = [y y0];
    ii;
end

if 64*4 ~= size(y,2)
    disp(['Actual number of data read is ' num2str(length(y)) '.'])
    size(y)
else
    disp('Seq data read successful.')
    
end

    if obj.serial_port.Status(1)=='o'
        fclose(obj.serial_port);
    end
    
    y = reshape(y,4,64);
    % convert to uint32, it is important for reading bit pattern.
    res(1,:) = typecast(uint32(y(1,:)*2.^16+y(2,:)),'uint32');
    res(2,:) = typecast(uint32(y(3,:)*2.^16+y(4,:)),'uint32');
    
    res = double(res)';

    if nargout > 0
        res1 = res;
    end
    

    % print out the first 5
    %  | width(24) | amp(5) | phase(5) | space(24) | q(3) | acq(1) | ls(1) | le(1) |
    disp 'pulse length(us), delay(us)'
    for ii=1:64
        if res(ii,1)+res(ii,2) ~=0
        fprintf (1,'%d:%d,\t\t\t\t%d\n',ii,bitshift(res(ii,1),-8)/15, bitshift(res(ii,2),-6)/15)
        end
    end
end

% read less than chunksize
% return data is a vector of uint16
function res = read1seqchunk(obj,howmany)
% reg_code corresponds to the C program 
% // Modbus error codes
% eMBErrorCode eMBRegHoldingCB

% howmany : number of pulse segments to download, each segment is 4 16-bits
% 
% 
% reg_code = 110 is set for reading seq
reg_code = 110;

k = howmany;

    y = obj.read_register(reg_code,k*4,k*8+5);    % return two chars per register
    pause(0.005);
    
    y2=reshape(double(y),2,length(y)/2);
    
    %
    % convert to uint16, it is important for reading bit pattern.
    res = typecast(uint16(y2(1,:)*256+y2(2,:)), 'uint16');
    res = double(res);
    
    %pause(0.01)
    
end

