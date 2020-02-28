% uNMR driver
% YS Dec 2016 --
% March 3, 2017
% try to read the temp controller, ads1248

% uNMR parameters
% start by initializing 
myNMR = uNMR

%% test to read the board temp
temp=[];
for ii=1:1
    try
        temp(ii) = myNMR.read_temp2()
    end
   
    if length(temp)>2
        plot(temp,'o-')
    end
    pause(1)
end

floor(temp/0.03125)
%%
avgTemp = mean(temp)
if isnumeric(avgTemp)
    LarmorFreq = myNMR.MagnetFreq(avgTemp,4)
else
    LarmorFreq = myNMR.MagnetFreq(25,4)      % room temp
    disp 'Assume room temp 25 C'
end



%%  *******************************
% set parameters
%  *******************************

NMR_job = 101;
code = hex2dec('0901'); 

for ii=1:1
    
    myNMR.write_1register(NMR_job,code);
    pause(0.1)
    x=myNMR.readparams()';
    disp([num2str(ii,'%02d')  ':' num2str(x(end),'%x')])
    pause(.1)
end

%%

x = myNMR.readstatus();
pause(1)
    y = myNMR.read_NMR_data(20);
    nmrplot(y)
