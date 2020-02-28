function save_data(myNMR,infreq,y,folder,name,saveornot)
%         i_asci_ver = 1;
%         i_tuningcap=2;
%         i_recgain=3;
%         i_na=4;
%         i_ds=5;
%         i_dwell=6;
%         i_T90=7;
%         i_T180=8;
%         i_TE=9;
%         i_notinuse=10;
%         i_TD=11;
%         i_TD1=12;
%         i_TD2=13;
%         i_maxTD=14;
%         i_acqiredTD = 15;
%         i_RD = 16;
%         i_freq = 17;
%         i_echoshape = 18; %added 8/23/2017
%         i_nint = 19; 
%         i_nfrac = 20;
%         i_dummyecho = 21;
%         i_tau = 22; %tau for T1 measurement
%         i_ws = 23;
%         i_error=24;
if saveornot == 0 
else
    para = myNMR.readparams();

    all_data(1).para = [para infreq];
    all_data(2).data = y;
    cd(folder)
    save(name, 'all_data');
end
end