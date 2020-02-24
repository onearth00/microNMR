function [outdata] = nmrshift(indata,n)
% NMR data shift, left (positive) or right shift
% function [outdata] = nmrshift(indata,n)

nd = size(indata);
outdata = zeros(nd);

if n == 0
    outdata = indata;
    return;
end

if n>0
    disp 'left shift'
    outdata(1:nd(1)-n,:) = indata(n+1:nd(1),:);
else
    disp 'right shift'
    outdata(n+1:nd(1),:) = indata(1:nd(1)-n,:);
end

return

