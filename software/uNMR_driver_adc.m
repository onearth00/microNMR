% uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:1
    temp(ii) = myNMR.read_temp2();
    pause(1)
end
temp
if length(temp)>2
    plot(temp)
else
    temp
end


%% poll uNMR status

x = myNMR.readstatus();
disp(['Number of data points to be transferred=',num2str(x)])

%%
y=[];
for kk=1:1

    y = myNMR.read_NMR_data(100);
    figure(1)
    nmrplot(y)
    pause(0.1)
end
disp ('Done')

%% write to NMR_job


NMR_job=101;
code = hex2dec('0901');
code = hex2dec('0001');
for ii=1:10
    myNMR.write_1register(NMR_job,code);
    pause(1)
ii
    x=0;
    while x==0
        x = myNMR.readstatus();
        disp(['Number of data points to be transferred=',num2str(x)])
    end
    

    %
    x = myNMR.readstatus();
    y = myNMR.read_NMR_data(20   );
    real(y);
    imag(y);
    subplot(111)
    plot(real(y)*2.5/2^14,'rs-','markersize',1)
    hold on
    plot(imag(y)*2.5/2^14,'ks-','markersize',1)
    hold off
    ylabel('Voltage, V')
    h=axis;
    axis([h(1:2) 0 2.5])
end

%real(y(1:10))*2.5/2^14
%
[dec2bin(real(y(1:10)),16)]
[dec2bin(imag(y(1:10)),16)]


 fprintf(1,'%b', 7)