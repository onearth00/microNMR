function [y,f,p0]=FID(infreq, RD, tune,TD,t90,NA,dummyscan,p,myNMR)
disp 'FID by freq scanning.'
disp 'Make sure sample is in the magnet !'
%pause(2);
%LarmorFreq = 23.0268*1000000; % M2.1 at room temperature
%LarmorFreq = 23.4268*1000000
%RD = 5e6;
%TD = 500;
 [Nint, Nfrac] = setfreq(infreq*2); 
 myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
 myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
    
 disp 'returned Nint and Nfrac from pulling the MCU.'
 temp = myNMR.readparams();
 [temp(19) temp(20)/1e6 infreq*2 - 32e6*(temp(20)/2^24+temp(19))/62 32e6*(temp(20)/2^24+temp(19))/1e9 ]
 pause(1);
 
myNMR.setNMRparameters(p.i_tuningcap, tune); pause(0.1);   
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,9);pause(0.1);
myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);
%myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
NMR_job = 101;
code1 = hex2dec('0201'); % run FID_mcbsp command

%    myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
    disp('now execute pp')    
    myNMR.write_1register(NMR_job,code1);

   
    x=0;
    while x==0
        pause(1)
        x = myNMR.readstatus();
        
    end
    disp(['FID Data to transfer=',num2str(x)])
    
    y = myNMR.read_NMR_data(x);
    
    subplot(2,1,1)
    nmrplot(y,0.01)
    xlabel('acquisition time, ms')
    ylabel('NMR signal')
   % title('FID data')
    
    subplot(2,1,2)
    fs = 1/(10.0e-6); %10e-6 is the dwell time.
    L = size(y,1);

    Y = fft(y)
    p2 = abs(Y/L);
    p1 = p2(1:L/2+1);
    p3 = p2(L/2+2:end);
    p0 = [p3 ; p1];
    f=fs*((-L/2):((L/2-1)))/L;
    plot(f,p0)
    xlabel('frequency in Hz')
    ylabel('FFT amplitude')
end    