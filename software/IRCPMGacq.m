function [fidlist]= IRCPMGacq(RD,TE, TD,t90,t180,NA,dummyscan,dummyecho,vd,p,myNMR)

NMR_job = 101;
code = hex2dec('0801');     % IRCPMG_mcbsp

echoshape = 0;
myNMR.setNMRparameters(p.i_echoshape,echoshape);pause(0.1); % here is to update echo shape recording (or not) 
% myNMR.setNMRparameters(p.i_recgain,6);pause(0.1); %change from 9 to 8 to avoid RX saturation
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_ds,dummyscan);pause(0.1);
myNMR.setNMRparameters(p.i_dummyecho,dummyecho);pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_T90,t90);pause(0.1);
myNMR.setNMRparameters(p.i_T180,t180);pause(0.1);
myNMR.setNMRparameters(p.i_TE,TE);pause(0.1);
fidlist = [];

for ii=1:size(vd,2) %length(caplist)
    
%   myNMR.setNMRparameters(p.i_tuningcap,caplist(ii) ); pause(0.1);
    myNMR.setNMRparameters(p.i_tau, vd(ii)); pause(0.1);
    myNMR.write_1register(NMR_job,code);
    
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(1)
    end
    disp(['relaxation Data to transfer=',num2str(x)])
    
    y2 = myNMR.read_NMR_data(x);
    fidlist(:,ii) = y2;
    
    plot(1:TD,abs(y2)*sign(mean(real(y2(2:5))))); %plot the signed amplitude
    xlabel('# of pts')
    ylabel('echo amplitude')
    hold all
    
end
hold off
end

