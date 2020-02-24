function [y]=T1acq(RD, TD,t90,t180,NA,dummyscan,vd,p,myNMR) 
% [Nint, Nfrac] = setfreq(infreq*2); 
%  myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
%  myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
%     
%  disp 'returned Nint and Nfrac from pulling the MCU.'
%  temp = myNMR.readparams();
%  [temp(19) temp(20)/1e6 infreq*2 - 32e6*(temp(20)/2^24+temp(19))/62 32e6*(temp(20)/2^24+temp(19))/1e9]
%  pause(1);
   
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
myNMR.setNMRparameters(p.i_T180, t180); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,9);pause(0.1);
myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);

NMR_job = 101;
code1 = hex2dec('0701'); % run IR_mcbsp command

for i = 1:size(vd,2)
    myNMR.setNMRparameters(p.i_tau, vd(i)); pause(0.1);
    
    myNMR.write_1register(NMR_job,code1);

   
    x=0;
    while x==0
        pause(1)
        x = myNMR.readstatus();
        
    end
    disp(['FID Data to transfer=',num2str(x)])
    
    y(:,i) = myNMR.read_NMR_data(x);
 
    subplot(2,1,1)
    nmrplot(y(:),0.01)
    xlabel('acquisition time, ms')
    ylabel('NMR signal')
    title('FID data')
    
    subplot(212)
    nmrplot(y(:),1)
    xlim([0 TD*size(vd,2)])
    hold all
    nmrplot(y(:),1)
    xlabel('acquisition pts')
    ylabel('NMR signal')    
    title('T1 recovery data')
end
hold off
end