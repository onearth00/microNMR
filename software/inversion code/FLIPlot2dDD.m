function  FLIPlot2dDD(D1, D2, FEst, inCM)  
%
% function  FLIPlot2dDD(D1,D2, FEst, inColorMap) 
% plot the 2d density function
%
% Unit of D1 and D2: cm2/s
%

    x=D1;y=D2;
    if nargin == 3
        theCM = jet;
    else
        theCM = inCM;
    end
	% Surface plot 
    hold off
    pcolor(x, y, FEst(1:length(y), 1:length(x))), colormap(theCM), shading interp, colorbar;
    hold on
    mycontourlines = [.1 .3 .5 .7 .9]*max(max(FEst));
    contour(x, y, FEst(1:length(y), 1:length(x)),mycontourlines,'m-')
    hold off
	axis square
	h = gca;
	set(h, 'XScale', 'log', 'YScale', 'log')
	xlabel('D1 (cn2/s)', 'FontSize', 9)
	ylabel('D2 (cm2/s)', 'FontSize', 9)
	set(gca, 'FontSize', 10);
	set(gca, 'XTickMode', 'Manual');
	set(gca, 'XTick', [1e-9 1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10 100 1e3 1e4]);
	set(gca, 'YTickMode', 'Manual');
	set(gca, 'YTick', [1e-9 1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10 100 1e3 1e4]);
	%title([DataName, ':F(T1, T2) for \alpha  = ', num2str(alpha)], 'FontSize', 9);
	
	v(1) = min(x); v(2) = max(x); V(3) = min(y); v(4) = max(y);
	axis(v)
	theCM = colormap;
    if (theCM(1,1) == 1) % min
        set(h, 'Color', 'k', 'LineStyle', '--')
        h = line([min(x) max(x)], [min(x) max(x)],'Color', 'k', 'LineStyle', '--');
        h = line(2*[min(x) max(x)], [min(x) max(x)],'Color', 'k', 'LineStyle', '--');
        h = line([0.5*min(x) 0.5*max(x)], [min(x) max(x)],'Color', 'k', 'LineStyle', '--');
        h = line([min(x) max(x)], 3*[min(x) max(x)],'Color', 'k', 'LineStyle', '--');

    else
        set(h, 'Color', 'w', 'LineStyle', '--')
        h = line([min(x) max(x)], [min(x) max(x)], 'Color', 'w', 'LineStyle', '--');
        h = line(2*[min(x) max(x)], [min(x) max(x)], 'Color', 'w', 'LineStyle', '--');
        h = line([0.5*min(x) 0.5*max(x)], [min(x) max(x)], 'Color', 'w', 'LineStyle', '--');
        h = line([min(x) max(x)], 3*[min(x) max(x)], 'Color', 'w', 'LineStyle', '--');

    
    end
 	
  
    set(gca, 'TickDir','out')
	

