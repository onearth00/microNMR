function [FEst, parameter, Fitdata] = FLI2d(inputData,inKernel1,inKernel2,inAlpha,U1,S1,V1,U2,S2,V2)
%   Two-dimensional inversion of Folh integral, including Laplace
%   inversion.
%   Syntax:
%   [FEst, parameter, Fitdata] = FLI2d(inData,inKernel1,inKernel2,inAlpha,U1,S1,V1,U2,S2,V2)
%   [FEst, parameter, Fitdata] = FLI2d(inData,inKernel1,inKernel2,inAlpha)
%
%	inData : data matrix
%	inKernel: kernel matrices
% 	inAlpha: 0:BRD method, positive constant: fixed reg, -1:full span, -2:t1heel method.
%	U,S,V: K=U*S*V', if they are provided, then SVD of K will be skipped.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                    %
%                                                                                    %
%        Main matlab file to do T1-T2 inversion.  It solves the problem of the       %
%        form M(tau_2, tau_1) = double integral ( F(T1, T2) (1.0 -                   %
%        2exp(-tau_1/T1)) exp(-tau_2/T2)) dT1 dT2                                    %
%                                                                                    %
%        where tau_1 corresponds to the different wait times and tau_2               %
%        corresponds to the equally spaced times at which CPMG data is acquired.     %
%                                                                                    %
%        Here, M(tau_2, tau_1) is measured experimentally by following a CPMG        %
%        following inversion recovery.  The objective is to estimate F(T1, T1)       %
%        subject to the constraint that F be greater than or equal to zero, given    %
%        the data.                                                                   %
%                                                                                    %
%        The problem is a least-squares problem and can be written to be of the      %
%        form, D = K2 * F * K1' + E where D(i,j) has the data at the i-th tau_2      %
%        value and j-th tau_1 value K2(i,j) = exp(-tau_2(i)/T2(j)) F(i,j) is the     %
%        (i,j)th element of F K1(i,j) = 1.0 - 2*exp(-tau_1(j)/T1(i)) E refers to     %
%        additive white Gaussian noise.                                              %
%                                                                                    %
%        The solution is in two steps :                                              %
%                                                                                    %
%        1.  Data compression : The data compression is done using singular value    %
%        decomposition of K2 and K1.  Consider r significant singular values of      %
%        K2 and p signifianct singular values of K1.  It can be shown that (a)       %
%        the data can be compressed to be of the size (r*p).  Let the compressed     %
%        data be denoted by D_.  (b) the problem can be re-formulated to be          %
%                                                                                    %
%        D_ = K2_ * F * K1'_ - Equation (a)                                          %
%                                                                                    %
%        where K2_ and K1_ are matrices and are found from the SVD of K2 and K1.     %
%                                                                                    %
%        2.  Solve (a) with zero-th order regularization with procedure given in     %
%        Butler, Reeds, and Dawson paper, subject to F>=0.                           %
%                                                                                    %
%        Inputs to the file are :                                                    %    
%        1. Number_T1, Number_T2, InitTime_T1, InitTime_T2, Final_T1, Final_T2,      %
%        2. The number of alphas, alpha_min, alpha_max                               %
%        3. Flag that indicates of data is being simulated or data already exists    %
%           as an experimental data set                                              %
%        4. Flag that indicates if the singular values are being computed or have    %
%           have been pre-computed and saved ; if flag is on, the upper bounds on    %
%           the number of singularvalues required for S1 and S2.                     %
%        5. If simulator is being used : InitTime_Tau_1, Final_Time_Tau_1,           %
%           Number_Tau_1, Echospacing, InitTime_Tau_2, Final_Time_Tau_2,             %
%           Number_Tau_2, Name of file where the data is stored                      %
%        6. The name of the data file (should have data, tau_1, tau_2, noisestd)     %
%        7. Name of file where the SVD is stored (if it is stored)                   % 
%        8. Ensure that if T1 or T2 or tau_1 or tau_2 changed, we have to compute    %
%           the SVD again.                                                           %
%                                                                                    %
%                                                                                    %
%                                                                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Original March 2001 
%	modified April 2001, September 2002.
%	
%	Rename for FLI.m for fast Laplace Inversion
%   modified May 28, 2003.
%
%	Details were published in 
%	L. Venkataramanan et. al., IEEE Tran. Signal Proc. 50, 1017-1026 (May, 2002).	 %
%	Y.-Q. Song, et al., J. Magn. Reson. 154, 261-268(2002).			    			 %
%	M D Hurlimann and L Venkataramanan, J. Magn. Reson. 157, 31 (2002).		    	 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	



