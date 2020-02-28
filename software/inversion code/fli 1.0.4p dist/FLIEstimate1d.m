
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Original March 2001
%	modified April 2001, September 2002.
%	
%	Rename for FLI.m for fast Laplace Inversion
%
%	Details were published in 
%	L. Venkataramanan et. al., IEEE Tran. Signal Proc. 50, 1017-1026 (May, 2002).	 %
%	Y.-Q. Song, et al., J. Magn. Reson. 154, 261-268(2002).			    			 %
%	M D Hurlimann and L Venkataramanan, J. Magn. Reson. 157, 31 (2002).		    	 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

function [FEst, CompressedData,Chi,Alpha_heel] = FLIEstimate1d(Data,  U1, V1, ...
                    S1, AlphaStart, NoiseStd, Alpha_Auto, ConditionNumber)
 
