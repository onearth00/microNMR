

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%				TEST OF FLI2d
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


     clear                                                       % Clear all variables
     
% make data

    ndata = [ 40 1000]; % number of data points

    
    Tau1 = logspace(-3,0,ndata(1))';
     Tau2 = 0.001*(1:1:ndata(2))';
    %%%%%%%%%%%%%% Range of T1 and T2 %%%%%%%%%%%%
    % T1 and T2 are logarithmically spaced
     T1 = logspace(-3, 0, 90);
    fmodel1 = exp(-([-50:39]./7).^2/2);
    
    fmodel2 = exp(-([-50:49]./7).^2/2);
    
   	T2 = logspace(-3, 0, 100);
    fmodel = fmodel1' * fmodel2;
    
%%   
   
	%%%%%%%%%%%%% Definitions of Kernel functions %%%%%%%%%%%%%%%
	
	%%%% CONVENTION
		% Tau is a vertical vector, TimeConst is horizontal vector,
	% and the resulting kernels are matrices.
	
	%%%%%%%%%%%% Kernel along the first dimension %%%%%%%%%%%%%%
	%exponential decay
	Kernel_1 = inline('exp(- Tau * (1./ TimeConst))','Tau','TimeConst');
	K1 = Kernel_1 (Tau1,T1);

    K2 = Kernel_1(Tau2,T2);
  
    
        %inv recovery
        %Kernel_1 = inline('1- 2*exp( - Tau * (1./ TimeConst))','Tau','TimeConst');


        %%%%%%%%%%%% Kernel modification for DC offset %%%%%%%%%%%%%

        % for inversion-recovery data, include the a DC offset in the kernel 
        % will help estimate the error in the pi pulse. However, if pi error is too
        % large, it is better to modify the kernel function to account for it first.

        % the kernel will be modified by adding a column of 1 as the last column
        % so that the program will find the pi pulse error, or other effects to produce
        % a dc  offset.

        %AllowDCOffset = 1;	% allow a dc offset
        AllowDCOffset = 0; 	% no offset


        [U1, S1, V1] = svds(K1, 15);
        [U2, S2, V2] = svds(K2, 15);
      data = K1 * fmodel * K2';
      dm = max(max(data));
      data = data ./ dm;
      
      
%% 

        inputdata = data + randn(size(data))*0.02;

        % use fixed alpha
        [FEst,Alpha_heel,Fit] = FLI2d(inputdata',K1,K2,1,U1,S1,V1,U2,S2,V2);
        
        % use t1heel method for regularization
        %[FEst,Alpha_heel,Fit] = FLI2d(inputdata',K1,K2,-2,U1,S1,V1,U2,S2,V2);
        
        figure(1)
        subplot(121)
        FLIPlot2dT1T2(T1,T2,FEst)
        title (['FLI2d result with \alpha=' num2str(Alpha_heel.alpha)])
        subplot(122)
        FLIPlot2dT1T2(T1,T2,fmodel')
        title('2d model')
% 
%%

