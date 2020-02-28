function [outdata] = nmrblc(indata,w,blc)
% NMR data baseline correction
% blc : ranges use as baseline, e.g. 
% blc=[-1000 -500 10 50], then [-1000 -500] and [10 50] will be used as
% baseline
% 
% Using only real part of the data.

%
% To implement 

outdata = zeros(size(indata));

% get blc data for fitting of the polynomial coefficients
    for ii = 1:length(blc)
        [mm,n] = min(abs(w-blc(ii)));

        blcpts(ii) = n;
    end

    theBLC = [];
    wBLC = [];
    ptBLC = [];
    for ii = 1:2:floor(length(blcpts))
        themax = max(blcpts(ii),blcpts(ii+1));
        themin = min(blcpts(ii),blcpts(ii+1));

        %theBLC = [theBLC; indata(themin:themax,:)];
        wBLC = [wBLC w(themin:themax)];
        ptBLC = [ptBLC (themin:themax)];
    end
    theBLC = real(indata(ptBLC,:));
    
    for ii= 1:size(theBLC,2)
        ii
        c = GetCoefficients(wBLC',theBLC(:,ii));
        outdata (:,ii) = indata(:,ii) - polyval(c,w');
    end
    disp 'blc done'

return

function [c] = GetCoefficients(w,indata) 
% order 2 for now

c = polyfit(w,indata,4);

return

function [outdata] = GetConstantBLC(indata,w,blc)
    for ii = 1:length(blc)
        [mm,n] = min(abs(w-blc(ii)));

        blcpts(ii) = n;
    end

    theBLC = 0;
    thePTS = 0;
    disp 'nmr baseline correction'
    for ii = 1:floor(length(blcpts)/2)
        themax = max(blcpts(ii),blcpts(ii+1));
        themin = min(blcpts(ii),blcpts(ii+1));

        thePTS = thePTS + themax - themin;
        theBLC = theBLC + sum(indata(themin:themax,:),1);
    end

    outdata = indata - ones(size(indata,1),1)*(theBLC./thePTS);
return        