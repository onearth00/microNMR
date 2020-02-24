function [res] = readstatus(obj,n)
% read the status of the uNMR board, the number of data to be transferred
% n: 1: just the status, number of data point to transfer.
% n: 2: two numbers to return, one is npoints, the second is error code
% default: n=1

% whether serial returns
% in acquisition 
% data ready to be download
% return 2 byte
% 

% Try to read two reg. First one is status, second is error code
if nargin ==1
    howmany =1;
else
    howmany = n;
end

if howmany == 1
    x = obj.read_1register(103);

    if isempty(x)
        res = 0;
        return;
    else
        x= dec2hex(double(x))';
        x=x(:)';

        res = hex2dec(x);
    end
end

if howmany == 2
    x = obj.read_register(103,howmany,howmany*2+5);

    if isempty(x)
        res = 0;
        return;
    else
        %x= dec2hex(double(x))';
        %x=x(:)';
        x = reshape(double(x),2,length(x)/2);
        x = typecast(uint16(x(1,:)*256+x(2,:)), 'Uint16');
        res = double(x);

    end
    pause(0.01)
end

