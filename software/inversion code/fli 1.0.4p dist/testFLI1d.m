

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%				TEST OF FLI1d
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


     clear                                                       % Clear all variables
     
% make data

    ndata = 40; % number of data points
    nrepeat = 30; % number of repeat
    
    Tau = logspace(-3,0,ndata)';
     
    %%%%%%%%%%%%%% Range of T1 and T2 %%%%%%%%%%%%
      
     InitTime_T1 = .001;                      % The initial value of T1 (in seconds)
     FinalTime_T1 = 1;                      % The final value of T1 (in seconds)
     Number_T1 = 100;                        % The number of T1's
            % T1 and T2 are logarithmically spaced
     T1 = logspace(log10(InitTime_T1), log10(FinalTime_T1), Number_T1);
    fmodel = exp(-([-50:49]./7).^2/2);
    fmodel = fmodel ./ sum(fmodel);
    
    
     
   
	%%%%%%%%%%%%% Definitions of Kernel functions %%%%%%%%%%%%%%%
	
	%%%% CONVENTION
		% Tau is a vertical vector, TimeConst is horizontal vector,
	% and the resulting kernels are matrices.
	
	%%%%%%%%%%%% Kernel along the first dimension %%%%%%%%%%%%%%
	%exponential decay
	Kernel_1 = inline('exp(- Tau * (1./ TimeConst))','Tau','TimeConst');
	K_1 = Kernel_1 (Tau,T1);

    data =( K_1 * fmodel')*ones(1,nrepeat);
    noise = randn(size(data));

   
    
    
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


        [U1, S1, V1] = svds(K_1, 12);
        inputdata = data + 0.02* noise;
% 
%         for ijk = 1:size(inputdata,2)
% 
%             ijk
%         Data =  inputdata(:,ijk)';
% 
%         % use fixed alpha
%         [FEst,Alpha_heel,Fit] = FLI1d(Data,K_1,-2,U1,S1,V1);
%         % use t1heel method for regularization
%         %[FEst,Alpha_heel,Fit] = FLI1d(Data,K_1,-2,U1,S1,V1);
% 
%         alpha_all(ijk) = Alpha_heel.alpha;
%         error_all(ijk) = std(Fit-Data');
%         FEst_all (ijk,:) = FEst(1:Number_T1);
%         Data_all(ijk,:) = Data;
%         Fit_all  (ijk,:) = Fit';
% 
%         end
% 
%         f2 = sum(FEst_all.^2,2);
% 
%         figure(1)
%         subplot(321)
%         plot(Tau,Data_all','-');
%         title('data')
%         xlabel('tau')
% 
%         subplot(322)
%         plot(Tau,Fit_all','-');
%         title('fits')
% 
%         subplot(323)
%         semilogx(T1,mean(FEst_all,1),T1,std(FEst_all,1),T1,fmodel,'r')
%         title('model and average results')
%         xlabel('T_1')
%         axis tight
% 
%         subplot(324)
%         semilogx(T1,FEst_all')
%         title('all spectra')
% 
%         subplot(325)
%         plot(alpha_all,'o-')
%         title('\alpha')
%         xlabel('repeat index')
% 
%         subplot(326)
%         plot(error_all,'o-');
%         hold on
%         plot(f2,'r')
%         hold off
%         title('std(blue) and f2(red)')
%         xlabel('repeat index')
        

        inputdata2 = data(:,1) + 0.05*randn(ndata,1);
        
        nalpha = 30
        alphalist = logspace(-3,3,nalpha);
        for ijk = 1:nalpha
            [FEst,Alpha_heel,Fit] = FLI1d(inputdata2',K_1,alphalist(ijk),U1,S1,V1);
            error_all(ijk) = std(Fit-inputdata2);
            error_svd(ijk) = Alpha_heel.chi;
            error2 (ijk) = sum(((Fit-inputdata2)));
            FEst_all (ijk,:) = FEst(1:Number_T1);
            Fit_all  (ijk,:) = Fit';
            alpha_all(ijk) = Alpha_heel.alpha;
        end
        f2 = sum(FEst_all.^2,2);
        
        r = Fit_all' - inputdata2 * ones(1,nalpha);
        
        figure(2)
        subplot(221)
        semilogx(Tau,inputdata2,'-');
        title('data')
        xlabel('tau')

        subplot(222)
        semilogx(Tau,Fit_all','-');
        title('fits')

     

        subplot(223)
        semilogx(T1,FEst_all',T1,fmodel,'r')
        title('model and all spectra')
        xlabel('T_1')
        

        subplot(224)
        loglog(alpha_all,error_all,'o-',alpha_all,error_svd,'-',alpha_all,f2,'r-',alpha_all,abs(error2)./sqrt(ndata),'g-')
        xlabel('alpha')
        title('std(blue) and f2(red)')
        
        return


