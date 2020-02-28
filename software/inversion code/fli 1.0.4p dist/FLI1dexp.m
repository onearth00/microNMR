function [FEst, parameter, Fitdata] = FLI1dexp(inputData,bvalue,diffConst,inAlpha)
%
%   Fast Laplace inversion for 1d data
%   function [FEst, parameter, Fitdata] = FLI1dexp(inputData,bvalue,diffConst,inAlpha)
%
%   fitting functional form: data = exp( - bvalue * diffConst).
%
%	inputData : data vector, 
%	bvalue: bvalue vector,
%   diffConst: diffusion constant vector
% 	inAlpha: 0:BRD method, positive constant: fixed reg, -1:full span, -2:t1heel method.
% 
%   For use with T1 or T2 inversion:
%   [FEst, parameter, Fitdata] = FLI1dexp(inputData,tau,1./T1,inAlpha)
%   tau: delay times vector
%   T1 : time constant vector
%
% version 1.1.1 2014


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

if nargin ==0
    fprintf(1,'FLI (Fast Laplace Inversion) version 1.1.1\n')
    FLIhelp();
    return;
end


theKernel = exp(-bvalue(:) * (diffConst(:)'));

[FEst,parameter,Fitdata] = FLI1d(inputData,theKernel,inAlpha);
