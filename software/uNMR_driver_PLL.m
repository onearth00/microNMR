 % uNMR driver
% YS Dec 2016

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:2
    temp(ii) = myNMR.read_temp2();
    pause(1)
end
temp
if length(temp)>2
    plot(temp)
end


%% poll uNMR status

x = myNMR.readstatus();
disp(['Number of data points to be transferred=',num2str(x)])

y=[];
for kk=1:1

    y = myNMR.read_NMR_data(10);
    figure(1)
    nmrplot(y)
    pause(0.1)
end
disp ('Done')

%% write to NMR_job


NMR_job=101;
code = hex2dec('0901');
code = hex2dec('0001');
for ii=1:1
    myNMR.write_1register(NMR_job,code);
    pause(1)
    ii
end

%% NMR, copy from David's python

% calcualte freq
 % PLL Initial set-up - 40M Hz\n",
    myNMR.write_registers(11,[0,2])   %# RST Register\n",
    myNMR.write_registers(12,[0,1])   %# REFDIV Register\n",
    myNMR.write_registers(13,[0,77])   %# Frequency Register Int (40M Hz)\n",
    myNMR.write_registers(15,[0,32528])   %# VCO_Reg0x02, R, output Divide\n", div=62
    myNMR.write_registers(15,[0,65280])   %# VCO_Reg0x00, VCO subband\n",
    myNMR.write_registers(16,[0,3914])   %# Delta-Sig Config Register\n",
    myNMR.write_registers(17,[0,9677])   %# Lock detect register\n",
    myNMR.write_registers(18,[193,48895])   %# Analog enable register\n",
    myNMR.write_registers(19,[48,60762])   %# CP Reg0x09\n",
    myNMR.write_registers(14,[65,54302])   %# Frequency Register Frac\n",


    
    %% 
    
f_xtal = 32*10^6;       % crystal freq
k_out = 62;  % output divider, reg 5
R = 1;  % ref divider




freq = 46.3942253*10^6;


f_vco = freq*k_out;

% reg 3
N_int = floor(f_vco / f_xtal)
% reg 4
N_frac = floor(mod(f_vco, f_xtal)/f_xtal*2^24)

freq_err = f_xtal*(N_int+N_frac/2^24)/k_out - freq;


x = [floor(N_frac/2^16) mod(N_frac,2^16)]
%myNMR.write_registers(14,x)

%myNMR.write_registers(14,[65,54302])   %# Frequency Register Frac\n",


%reg_NMR = 101;
%x=myNMR.write_1register(reg_NMR,[0,1]);

%% 



