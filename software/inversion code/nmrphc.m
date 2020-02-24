function [outdata] = nmrphc(indata,phi)
% NMR data phase correction, input phi in radian
% function [outdata] = nmrphc(indata,phi)
global nmrPHASE0
global nmrPHASE1

if phi ~= 0
    disp 'nmr phase correction'
    outdata= indata .*exp(1i*phi);
else
    outdata = indata;
end

nmrPHASE0 = phi;

return

