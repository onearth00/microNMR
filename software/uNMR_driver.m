 % uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:20
    temp(ii) = myNMR.read_temp2();
    pause(1)
end
temp
if length(temp)>2
    plot(temp)
end

%% read temp using read_1reg
% read temp
x=read_1register(myNMR,7);
%x=myNMR.read_register(7, 1, 7);
x=dec2hex(x)';
x = hex2dec(x(:)')*0.0315

%% read ADC, LTC1407. only one channel. 12 bits
v=[];
for ii=1:1
    x=read_1register(myNMR,8);
    double(x);
    pause(.1)
    x=dec2hex(x)';
    v(ii) = hex2dec(x(:)')/4096*2.5;
fprintf(1,'ADC=%d volt\r',v(ii))
end

if length(v)>2
    plot(v)
end


%% write a command to DAC

reg_DAC = 3;

data = 0;
    
%x=myNMR.write_1register(reg_DAC,[d1(1),d1(2)]);
x=myNMR.write_1register(reg_DAC,data);
pause(1)
%x=myNMR.write_1register(reg_DAC,[0,0]);

%% write more than 1 reg
reg_DAC = 3;
reg_PLL=11;
x=myNMR.write_registers(11,[0,1]);
if isempty(x) 
    disp 'Error. no return message'
elseif double(x(2)>128) 
    disp (['Error code=' num2str(double(x(3))) ])
else
    disp (['Write correctly. Return message received.' ])
end

%% set ASIC gain
% reg_ASIC_gain=102;
% x=myNMR.write_1register(reg_ASIC_gain,31);
% pause(2)
% x=myNMR.read_1register(reg_ASIC_gain);

x = myNMR.setgain(10)

%% poll uNMR status

x = myNMR.readstatus();
disp(['Number of data points to be transferred=',num2str(x)])

y=[];
for kk=1:1

    y = myNMR.read_NMR_data(x);
    figure(1)
    nmrplot(y)
    pause(0.1)
end
disp ('Done')

%% NMR, copy from David's python

% calcualte freq
 % PLL Initial set-up - 40M Hz\n",
    myNMR.write_registers(11,[0,2])   %# RST Register\n",
    myNMR.write_registers(12,[0,1])   %# REFDIV Register\n",
    myNMR.write_registers(13,[0,77])   %# Frequency Register Int (40M Hz)\n",
    myNMR.write_registers(15,[0,32528])   %# VCO_Reg0x02, R, output Divide\n",
    myNMR.write_registers(15,[0,65280])   %# VCO_Reg0x00, VCO subband\n",
    myNMR.write_registers(16,[0,3914])   %# Delta-Sig Config Register\n",
    myNMR.write_registers(17,[0,9677])   %# Lock detect register\n",
    myNMR.write_registers(18,[193,48895])   %# Analog enable register\n",
    myNMR.write_registers(19,[48,60762])   %# CP Reg0x09\n",
    myNMR.write_registers(14,[65,54302])   %# Frequency Register Frac\n",



%reg_NMR = 101;
%x=myNMR.write_1register(reg_NMR,[0,1]);

%% 
%
issue NMR command

Test_pull_from_serial_for NMR data

