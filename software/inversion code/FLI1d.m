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

   
%   normalization
    theMaxPoint = max(inputData);
    inData = inputData ./ theMaxPoint;
 
   	%%%%%%%%%%%%%% Regularization %%%%%%%%%%%%

    if (inAlpha < 0 && inAlpha ~= -1 && inAlpha ~=-2)  
        disp 'Input alpha is not valid.'
        return
    end
    
    switch inAlpha
        case 0                  %BRD method
            Alpha_Auto = 1;
            AlphaStart = 0.01;
        case -1                 %a full span of alpha is tested.
            Alpha_Auto = 2;
        case -2                 % t1heel method by Apo
            Alpha_Auto = 3;
            AlphaStart = 0.01;
        otherwise
            Alpha_Auto = 0;     % fixed alpha
            AlphaStart = inAlpha;
    end
    
            

 if nargin == 3     % use the input Kernel
         Number_T1 = size(inKernel,2);                        % The number of T1's
         Number_S1 = 14;                % Upper limit for number of singular values for K1     
         Number_Tau = size(inKernel,1);
      % SVD of inKernel
     	%fprintf(1,'Computing SVD of the Kernel ... ');
     	t = cputime;
     	[U1, S1, V1] = svds(inKernel, Number_S1);
     	e = cputime -t;
     	%fprintf(1, '%d\n',e);

    else if nargin == 6    % ignor input Kernel and use U,S,V instead to save svd
            %fprintf(1,'Use the input SVD: U,V,S ... ');
             U1 = U;
             S1 = S;
             V1 = V;
         else
             fprintf(1,'The input parameters appear to be incompatible with the prototype.');
             fprintf(1,'FLI1d will return without further calculation.');
             return
         end
     end
     
    ConditionNumber = 10000;
    S = diag(S1) ./ S1(1,1);
    x = find(S*ConditionNumber>=1);
 	U1 = U1(:,x);
    S1 = S1(x,x);
    V1 = V1(:,x);

    NoiseStd = std(U1*(U1'*inData') - inData')  ;
    %fprintf(1,'Estimated noise standard dev is %g\n',NoiseStd);
        
% fitting
    switch Alpha_Auto
         case {0,1,3}	% 0:for a fixed alpha, 
                        % 1:BRD method
                        % 3: t1heel method

        [FEst, CompressedData, Chi, Alpha_heel] = ...
            FLIEstimate1d(inData,  U1, V1, S1, ...
                AlphaStart, NoiseStd, Alpha_Auto, ConditionNumber);
            
        case 2
            AlphaSpan = logspace(-4,4,50);	%% calc for a series of Alpha. the range may be changed 
                					%% to suit the specific needs
                AlphaSpan = fliplr(AlphaSpan);
                Alpha_AutoTmp = 0;
                for ijk = 1:length(AlphaSpan)
                    [FEst, CompressedData, Chi, Alpha_heel] = FLIEstimate1d(inData,  U1, V1,  ...
                    S1, AlphaSpan(ijk), NoiseStd, Alpha_AutoTmp, ConditionNumber);
                    CompressedError(ijk) = Chi;
                    FDensity{ijk} = FEst;
                end 
              
                % findheel	- FindHeel.m
                CompressedError = CompressedError(1:end);
                AlphaSpan = AlphaSpan(1:end);
                logChi = fliplr(log10(CompressedError));
                AlphaSpan = fliplr(AlphaSpan);
                logalpha = log10(AlphaSpan(2)/AlphaSpan(1));
                
                for i = length(logChi) : -1 :2
                    dlogChi(i) = (logChi(i) - logChi(i-1))/logalpha;
                end
                dlogChi(1) = 0;
                
                 
                j = find(dlogChi >= 0.1);
                
               Alpha_heel = AlphaSpan(j(1));
                
                [FEst, CompressedData, Chi, Alpha_heel] = ...
                    FLIEstimate1d(inData, U1, V1, ...
                        S1, Alpha_heel, NoiseStd, Alpha_AutoTmp, ConditionNumber);
                
 
				%%%%%  plot chi-sq
                figure
                subplot(221)
               plot(log10(AlphaSpan), logChi, '*-')
                      title('plot(log10(AlphaSpan), logChi,')
                      
                 subplot(222)
                plot(log10(AlphaSpan), dlogChi)
                title('plot(log10(AlphaSpan), dlogChi)')
             otherwise % SWITCH
            	fprintf(1,'Alpha_Auto = %d. Not a valid choice.\n',Alpha_Auto);
        end	%SWITCH

        FEst = FEst*theMaxPoint;
        Chi = Chi*theMaxPoint;
        
		Fitdata = inKernel*FEst';
		parameter.chi = Chi;
		parameter.alpha = Alpha_heel;
        
    return
