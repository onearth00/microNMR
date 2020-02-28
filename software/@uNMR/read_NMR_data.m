function [res] = read_NMR_data(obj,npts)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
%
% read 16 bit NMR data
% Input: npts: the number of data points (complex) to be acquired.
%
%

howmany = npts*2;

% chunksize = 120; % max chunk to transfer via serial link
chunksize = 120; % max chunk to transfer via serial link 1/25/2018


residue = mod(howmany,chunksize);
nchunk = floor(howmany/chunksize);
    
%k=howmany;

y = [];

for ii=1:nchunk
    k=chunksize;
    y0 = read1chunk(obj,k);
    y = [y y0];
    ii;
end

    k=residue;
    if  k> 0
        y0 = read1chunk(obj,k);
        y = [y y0];
    end
    size(y);
%disp(['NMR data:' num2str(y)])
%disp([howmany sqrt(max(y)-1) length(y)])
% pause(0.01)

res = reshape(y,2,length(y)/2)';
res = res(:,1) + 1i*res(:,2);

if howmany ~= length(y)
    disp(['Actual number of data read is ' num2str(length(y)) '.'])
else
    disp('Data read successful.')
end

    if obj.serial_port.Status(1)=='o'
        fclose(obj.serial_port);
    end
end

%% read 16 bit NMR data
% read less than chunksize
function res = read1chunk(obj,howmany)
    
    switch howmany
        case 10
            kk = [10];
        case 46
            kk = [46];
        otherwise
            kk = howmany;
    end
    
    y=[];
    
    for ii=kk
        k=ii;
        y0 = obj.read_register(104,k,k*2+5);    % return two chars per register
        y=[y y0];
        pause(0.005);
    end
    
    y2=reshape(double(y),2,length(y)/2);
    
    %
    % NMR data is int16 format
    % convert to int16 in order to read positive/negative values 
    res = typecast(uint16(y2(1,:)*256+y2(2,:)), 'int16');
    res = double(res);
    
    %pause(0.01)
    
end
% % read 32 bit NMR data 1/25/2018
% read less than chunksize
% function res = read1chunk(obj,howmany)
%     
%     switch howmany
%         case 10
%             kk = [10];
%         case 46
%             kk = [46];
%         otherwise
%             kk = howmany;
%     end
%     
%     y=[];
%     
%     for ii=kk
%         k=ii;
%         y0 = obj.read_register(104,k*2,k*2*2+5);    % return two chars per register
%         y=[y y0];
%         pause(0.005);
%     end
%     
%     y2=reshape(double(y),4,length(y)/4);
%    y2 = [2^24 2^16 2^8 1]*y2;
%     
%     
%     NMR data is int32 format
%     convert to int32 in order to read positive/negative values 
%     y2 = typecast(uint32(y2(1,:)*2^24+y2(2,:)*2^16+y2(3,:)*2^8+y2(4,:)), 'int32');
%     y2 = typecast(uint16(y2(1,:)*256+y2(2,:)), 'int16');
%     res = double(y2);
%     
%     pause(0.01)
%     
% end