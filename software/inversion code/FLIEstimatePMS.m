function  [FEst, CompressedData, Chi, alpha] = FLIEstimatePMS(Data, ...
U1, U2, V1, V2,S1, S2, alpha, NoiseStd, flag, CondNum)

% function  [FEst, CompressedData, Chi, alpha] = FLIEstimate(Data, ...
% U1, U2, V1, V2,S1, S2, alpha, NoiseStd, flag, scale)
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                                %
%   Function is called by the main function FLI.m                                             %
%   Estimate of F(T1, T2), subject to F(T1, T2) >=0, from the data. 
%                                                                                                %
%   Function inputs are :                                                                        %
%   1. Data, details about the data                                                              %
%   2. SVD of matrices K_2 and K_1                                                               %
%   3. Values of alpha for which we need to solve the problem                                    %
%   4. Flag = 1 : if alpha automaticaly chosen (alphas = alpha_start)                            %
%      Flag = 0 : if alpha fixed at alphas = alpha_fixed                                         %
%       flag = 3: alpha is determined by t1heel method.
%
%   Function outputs are :                                                                       %
%   1. FEst for a given value of $\alpha$.                                                       %
%   2. Compressed and Projected data                                                             %
%   3. Optimum value of \alpha (if flag == 0)                                                    %
%                                                                                                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   YS May 2003. add non-uniform noise variance
%   NoiseVar should be of the same dimension as Data.
%   If the input contains only the first 15 parameters, then the NoiseVar is
%   assume to be 1 for all data.
%
%   YS Oct 03 WARNING: 
%   The handling of non-uniform noise variance has not been implemented
%   completely. DO NOT USE IT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Number_Tau_1 = length(U1);
Number_Tau_2 = length(U2);

Number_T1 =length(V1);  % number of T1 plus 1.
Number_T2 =length(V2);

n = 1;
%V = zeros((Number_T1+1)*Number_T2,1);
  V = zeros((Number_T1)*Number_T2,1);
  
% %Compute compressed data and modified vector V; NoiseVar
% if nargin == 11  % no input of the NoiseVar
%     disp 'Assume uniform Noise Variance...'
	for i = 1:length(S2)
		for j = 1:length(S1)
			if (S2(i,i)*S1(j,j) > S1(1,1)*S2(1,1)/CondNum)
				S(n)= S2(i,i) * S1(j,j);
          	CompressedData(n) = U2(:,i)'*Data*U1(:,j);
  %          CompressedNoiseVar(n) = 1;
          	V(:,n) = kron(V2(:,i), V1(:,j));
          	n = n+1;
          end
        end
     end
% else if ((nargin == 12) && exist('NoiseVar'))       % with input of the NoiseVar
%     disp 'Use the Noise Variance input...'
%     
% 	for i = 1:length(S2)
% 		for j = 1:length(S1)
% 			if (S2(i,i)*S1(j,j) > S1(1,1)*S2(1,1)/scale )
% 				S(n)= S2(i,i) * S1(j,j);
%           	CompressedData(n) = U2(:,i)'*Data*U1(:,j);
%    %         CompressedNoiseVar(n) = (U2(:,i).^2)'*NoiseVar*(U1(:,j).^2);
%           	V(:,n) = kron(V2(:,i), V1(:,j));
%           	n = n+1;
%           end
%         end
%      end
%  end
% end

 e= 1;  
 S = diag(S);
 n = length(S);
 data = CompressedData';
 
 fprintf(1, 'Size of compressed data = %d\n',n);
  
% Re-compute (modified) K
K = S*V';
%CompressedNoiseVar = sqrt(CompressedNoiseVar);
%CompressedNoiseVar = length(CompressedNoiseVar)*CompressedNoiseVar ./ sum(CompressedNoiseVar);

%%%% weight the data by the noise variance. YS May 2003
%for i=1:n
%    K(i,:) = K(i,:) ./ CompressedNoiseVar(i);
%    data(i) = data(i) ./ CompressedNoiseVar(i);
%end

%%%% now we have to solve the linear equation data = K * F.

% Set up the optimization criteria
options = optimset; options.GradObj = 'on'; options.Hessian = 'on';
options.LargeScale = 'on'; options.MaxIter = 5000;
options.Display = 'final';
options.TolX = 1e-8;
options.TolFun = 1e-16;
options.MaxFunEvals = 5000;


% Useful constants used in the code.
Identity = eye(n, n);
Zero_mat = zeros(Number_T2, Number_T1);

% For each value of alpha, run over the optimization code
fprintf(1,'alpha = [');
found = 0;  
alpha_opt = []; 

% Compute rough estimate of vector C for first value of alpha
C_Vec = ones(n, 1);
k = 1;
MaxIter = 5000; 

while (~found)
	fprintf(1, ' %2.2e ', alpha);	
	% Use previous estimate as starting point for C_Vec for higher values of alpha
	% and plod through optimization algorithm
	[C_Vec, fval, exitflag, output] = fminunc('FLIminfunPMS', C_Vec, options, ...
	    data,  K, alpha,Identity); 
	% Ensure that the optimization code ran correctly by looking at the exit flag
	if (exitflag ~= 1)
		fprintf(1, 'Increase tolerance for alpha = %d and run again \n', alpha);
		fprintf(1, 'Iterations = %d FuncCount = %d ExitFlag = %d\n', output.iterations,...
		output.funcCount, exitflag);
	end
	
	% Convert vector back into matrix
	% Compute the best value of F(T2, T1) for given value of alpha
%%%	FEst = max(0, reshape(K'*C_Vec, (Number_T1), Number_T2)');	
	Chi = alpha * norm(C_Vec, 'fro');
%	fprintf(1,'Chi = %d exp = %d  \n', Chi, sqrt(n)*NoiseStd);

%	if (flag == 0) found = 1;
%	else 
%            if(flag == 1)
%                alpha_opt =  sqrt(n)*NoiseStd/(norm(C_Vec,'fro'));
%                if (abs((alpha-alpha_opt)/alpha) < 1e-3) 
%                    found = 1; 
%                end
%                %% YS May 2003
%                %if (abs(Chi-sqrt(n)*NoiseStd)/(sqrt(n)*NoiseStd) < 1e-1) found = 1; end
%                if(alpha * 100 < Chi) 
%                    found =1; 
%                   fprintf(1,'Alpha appears to have become much too small before convergence. Stop.\n');
%                end
%                
%                alpha = alpha_opt;		
%            else
%                found = 1;
%            end
%	end
        %%%% YS aug 03. switch
        switch flag
            case 0  % fixed
                found = 1;
            case 1  % BRD
                alpha_opt =  sqrt(n)*NoiseStd/(norm(C_Vec,'fro'));
                if (abs((alpha-alpha_opt)/alpha) < 1e-3) 
                    found = 1; 
                end
                %% YS May 2003
                %if (abs(Chi-sqrt(n)*NoiseStd)/(sqrt(n)*NoiseStd) < 1e-1) found = 1; end
                if(alpha * 100 < Chi) 
                    found =1; 
                   fprintf(1,'Alpha appears to have become much too small before convergence. Stop.\n');
                end
                
                alpha = alpha_opt;		
            case 3
                % do t1heel
                [C_Vec, Chi, alpha] = t1heel(data, K);
                found =1;
                fprintf(1,'t1heel determines that alpha=%e.\n',alpha);
            otherwise
                found = 1;
        end
        
        % Convert vector back into matrix
	% Compute the best value of F(T2, T1) for given value of alpha
	FEst = max(0, reshape(K'*C_Vec, (Number_T1), Number_T2)');	
	Chi = alpha * norm(C_Vec, 'fro');
	fprintf(1,'Chi = %d exp = %d  \n', Chi./sqrt(n), NoiseStd);

%%%%%%%%%%%%%%%%%%

	if (k > MaxIter) && (found ==0)
		fprintf(1, 'Error ... algorithm does not seem to converge? \n');
		found = 1; FEst = [];
	end
	k = k+1;
end	

return	%% end of Estimate()

function [g, p, x] = cholsolv(a, b)
%    int t1heel_Analyser::chol_(
% 		double *a, 				//hess, input
% 		double *g, 				// cholesky decomposition
% 		double *b, 				// usually grad
%		double *x, 				// result
%		long n, 				//input
%		long *ierchol, 			// output
%		long ido)

% Cholesky decomposition G' * G =A
% and solve the equation A x = b.

    [g,p] = chol(a);
    if g'*g ~= a
        disp 'Error in cholesky decomposition.'
    end
    
    if nargout == 2
        return
    end
    x=zeros(length(b),1);
    y=zeros(length(b),1);
    
    %solve G' y = b        G' is lower triangle
    for k=1:length(b)
        total = b(k);
        for l=1:k-1
            total = total - g(l,k)*x(l);
        end
        x(k) = total ./ g(k,k);
    end

    %solve G* x = y        G is a upper triangle matrix
    for k=length(b):-1:1
        total = x(k);
        for l=k+1:length(b)
            total = total - g(k,l)*y(l);
        end
        y(k) = total ./ g(k,k);
    end

    if a*y ~= b
        if max(abs(a*y-b)) > 0.000001
        disp 'Error in cholsolv.'
    end
    end
    
    x=y;
return %cholsolv
    
function  [C_Vec, Chi, alpha] = t1heel(data, K)

    % Set up the optimization criteria
    options = optimset; options.GradObj = 'on'; options.Hessian = 'on';
    options.LargeScale = 'on'; options.MaxIter = 5000;
    options.Display = 'final';
    options.TolX = 1e-8;
    options.TolFun = 1e-16;
    options.MaxFunEvals = 5000;
    
    alpha = max([ max(sum(K.^2,2))]);	%initial alpha
    
     n = size(K,1);
    C_Vec = ones(n, 1);
    k = 1;
    MaxIter = 5000; 

    Identity = eye(n, n);
    found = 0;

    % t1heel parameters
    dxerrlo = 0.;
    dxerrhi = 0.;
    ddxerr = 0.;
    alflo = 0.;
    alfhi = 0.;
    xerrmin = 1e30;
    flag__ = 1;
    alfmin = 0.;
    step = 100.;
    
    tolgrd = 1e-15;
    tresh = .1;

    i__1 = 50; %
    t1heel_maxiter = 50;
    iter = 1;

   while (found == 0 && iter < t1heel_maxiter)           
		fprintf(1, ' %2.2e ', alpha);	
		% Use previous estimate as starting point for C_Vec for higher values of alpha
		% and plod through optimization algorithm
		[C_Vec, fval, exitflag, output] = fminunc('FLIminfunPMS', C_Vec, options, ...
		    data,  K, alpha,Identity); 
		% Ensure that the optimization code ran correctly by looking at the exit flag
		if (exitflag ~= 1)
			fprintf(1, 'Increase tolerance for alpha = %d and run again \n', alpha);
			fprintf(1, 'Iterations = %d FuncCount = %d ExitFlag = %d\n', output.iterations,...
			output.funcCount, exitflag);
		end
	
	    Chi = alpha * norm(C_Vec, 'fro');
            
            [f,g, H] = FLIminfunPMS(C_Vec, data,  K, alpha,Identity);
            % H is ns by ns
            % g is ns by 1
            % f is 1 by 1
            
            [g,ier1, x] = cholsolv(H,C_Vec); %g*g'=H; H*x=C_Vec;
            cc=sum(C_Vec.^2);
            cp=x'*C_Vec;
            xerr = alpha*sqrt(cc);
            dxerr = 1 - alpha * cp / cc;
            [f xerr dxerr];
            
            if iter > 1
                ddxerr = (dxerr - dxerrold) / log(alpha / alphaold);
            end
            dxerrold = dxerr;
            alphaold = alpha;
            if (ier1 ~= 0) 
                alflo = alpha;
                dxerrlo = 0.;
                if (dxerrhi > 0.) 
                    alpha = sqrt(alflo * alfhi);
                else 
                    alpha = alpha*step;
                end
            else
                if (dxerr <= tresh) 
                    alflo = alpha;
                    dxerrlo = dxerr;
                    xerrlo = xerr;
                else if (dxerr > tresh || ddxerr < 0. && flag__ == 1) 
                        alfhi = alpha;
                        dxerrhi = dxerr;
                        xerrhi = xerr; 
                    end
                end
                if (ddxerr > 0.) 
                    flag__ = 0;
                end
                
                if (alflo == 0.) 
                    alpha = alpha/step;
                else if (alfhi == 0.) 
                    alpha = alpha*step;
                    else if (dxerrlo * dxerrhi > 0.) 
                            d__1 = alfhi / alflo;
                            d__2 = (tresh - dxerrlo) / (dxerrhi - dxerrlo);
                            alpha = alflo * (d__1 .^ d__2);
                        else 
                            alpha = sqrt(alfhi * alflo);
                        end
                    end
                end
            end
            
            d__1 = dxerr - tresh;
            if (abs(d__1) < tresh * .1) 
                alpha = alphaold;
                found = 1;
            end
            
        iter = iter +1;
    end % while

return
