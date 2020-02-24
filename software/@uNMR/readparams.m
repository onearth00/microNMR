function [res] = readparams(obj)
% read all NMR parameters
% order:
% return 32 integer for each parameter


% read the status of the uNMR board, the number of data to be transferred
% n: 1: just the status, number of data point to transfer.
% n: 2: two numbers to return, one is npoints, the second is error code
% default: n=1


    howmany = 24; %this needs to be consistent with the number of var in pindex
   % x = obj.read_register(103,howmany*2,howmany*4+5);
    x = obj.read_register(103,howmany*2,howmany*2*2+5);

    if isempty(x)
        res = 0;
        return;
    else
        %x= dec2hex(double(x))';
        %x=x(:)';
        x = reshape(double(x),4,length(x)/4);
        x = [2^24 2^16 2^8 1]*x;
%        x = typecast(uint16(x(1,:)*256+x(2,:)), 'Uint16');
        res = double(x);

    end
end