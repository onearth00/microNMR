function  FLIPlot2dFullDD(D1, D2, FEst, inCM)  
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
    
    % main plot of 2d
    subplot(4,4,[5:7 9:11 13:15])
    
	% Surface plot of f(T1, T2)
    %FEst (T2index, T1index)
	%surfc(x, y, FEst(1:length(y), 1:length(x)),[1 10 20 30 40]) ,colormap (gray) , shading flat %interp
    hold off
    pcolor(x, y, FEst(1:length(y), 1:length(x))), colormap(theCM), shading interp;
    hold on
    mycontourlines = [.1 .3 .5 .7 .9]*max(max(FEst));
    contour(x, y, FEst(1:length(y), 1:length(x)),mycontourlines,'m-')
    hold off
	%axis square
    h = gca;
	set(h, 'XScale', 'log', 'YScale', 'log','FontSize',12)
	xlabel('D1 (cn2/s)', 'FontSize', 9)
	ylabel('D2 (cm2/s)', 'FontSize', 9)
	set(gca, 'FontSize', 10);
	set(gca, 'XTickMode', 'Manual');
	set(gca, 'XTick', [1e-9 1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10 100 1e3 1e4]);
	set(gca, 'YTickMode', 'Manual');
	set(gca, 'YTick', [1e-9 1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10 100 1e3 1e4]);
    title('DD plot', 'FontSize', 9);
	
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
   
    h = line([0.5*min(x) 0.5*max(x)], [min(x) max(x)]);
    if (theCM(1,1) == 1) % min
        set(h, 'Color', 'k', 'LineStyle', '--')
    else
        set(h, 'Color', 'w', 'LineStyle', '--')
    end
    
    set(gca, 'TickDir','out')
	
    % subplots for projections
    
    subplot(4,4,[1:3])
    semilogx(x,sum(FEst,1))
    set(gca,'XAxisLocation','top');
    v1 = axis;
    axis([v(1) v(2) v1(3) v1(4)])
    
    subplot(4,4,[8 12 16])
    semilogx(y,sum(FEst,2))
    
    v2 = axis;
    axis([v(3) v(4) v2(3) v2(4)])
    view(90,90)
    
    set(gca,'YDir','reverse','XDir','reverse');
    set(gca,'XAxisLocation','top');
    
    % reset the target figure
    subplot(4,4,[5:7 9:11 13:15])
    
