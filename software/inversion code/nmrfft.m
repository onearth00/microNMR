function [outdata,w2] = nmrfft(indata,dwell)
% fft NMR data, 1D ttransform, work for 2D data
% 
nd = size(indata);

if nargin == 1
    dw = 1;
else
    dw = dwell;
end

if nargout > 0
    outdata = fftshift(fft(indata,[],1),1);
end

if nargout > 1
    w2 = (-nd(1)/2:1:nd(1)/2-1) ./ nd(1) ./dw;
end
return

