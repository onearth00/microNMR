function  FLIPlot2dFullDT2(D, T2, FEst, inCM)  
% 
% function  FLIPlot2dFullDT2(D, T2, FEst, inColorMap) 
%
% plot the 2d density function
% 
% FEst : col - diffusion, row - T2 relaxation
% diffusion unit : 10e-5 cm2/s
% Relaxation unit: second
% 

    x=T2;y=D;
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
    pcolor(x,y, FEst(1:length(x), 1:length(y))'), colormap(theCM), shading interp; %, colorbar;
    hold on
    mycontourlines = [0.02 0.05 .1 .3 .5 .7 .9]*max(max(FEst));
    contour(x, y, FEst(1:length(x), 1:length(y))',mycontourlines,'m-')
    hold off
	
    h = gca;
	set(h, 'XScale', 'log', 'YScale', 'log')
	ylabel('D (cm^2/s)', 'FontSize', 9)
	xlabel('T_2 (secs)', 'FontSize', 9)
	set(gca, 'FontSize', 10);
	set(gca, 'XTickMode', 'Manual');
	set(gca, 'XTick', [1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10 100]);
	set(gca, 'YTickMode', 'Manual');
	set(gca, 'YTick', [1e-12 1e-11 1e-10 1e-9 1e-8 1e-7 1e-6 1e-5 1e-4 1e-3 1e-2 1e-1 1 10 100]);
	title('DT2 plot', 'FontSize', 9);
    
    
    
	v(1) = min(x); v(2) = max(x); V(3) = min(y); v(4) = max(y);
	axis(v)
	theCM = colormap;
	h = line([min(x) max(x)], [2 2]);
	
    if (theCM(1,1) == 1) % min
        set(h, 'Color', 'k', 'LineStyle', '--')
    else
        set(h, 'Color', 'w', 'LineStyle', '--')
    end
    
 	%h = line([min(x) max(x)], [min(x) max(x)]);
 	h = line([0.005 5], [0.002 2]);
    if (theCM(1,1) == 1) % min
        set(h, 'Color', 'k', 'LineStyle', '--')
    else
        set(h, 'Color', 'w', 'LineStyle', '--')
    end
   
    set(gca, 'TickDir','out')
	

    
    % subplots for projections
    
    subplot(4,4,[1:3])
    semilogx(x,sum(FEst,2))
    set(gca,'XAxisLocation','top');
    v1 = axis;
    axis([v(1) v(2) v1(3) v1(4)])
    
    subplot(4,4,[8 12 16])
    semilogx(y,sum(FEst,1))
    
    v2 = axis;
    axis([v(3) v(4) v2(3) v2(4)])
    view(90,90); % rotate the plot
    
    set(gca,'YDir','reverse','XDir','reverse');
    set(gca,'XAxisLocation','top');
    
    

    
    
    