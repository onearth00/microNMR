function [y2]=CPMGacq_ws(echoshape, infreq,RD,TE, TD,t90,t180,NA,dummyscan,dummyecho,p,myNMR)

NMR_job = 101;
code = hex2dec('0401');     % CPMG_mcbsp
%TE = 3000;
%TD = 1000;
%NA = 4;
%RD = 8e6;

myNMR.setNMRparameters(p.i_echoshape,echoshape);pause(0.1); % here is to update echo shape recording (or not) 
myNMR.setNMRparameters(p.i_recgain,9);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);
myNMR.setNMRparameters(p.i_dummyecho,dummyecho);pause(0.1);

% myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1); pause(0.1);
 [Nint, Nfrac] = setfreq(infreq); 
    
    myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
    myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
    
    disp 'returned Nint and Nfrac from pulling the MCU.'
    temp = myNMR.readparams();
    [temp(19) temp(20)/1e6 infreq - 32e6*(temp(20)/2^24+temp(19))/62 32e6*(temp(20)/2^24+temp(19))/1e9 ]
    pause(1);
    
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_T90,t90);pause(0.1);
myNMR.setNMRparameters(p.i_T180,t180);pause(0.1);
myNMR.setNMRparameters(p.i_TE,TE);pause(0.1);

caplist = 4000;

fidlist = [];
for ii=1:1 %length(caplist)
    
    myNMR.setNMRparameters(p.i_tuningcap,caplist(ii) ); pause(0.1);
    myNMR.write_1register(NMR_job,code);
    
    pause(3)
    

    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['relaxation Data to transfer=',num2str(x)])
    
    y2 = myNMR.read_NMR_data_ws(x);
    fidlist(:,ii) = y2(:);
    
    %
  %  subplot(2,1,2)
%     nmrplot(y2,1);
%     xlabel('time in ms')
%     ylabel('Signal amplitude')
%     title('One-shot relaxation experiment, 20 echos')
end
end

