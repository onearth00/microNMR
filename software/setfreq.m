function [nint, nfrac] = setfreq(infreq)   
 k = 62; 
 freqxtal = 32e6;
 TWO_POW_24 = 2^24;
 
 x = infreq*k/freqxtal; 
 nint = floor(x);
 x = x-nint;

 nfrac = floor(x*TWO_POW_24);
end