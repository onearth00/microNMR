function  FLIPlot2dT1T2cont(T1, T2, FEst, contourcolor)  
% 
% function  FLIPlot2dT1T2cont(T1, T2, FEst, contourcolor) 
%
%  plot the 2d density function as a contour plot
%  use caxis([min max]) to control z-scale
%




    x=T1;y=T2;

	% Surface plot of f(T1, T2)
    %FEst (T2index, T1index)
	%surfc(x, y, FEst(1:length(y), 1:length(x)),[1 10 20 30 40]) ,colormap (gray) , shading flat %interp
    %pcolor(x, y, FEst(1:length(y), 1:length(x))), colormap(theCM), shading interp, colorbar;
    %hold on
    mycontourlines = [.1 .3 .5 .7 .9]*max(max(FEst));
    contour(x, y, FEst(1:length(y), 1:length(x)),mycontourlines,contourcolor)
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
    set(h, 'Color', 'k', 'LineStyle', '-')

    h = line([2*min(x) 2*max(x)], [min(x) max(x)]);
    set(h, 'Color', 'k', 'LineStyle', '--')

    set(gca, 'TickDir','out')
	
