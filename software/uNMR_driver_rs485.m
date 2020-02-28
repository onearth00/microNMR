% uNMR driver
% YS Dec 2016 --
% March 2, 2017
% measure rs485 behavior. 
% Change the serial speed to 115,200 bps. 
% Allow the port to stay open during the read_NMR_data to speed up.
% There is a 12ms delay between transmitting the command and receiving the
% response. Don;t know how to reduce that. Probably in modbus code.

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:200
    try
        temp(ii) = myNMR.read_temp2();
    end
   
    if length(temp)>2
        plot(temp,'o-')
    end
    pause(1)
end
avgTemp = mean(temp)
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,4)
else
    LarmorFreq = myNMR.MagnetFreq(25,4)      % room temp
    disp 'Assume room temp 25 C'
end
%%
NA = 1;
DS = 0;
TE = 1000;
TD = 200;
p = pindex;

cap=4000;
myNMR.setNMRparameters(p.i_tuningcap, cap); pause(0.5);




%%  *******************************
% set parameters
%   *******************************
tic
for ii=1:1
x = myNMR.readstatus();
end
toc
tic
y = myNMR.read_NMR_data(3000);
    toc
    nmrplot(y)