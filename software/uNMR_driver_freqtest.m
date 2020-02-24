% uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR


% test of PLL freq set

%% test to read the board temp
temp=[];
for ii=1:5
    try
        temp(ii) = myNMR.read_temp2();
    end
    pause(1)
end
temp;
if length(temp)>2
    plot(temp)
else
    temp
end

avgTemp = mean(temp)
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,4)
else
    LarmorFreq = myNMR.MagnetFreq(25,4)      % room temp
    disp 'Assume room temp 25 C'
end

p = pindex;

%
myNMR.setNMRparameters(p.i_T90,15);pause(0.1);
myNMR.setNMRparameters(p.i_T180,30);pause(0.1);



%% find the max signal
TD=1000;
RD = 10000;
myNMR.setNMRparameters(p.i_TD, TD);pause(0.5);
myNMR.setNMRparameters(p.i_na, 1);pause(0.5);
myNMR.setNMRparameters(p.i_recgain, 5);pause(0.5);
myNMR.setNMRparameters(p.i_RD, RD);pause(0.5);
myNMR.setNMRparameters(p.i_tuningcap, 4000);pause(0.5);
myNMR.setNMRparameters(p.i_T90, 17);pause(0.5);

nmrparams= myNMR.readparams()'

%% run fid once
o1 = 10000;
f0 = LarmorFreq +o1;
RD = 1000000;
%
 myNMR.setNMRparameters(p.i_freq, f0);pause(0.1);
%
myNMR.setNMRparameters(p.i_TD, 1000);pause(0.1);
%
myNMR.setNMRparameters(p.i_dwell, 10);pause(0.1);
NMR_job = 101;
%code = hex2dec('0301'); 
code = hex2dec('0001'); 

for ii=1:1
myNMR.write_1register(NMR_job,code);

pause(2)

x = myNMR.readstatus(); pause(0.1)
y = myNMR.read_NMR_data(x);
%
nmrplot(y-y(end-10))
%
    if 0
        nmrparams=myNMR.readparams()';
        if     nmrparams(p.i_TD)-nmrparams(p.i_acqiredTD) ~= 0
                disp (['acquisition error:' ...
                num2str(nmrparams(p.i_TD)-nmrparams(p.i_acqiredTD))])
                %failure = failure + 1;
        end
    end
    
end

%%
TD = 1000;
o1 = 46000;
f0 = LarmorFreq +o1;
RD = 1000000;
myNMR.setNMRparameters(p.i_freq, f0);pause(0.1);
myNMR.setNMRparameters(p.i_RD, RD);pause(0.1);
myNMR.setNMRparameters(p.i_TD, TD);pause(0.1);
myNMR.setNMRparameters(p.i_na, 1);pause(0.1);
%
NMR_job = 101;
code = hex2dec('0001'); 
datalist=[];

failure=0;
for ii=1:1
    %myNMR.setNMRparameters(p.i_tuningcap, mylist(ii));pause(0.1);
    myNMR.write_1register(NMR_job,code);
    pause(0.1); ii
    x=0;
    while x==0
        x = myNMR.readstatus();
        pause(0.1)
    end
    
    if 1
        disp(['Number of data points to be transferred=',num2str(x)])
        y = myNMR.read_NMR_data(x);
        datalist(:,ii)=y(:);

        blc=mean(y(TD-50:end-10));
        figure(1)
        subplot(211)
        tau=(1:TD)*nmrparams(p.i_dwell)/1000;
        plot(tau,real(y-blc)*2.5/2^12,'r.-')
        hold on; 
        plot(tau,imag(y-blc)*2.5/2^12,'.-'); hold off
        ylabel('Signal, V')
        xlabel('time, ms')
        % fft
        subplot(212)
        [yf,w2] = (nmrfft(y(5:end-1)-blc,nmrparams(p.i_dwell)/1000));
        nmrplot(abs(yf),w2)
        h=axis;
        [a,b]=max(abs(yf));
        
        axis([-50 50 h(3:4)])
        title(['Peak at:' num2str(w2(b)) ' kHz'])
        
        pause(.10)
        
    end
end

disp 'done'
%
    
nmrparams= myNMR.readparams()';
nmrparams(p.i_error)/100
