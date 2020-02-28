% This is to characterize the tuning behavior of the microstrip 
% Ray Tang 11/06/2017

clear
myNMR = uNMR('COM6')
p = pindex;

% set parameter values

DS = 0;
NA = 2;

infreq = [23.4*1000000 + 4e4 + 9600 23*1000000 + 4e4 + 9600 22.8*1000000 + 4e4 + 9600]; %in hertz
%datatitle = ['data11.mat' 'data12.mat' 'data13.mat']

% pass parameter values to DSP
% [Nint, Nfrac] = setfreq(infreq*2); 
% myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
% myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
myNMR.setNMRparameters(p.i_ds, DS); pause(0.1);
myNMR.setNMRparameters(p.i_recgain,2);pause(0.1);
myNMR.setNMRparameters(p.i_na, NA); pause(0.1);

% sweep DAC voltage
nofv = 20;
pulse_ampl = zeros(1,nofv);
pulse_phase = zeros(1,nofv);
tunev = linspace(200,4000,nofv);
datalist = [];
save('data.mat','datalist')
%%
% this program 

for jj = 1:size(infreq,2)
    [Nint, Nfrac] = setfreq(infreq(jj)*2); 
    myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
    myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
    datalist = [];
    for i = 1:nofv

        myNMR.setNMRparameters(p.i_tuningcap, tunev(i));pause(0.1);
        tunev(i)

        disp 'parameters have been set.'
    % observe RF pulses
        pause(0.5)

        %disp 'Observe the RF pulse.'
        % disp ''

        NMR_job = 101;
        code = hex2dec('0501'); % run tuning command
       % phase_angle=[];
        for ii=1:1
            myNMR.write_1register(NMR_job,code);
            pause(.5)

            x=0;
            while x==0
                x = myNMR.readstatus();
                pause(1)
            end
            disp(['Data to transfer=',num2str(x)])

            y = myNMR.read_NMR_data(x)*2.5/2^12;
            datalist(:,i) = y;
            real(y);
            imag(y);
            subplot(2,1,2)
            plot(real(y),'rs-','markersize',1)
            hold on
            plot(imag(y),'ks-','markersize',1)
            hold off
            ylabel('Voltage, V')
            h=axis;
            %axis([h(1:2) 0 2.5])
            xlabel('acq points (10us)')
            title(num2str(i))    
        end

        pulse_ampl(i) = mean(abs(y(30:50))); % calibrate to volt.
        pulse_phase(i) = atan(mean(imag(y(30:50)))/mean(real(y(30:50))));
    end
    subplot(211)
    plot(tunev/4096*2.5,pulse_ampl,'o')
    xlabel('DAC output in v')
    ylabel('received voltage amplitude')
    title(['input frequency at ' num2str(infreq(jj))])
    subplot(212)
    plot(tunev/4096*2.5,pulse_phase*180/pi,'o')
    xlabel('DAC output in v')
    ylabel('received voltage phase')
    saveas(gcf,['1' num2str(jj) '.png'])
    
    save(['data1' num2str(jj) '.mat'],'datalist')
   
end
%% load back data:
clear datalist
load data13
clear pulse_ampl pulse_phase
pulse_ampl = mean(abs(datalist(30:50,:))); % calibrate to volt.
pulse_phase = atan(mean(imag(datalist(30:50,:)))./mean(real(datalist(30:50,:))));
    
subplot(211)
plot(tunev/4096*2.5,pulse_ampl,'o')
xlabel('DAC output in v')
ylabel('received voltage amplitude')
title(['input frequency at ' num2str(infreq(jj))])
hold all
subplot(212)
plot(tunev/4096*2.5,pulse_phase*180/pi,'o')
xlabel('DAC output in v')
hold all
%% sweep frequency
clf
nofv = 10;
tunev = [500];
tunev = linspace(500,4000,nofv);
index = [1:nofv];
%infreq = 22.8*1000000 + 4e4 + 9600+ (-40:2:35)*50000; %in hertz
infreq = 22.8*1000000 + 4e4 + 9600+ (-30:2:30)*50000; %in hertz

parameter(1).infreq = infreq;
parameter(2).tunev = tunev;

save('parameter.mat','parameter')
clear pulse_ampl pulse_phase

for kk = 1:size(index,2)
  
    myNMR.setNMRparameters(p.i_tuningcap, tunev(index(kk)));pause(0.1);
    datalist=[];
    
    for i = 1:size(infreq,2)
        infreq(i)
        [Nint, Nfrac] = setfreq(infreq(i)*2); 
        myNMR.setNMRparameters(p.i_nint, Nint);pause(0.1);
        myNMR.setNMRparameters(p.i_nfrac, Nfrac);pause(0.1);
        
        disp 'returned Nint and Nfrac from pulling the MCU.'
        temp = myNMR.readparams();
        [temp(19) temp(20)/1e6 infreq(i)*2 - 32e6*(temp(20)/2^24+temp(19))/62 32e6*(temp(20)/2^24+temp(19))/1e9 ]
      %   pause(1)

        disp 'parameters have been set.'
%        pause(0.5)

        NMR_job = 101;
        code = hex2dec('0501'); % run tuning command
        
        phase_angle=[];
        
            myNMR.write_1register(NMR_job,code);
 %           pause(.5)


            x=0;
            while x==0
                x = myNMR.readstatus();
 %               pause(1)
            end
            disp(['Data to transfer=',num2str(x)])

            y = myNMR.read_NMR_data(x)*2.5/2^12;
            datalist(:,i) = y;
            real(y);
            imag(y);
            subplot(2,1,2)
            plot(real(y),'rs-','markersize',1)
            hold on
            plot(imag(y),'ks-','markersize',1)
            hold off
            ylabel('Voltage, V')
            h=axis;
            %axis([h(1:2) 0 2.5])
            xlabel('acq points (10us)')
            title(num2str(i)) 
            
            pulse_ampl(i) = mean(abs(y(30:50))); % calibrate to volt.
            pulse_phase(i) = atan(mean(imag(y(30:50)))./mean(real(y(30:50))));
    end 
    
    subplot(211)
    plot(infreq/1e6,pulse_ampl,'o')
    xlabel('freq in MHz')
    ylabel('received voltage amplitude')
    title(['DAC voltage at ' num2str(tunev(index(kk)))])
    subplot(212)
    plot(infreq/1e6,pulse_phase*180/pi,'o')
    xlabel('freq in MHz')
    ylabel('received voltage phase')
    saveas(gcf,['2' num2str(kk) '.png'])
    save(['data2' num2str(kk) '.mat'],'datalist')
end
%
% sign correction on phase

%infreq = 22.8*1000000 + 4e4 + 9600+ (-40:2:35)*50000; %in hertz
%infreq = 22.8*1000000 + 4e4 + 9600+ (-40:2:20)*50000; %in hertz

for i = 1:nofv
    dataset = ['data2' num2str(i)]
    load(dataset)
    clear pulse_ampl pulse_phase
    pulse_ampl = mean(abs(datalist(30:50,:))); % calibrate to volt.
    pulse_phase = atan(mean(imag(datalist(30:50,:)))./mean(real(datalist(30:50,:))));
    for jj = 1:size(pulse_phase,2)
        if pulse_phase(jj) < 0
            pulse_phase(:,jj:end) = pi+pulse_phase(:,jj:end);
            break;
        else
        end
    end
    figure(1)
    subplot(211)
    plot(infreq/1e6',pulse_ampl,'-')
    xlabel('freq in MHz')
    ylabel('received voltage amplitude')
    title('no flank caps')
  %  legend(num2str(tunev(i)))
   
    hold all
    subplot(212)
    plot(infreq/1e6',pulse_phase*180/pi,'-')
    xlabel('freq in MHz')
    ylabel('received voltage phase')
%     pause
    hold all
end
%%
cd 'C:\Users\ytang12\Desktop\tuning baseline'
load data21
database = datalist;

cd 'C:\Users\ytang12\Desktop\tuning baseline\c =10 pf and r = 90k'
load data21
data = datalist;

clear pulse_ampl pulse_phase
pulse_amplbase = mean(abs(database(30:50,:))); % calibrate to volt.
pulse_phasebase = atan(mean(imag(database(30:50,:)))./mean(real(datalist(30:50,:))));

pulse_ampl = mean(abs(data(30:50,:))); % calibrate to volt.
pulse_phase = atan(mean(imag(data(30:50,:)))./mean(real(datalist(30:50,:))));
    
subplot(211)
plot(tunev/4096*2.5,(pulse_ampl-pulse_amplbase),'o')
xlabel('DAC output in v')
ylabel('received voltage amplitude')
title(['input frequency at ' num2str(infreq(jj))])
subplot(212)
plot(tunev/4096*2.5,(pulse_phase-pulse_phasebase)*180/pi,'o')
xlabel('DAC output in v')
%% subtract by the open circuit reading
cd 'C:\Users\ytang12\Desktop\tuning test\11072017'
j = 1;
load data21
database = datalist;

cd 'C:\Users\ytang12\Desktop\tuning test\11072017\c =10 pf and r = 90k'
load data21
data = datalist;

clear pulse_ampl pulse_phase
pulse_amplbase = mean(abs(database(30:50,:))); % calibrate to volt.
pulse_phasebase = atan(mean(imag(database(30:50,:)))./mean(real(datalist(30:50,:))));

pulse_ampl = mean(abs(data(30:50,:))); % calibrate to volt.
pulse_phase = atan(mean(imag(data(30:50,:)))./mean(real(datalist(30:50,:))));

figure(2)
%subplot(211)
plot(infreq/1e6',2.5^-1*pulse_ampl,'ro')
hold all
plot(infreq/1e6',pulse_amplbase,'bo')
xlabel('freq in MHz')
ylabel('received voltage amplitude')
title(['DAC voltage at ' num2str(tunev(index(j)))])
% hold all
% subplot(212)
% plot(infreq/1e6',(pulse_phase./pulse_phasebase)*180/pi,'o')
% xlabel('freq in MHz')
% ylabel('received voltage phase')
hold all

cd 'C:\Users\ytang12\Desktop'
saveas(gca,'1.png')
%% do manual phase correction
cd 'C:\Users\ytang12\Desktop\tuning baseline'
load data2
database = datalist;

cd 'C:\Users\ytang12\Desktop\tuning baseline\c =10 pf and r = 90k'
load data21
data = datalist;

% only look at 30 - 50 pts
data = data(30:50,:);
database = database(30:50,:);


% correct signs. sc for sign corrected
datasc = real(data).*sign(real(data)) + sqrt(-1)*(imag(data).*sign(imag(data)));
databasesc = real(database).*sign(real(database)) + sqrt(-1)*(imag(database).*sign(imag(database)));
plot(real(datasc(:))./imag(datasc(:)))

plot(real(datasc(:)),'b*')
hold all
plot(real(databasesc(:)),'r*')
plot(imag(datasc(:)),'bo')
plot(imag(databasesc(:)),'ro')
hold off
xlabel('number of pts')
ylabel('voltage')
title('DAC bias voltage at 3000, sign corrected')
legend('real data','real data baseline','imag data','imag data baseline')

cd 'C:\Users\ytang12\Desktop'
saveas(gca,'1.png')