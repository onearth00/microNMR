function [fidlist]=FIDscan(startfreq,NoScan,step,RD, TD,t90,NA,dummyscan,p,myNMR)
disp 'FID by freq scanning.'
disp 'Make sure sample is in the magnet !'
pause(2);
%LarmorFreq = 23.0268*1000000; % M2.1 at room temperature
%LarmorFreq = 23.4268*1000000
o1 = 0;
%RD = 5e6;
%TD = 500;
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,9);pause(0.1);
myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);
NMR_job = 101;
code1 = hex2dec('0201'); % run FID_mcbsp command

fidlist=[];
seed = 0:(NoScan-1);
fidlist0=zeros(TD,size(seed,2));
o1list= seed*step;
%
for ii=1:length(o1list)
   
    o1 = o1list(ii)
    [Nint, Nfrac] = setfreq((startfreq+o1)*2); 
    myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
    myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
    
    disp 'returned Nint and Nfrac from pulling the MCU.'
    temp = myNMR.readparams();
    [temp(19) temp(20)/1e6 (startfreq+o1)*2 - 32e6*(temp(20)/2^24+temp(19))/62 32e6*(temp(20)/2^24+temp(19))/1e9 ]
    pause(1);
    
    myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);

    
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
    fidlist(:,ii) = y;
    subplot(2,1,1)
    nmrplot(y,0.01)
    xlabel('acquisition time, ms')
    ylabel('NMR signal')
    title('One-shot FID data')
    
    
    subplot(212)
    nmrplot(fidlist0(:),1)
    xlim([0 TD*size(seed,2)])
    hold all
    nmrplot(fidlist(:),1)
    xlabel('acquisition points')
    ylabel('NMR signal')    
    title('frequency sweeping data')
end
hold off
end