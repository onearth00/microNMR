function [FEst, parameter, Fitdata] = FLI1d(inputData,inKernel,inAlpha,U,S,V)
%
%   Fast Laplace inversion for 1d data
%   function [FEst, parameter, Fitdata] = FLI1d(inData,inKernel,inAlpha)
%   function [FEst, parameter, Fitdata] = FLI1d(inData,inKernel,inAlpha,U,S,V)
%
%	inData : data vector
%	inKernel: kernel matrix
% 	inAlpha: 0:BRD method, positive constant: fixed reg, -1:full span, -2:t1heel method.
%	U,S,V: K=U*S*V', if they are provided, then SVD of K will be skipped.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%	Original March 2001 
%	modified April 2001, September 2002.
%	
%	Rename for FLI.m for Fast Laplace Inversion
%   	Modified for 1d data, May 28, 2003. YS
%	Add t1heel method, Aug 28,2003. YS
%
%	Details were published in 
%	L. Venkataramanan et. al., IEEE Tran. Signal Proc. 50, 1017-1026 (May, 2002).
%	Y.-Q. Song, et al., J. Magn. Reson. 154, 261-268(2002).			    	
%	M D Hurlimann and L Venkataramanan, J. Magn. Reson. 157, 31 (2002).		 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	

    
