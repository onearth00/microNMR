function  FLIPlot2dT1T2(T1, T2, FEst, inCM)  
%function  FLIPlot2dT1T2(T1, T2, FEst, inColorMap) 
%plot the 2d density function

    x=T1;y=T2;
    if nargin == 3
        theCM = jet;
    else
        theCM = inCM;
    end
	% Surface plot of f(T1, T2)
    %FEst (T2index, T1index)
	%surfc(x, y, FEst(1:length(y), 1:length(x)),[1 10 20 30 40]) ,colormap (gray) , shading flat %interp
    hold off
    pcolor(x, y, FEst(1:length(y), 1:length(x))), colormap(theCM), shading interp, colorbar;
    hold on
    mycontourlines = [.1 .3 .5 .7 .9]*max(max(FEst));
    contour(x, y, FEst(1:length(y), 1:length(x)),mycontourlines,'m-')
    hold off
	axis square
	h = gca;
	set(h, 'XScale', 'log', 'YScale', 'log')
	xlabel('T_1 (secs)', 'FontSize', 9)
	ylabel('T_2 (secs)', 'FontSize', 9)
	set(gca, 'FontSize', 10);
	set(gca, 'XTickMode', 'Manual');
	set(gca, 'XTick', [1e-3 1e-2 1e-1 1 10]);
	set(gca, 'YTickMode', 'Manual');
	set(gca, 'YTick', [1e-3 1e-2 1e-1 1 10]);
	%title([DataName, ':F(T1, T2) for \alpha  = ', num2str(alpha)], 'FontSize', 9);
	
	v(1) = min(x); v(2) = max(x); V(3) = min(y); v(4) = max(y);
	axis(v)
	theCM = colormap;
	h = line([min(x) max(x)], [min(x) max(x)]);
    if (theCM(1,1) == 1) % min
        set(h, 'Color', 'k', 'LineStyle', '--')
    else
        set(h, 'Color', 'w', 'LineStyle', '--')
    end
 	h = line([2*min(x) 2*max(x)], [min(x) max(x)]);
    if (theCM(1,1) == 1) % min
        set(h, 'Color', 'k', 'LineStyle', '--')
    else
        set(h, 'Color', 'w', 'LineStyle', '--')
    end
   
    set(gca, 'TickDir','out')
	
%	% Compute T1, T2 distributions, porosity and beta
%	dlogx = log10(x(2)/x(1)); dlogy = log10(y(2)/y(1));
%	FEst = FEst ./(dlogx *dlogy);
%	[x_dist, y_dist, por, beta] = ComputeIndividualDist(FEst, length(x), length(y), ...
%	dlogx, dlogy);
	
% 	[x_dist, y_dist, por, beta] = ComputeProjections(FEst, x,y);
% 	
%    % Plot T1 and T2 distributions
% 	%figure('Units', 'Inches','Position', [0.5 0.5 7.5 10])
% 	subplot(223)
% 	semilogx(x, x_dist(1:length(x)), 'r-.')
% 	xlabel('T_1 (secs)', 'FontSize', 9)
% 	ylabel(' F(T_1)', 'FontSize', 9)
% 	title(['T_1 distribution with \alpha = ', num2str(alpha)], 'FontSize', 9)
% 	set(gca, 'FontSize', 9);
% 	
% 	subplot(224)
% 	semilogx(y, y_dist, 'r-.')
% 	xlabel('T_2 (secs)', 'FontSize', 9)
% 	ylabel('F(T_2)', 'FontSize', 9)
% 	title(['T_2 distribution with \alpha = ', num2str(alpha)], 'FontSize', 9)
% 	set(gca, 'FontSize', 9);
% 	fprintf(1, ' por. = %g\n',por);
% 
% 	orient tall
