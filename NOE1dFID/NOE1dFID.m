function [y,f,p0]=NOE1dFID(infreq, RD, tune,TD,t90,NA,dummyscan,p,myNMR)
% infreq : hydrogen freq
% 

HLarm = 42.57e6;
FLarm = 40.052e6;

disp 'FID by freq scanning.'
disp 'Make sure sample is in the magnet !'
%%
%pause(2);
%LarmorFreq = 23.0268*1000000; % M2.1 at room temperature
%LarmorFreq = 23.4268*1000000
%RD = 5e6;
%TD = 500;
  tune = 1000;
 t90=10;
 dummyscan = 0;
 NA = 2;
 RD = 3e6;
 TD = 1000;

% H-1
infreq = myNMR.MagnetFreq(20,3);

%F-19
  myNMR.setNMRparameters(p.i_nint, infreq*FLarm/HLarm);pause(0.1);
%  
% 
  myNMR.setNMRparameters(p.i_freq, infreq);pause(0.1);
%     
 myNMR.setNMRparameters(p.i_tuningcap, tune); pause(0.1);   
 myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
 myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
 myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
 myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
 myNMR.setNMRparameters(p.i_recgain,10);pause(0.1);
 myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);
% 
% 
% myNMR.setNMRparameters(p.i_freq,LarmorFreq); pause(0.1);
tic
for kk = 1:100
    myNMR.startExpt(2,1);   % 5 is tuning; 6=>get full tuning curve
    disp 'starting ...'
        x=0;
        while x==0
            pause(2);
            fprintf(1,'waiting ... ')
            x = myNMR.readstatus();      
        end

        disp(['FID Data to transfer=',num2str(x)])

        %
        y = myNMR.read_NMR_data(x);
        datalist(:,kk) = y(:);
        
        subplot(2,1,1)
        nmrplot(y,0.01)
        xlabel('acquisition time, ms')
        ylabel('NMR signal')
       % title('FID data')

        subplot(2,1,2)
        fs = 1/(10.0e-6); %10e-6 is the dwell time.
        L = size(y,1);

        Y = fft(y);
        p2 = abs(Y/L);
        p1 = p2(1:L/2+1);
        p3 = p2(L/2+2:end);
        p0 = [p3 ; p1];
        f=fs*((-L/2):((L/2-1)))/L;
        plot(f,p0)
        xlabel('frequency in Hz')
        ylabel('FFT amplitude')
pause (1)
kk
        [peak,n] = max(p0);
        peaklist(kk,1) = f(n);
        peaklist(kk,2) = toc;
        %sound(real(y)/5)
    end
end    