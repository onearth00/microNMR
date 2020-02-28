% serial connection to uNMR
% YS nov 30, 2016

%s1= serial('/dev/tty.KeySerial1');
s1 = serial('/dev/tty.usbserial-FTYTWHRQ');
%s1 = serial('/dev/cu.usbserial-FTZ6DV8U');





get (s1);

set(s1,'BaudRate',57600,'DataBits',8,'parity','even');
set(s1,'timeout',2);
%
% Specify Terminator
s1.terminator='';
%% 

fopen(s1);

%%
device = 1;

%
%sendstring = [':',device, '07', '01'];
sendstring = [ device, 3,0,7,0,1,249,94];

% increment a counter. 
% Read back double(outstring)= is     1     3     2     0    10    56    67
sendstring = [ device, 3,0,2,0,1,37,202];


%convert to hex

try 
    fprintf(s1,[sendstring])
    outstring = fscanf(s1)
    pause(1)
catch
    outstring = '';
    disp 'Error. Cannot communicate with serial port.'
end

double(outstring)

%fclose(s1)

