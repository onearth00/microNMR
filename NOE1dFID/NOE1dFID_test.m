%function [y,f,p0]=NOE1dFID(infreq1H, RD, tune,TD,t90,NA,dummyscan,p,myNMR)
function NOE1dFID()

% infreq : hydrogen freq
% 
% Need to get the system to fully set up
% 

myNMR.read_temp2()

%%
% magnet 1,2,3 => M2.1, M2.2, M2.3
% magnet 4 => high res
    LarmorFreq = myNMR.MagnetFreq(22,3)      % room temp
    disp 'Assume room temp 22 C'
    %
p = pindex;
    DS = 0;
%  *******************************
% set parameters
%   *******************************


myNMR.setNMRparameters(p.i_freq, LarmorFreq+o1);pause(0.1);
LarmorFreq+o1

% acq parameters
HLarm = 42.57e6;
FLarm = 40.052e6;

infreq1H = LarmorFreq;
infreq19F = infreq1H*FLarm/HLarm;

o1H = 45e3;
o1F = 30e3;

tuneCap1H = 3500;
tuneCap19F = 700;


TD = 1000;
t90 = 7;
RD = 2e6;
NA =1;
rg = 11;

disp 'NOE1d with FID acquistion'
disp 'Make sure sample is in the magnet !'

myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,rg);pause(0.1);
myNMR.setNMRparameters(p.i_ds,0);pause(0.1);


for ii=1:10

% for 1H as f1
     myNMR.setNMRparameters(p.i_freq, infreq1H+o1H);pause(0.1);
     myNMR.setNMRparameters(p.i_tuningcap, tuneCap1H); pause(0.1);    

     figure(1)
     disp 'Acquire 1H signal ...'
     [nmrdata, peakfreq] = getNMRspec(myNMR,2, 1);

        title('H-1')

    % for 19-F as f1
    disp 'Acquire 19F signal ...'

    tuneCap19F = 700;
     myNMR.setNMRparameters(p.i_freq, infreq19F+o1F);pause(0.1);
     myNMR.setNMRparameters(p.i_tuningcap, tuneCap19F); pause(0.1);    

        figure(1)
     [nmrdata, peakfreq] = getNMRspec(myNMR,2, 3);

        title('F-19')
 end
%% check phase jump
    
    
    
%% run the NOE seq
infreq1H = LarmorFreq;
infreq19F = infreq1H*FLarm/HLarm;

o1H = 45e3;
o1F = 30e3;
TD = 1000;
t90 = 7;
RD = 2e6;       % initial WT, in F channel
NA =1;
rg = 11;

tau = 1000*1000; % wait time between f2 and f1 segments

disp 'NOE1d with FID acquistion'
disp 'Make sure sample is in the magnet !'

% F2 receive
 myNMR.setNMRparameters(p.i_freq, infreq19F+o1F);pause(0.1);
 myNMR.setNMRparameters(p.i_tuningcap, tuneCap19F); pause(0.1);    

% F1, CPMG sat
myNMR.setNMRparameters(p.i_nint, infreq1H+o1H);pause(0.1);
myNMR.setNMRparameters(p.i_nfrac, tuneCap1H); pause(0.1);    

myNMR.setNMRparameters(p.i_RD, RD); pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);
myNMR.setNMRparameters(p.i_T90, t90); pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,rg);pause(0.1);
myNMR.setNMRparameters(p.i_ds,0);pause(0.1);
myNMR.setNMRparameters(p.i_tau,tau);pause(0.1);

nmrdatalist = [];
figure(2)
for ii=1:100
    [nmrdata, peakfreq] = getNMRspec(myNMR, 100, 1);
    subplot(222)
    axis([-50 50 -100 12000])
    nmrdatalist(:,ii) = nmrdata(:);
    title(num2str(ii))
%     [nmrdata, peakfreq] = getNMRspec(myNMR, 100, 3);
%     subplot(224)
%     axis([-50 50 -100 12000])
end
%%
nmrplot(nmrdatalist(12,:)')

ngood = find(real(nmrdatalist(12,:)>400));
avgdata = mean(nmrdatalist(:,ngood),2);
nmrplot(avgdata)
%%
blc = mean(avgdata(TD/2:end));
data1 = nmrshift(avgdata - blc,4);

nmrplot(abs(nmrfft(data1)))

 %%
myNMR.startExpt(100,1);   % 5 is tuning; 6=>get full tuning curve
                            % 100 is test_seq
                            
    disp 'starting ...'
        x=0;
        while x==0
            pause(1);
            fprintf(1,'waiting ... ')
            x = myNMR.readstatus();  
            pause(1);
        end

        disp(['FID Data to transfer=',num2str(x)])

        %
        pause(1)
        y = myNMR.read_NMR_data(x);
%
figure(2)
        nmrplot(y,0.01)

end    

function showdata(nmrdata, whichpanel)
    %
y = nmrdata;

    subplot(2,2,whichpanel)
    nmrplot(y,0.01)
    xlabel('acquisition time, ms')
    ylabel('NMR signal')
   % title('FID data')
   axis tight
    
    subplot(2,2,whichpanel+1)
    fs = 1/(10.0e-6); %10e-6 is the dwell time.
    L = size(y,1);

    Y = fft(y);
    p2 = abs(Y/L);
    p1 = p2(1:L/2+1);
    p3 = p2(L/2+2:end);
    p0 = [p3 ; p1];
    f=fs*((-L/2):((L/2-1)))/L/1000;
    plot(f,p0)
    xlabel('frequency in kHz')
    ylabel('FFT amplitude')
end


function [nmrdata, peakfreq] = getNMRspec(myNMR, expcode, showpanel)
    myNMR.startExpt(expcode,1);   % 5 is tuning; 6=>get full tuning curve
                                    % 100 is experimental seq
    disp 'starting ...'
        x=0;
        while x==0
            pause(1);
            fprintf(1,'waiting ... ')
            x = myNMR.readstatus();  
            pause(1);
        end

        disp(['FID Data to transfer=',num2str(x)])

        %
        pause(1)
        y = myNMR.read_NMR_data(x);
        nmrdata= y(:);
        
        ndata = length(nmrdata);
        blc = mean(nmrdata(floor(ndata*3/4):ndata));
        nmrdata = nmrdata ;
        
        
        L = size(y,1);
        y = nmrshift(nmrdata(:)-blc,4);
        y = y.*exp(-(1:length(nmrdata))'/200);            
        [p0, f] =nmrfft(y,0.01);
            
            [peak,n] = max(abs(p0));
            
            x = find(abs(p0)>peak*3/4);
            
            peakfreq = sum(f(x).*abs(p0(x)))/sum(abs(p0(x)));
            
            
        if 1
            subplot(2,2,showpanel)
            nmrplot(nmrdata,0.01)
            xlabel('acquisition time, ms')
            ylabel('NMR signal')
           % title('FID data')

            subplot(2,2,showpanel+1)

            plot(f,abs(p0))
            xlabel('frequency in kHz')
            ylabel('FFT amplitude')
        end
        %sound(real(y)/5)
end