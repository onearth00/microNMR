function [outdata] = nmrphc2(indata,phi,w,pivot)
% NMR data phase correction, input phi in degree
% phi = [phc0 phc1]
% phase = phc0 + phc1*(w - pivot)
% function [outdata] = nmrphc(indata,phi,w,pivot)
%
% phc0 : zeroth order ph correct
% phc1 : 1st order ph correction, phc1 for the full range
% w : freq axis in hertz
% pivot : freq that phase = phc0

%
% To implement pivot point, set w with the desired peak at w=0


global nmrPHASE0
global nmrPHASE1

wRange = max(w) - min(w);

switch length (phi)
    case 2
        
        disp 'nmr phase correction, 1st & 0th order'
        phase = pi/180*(phi(1) + phi(2)*(w-pivot)./wRange);
        phc = exp(-1i*phase') * ones(1,size(indata,2));
        outdata= indata .* phc;
        

    case 1
        if phi ~= 0
            disp 'nmr phase correction, 0th order'
            phase = pi/180*(phi(1) );
            outdata= indata .*exp(-1i*phase);
        else
            outdata = indata;
        end
    otherwise
        disp 'No input phase correction'
end

nmrPHASE0 = phi(1);
if length(phi) == 2
    nmrPHASE1 = phi(2);
end
return

