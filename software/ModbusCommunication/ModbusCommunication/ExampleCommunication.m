% ExampleCommunication.m  m-file for demonstrating how to use modbus
% interface functions.  Enclosed are the m-files necesary for communication
% over an RS-232 line with a PLC in ASCII mode.  Specifically this code was developed for
% an eaton ELC-PLC controller, however I used the modbus communication 
% standards that can be found at: http://www.modbus.org/specs.php
% Four modes are supported in this code, communication modes 2,3,15 and 16
% allowing for the sending and receiving of both binary (1/0 coils) and
% register (positive integer) data.  Note that although the modbus protocol
% language should work with all PLC devices I only have the Eaton device to
% test on. 
%
% Files included are:
%
% serialstart.m - initiate and set up serial object
% LRC.m - perform longitudinal redundency check operation
% moderr.m - Function for displaying modbus error codes
% modbus2.m - read 40 binary values (coils) from PLC
% modbus3.m - read 16 positive integers (registers) from device
% modbus15.m - write 40 binary values (coils) to PLC
% modbus16.m - write 16 positive integers (registers) to device
%
%
% Serial setup:  serialstart.m initiates the serial port object and passes
% it on to the modbus interfaces.  It is important to set up the operating
% parameters within serialstart to match those specified in the ladder
% logic of your PLC and PLC manual.  An image of the ladder logic used for
% setting the communication parameters on the Eaton device is included
%
%  Adresses:  PLC's often have their own internal means of addressing
%  memory divided by the type of memory.  for example in an Eaton ELC-PLC
%  some of their 1/0 coils are labeled M0-M1535, however their hex address
%  is '0800'-'0DFF'.  From the standpoint of modbus communications it is
%  important to look up the memory adressing table of your PLC.  NOTE:  due
%  to the way in which memory is referenced the address in Hex and the
%  modbus address may be off by 1.  Go with the Hex address given and
%  double check that the proper address is being referenced using your
%  PLC's computer link.
%
% Please note that this code was developed for a specific
% communication application and this is a version that I have modified to
% allow more user changes such as specifying the address instead of having
% a fixed address. As such, this code is limited in some ways.  Within my
% implementation I have the modbus communication functions in a loop to
% continually update.  Note that there are a number of pause commands in
% the code, these could be shortened or removed, however I found in
% experimenting that with the serial port it was sometimes best to give it
% extra time.  I have also found the java based implementation of the
% serial object in matlab to sometimes stop functioning properly until
% matlab is closed and re-started.



clear
close all

% remove any remaining serial objects to prevent serial issues
g = instrfind; 
if ~isempty(g);
   fclose(g);
   delete(g)
   clear g
end

% Initialize Serial Port Object [s]
[s] = serialstart();

% Designate the PLC number to be addressed, if there is 
%  only one PLC then generally it is 01
device = '01';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Write and read binary data (coils)

% Write coils (1/0) to PLC
% modbus15.m writes 40 consecutive coils

address = '0800';  % address in Hex
% NOTE:  Often memory within a PLC is addressed starting at 0, 
%   so there may be an offset between the number address and 
%   Actual memory number referenced.  Use Hex

% generate array to send 1x40
Mout = [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,...
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0];


[Mout, err] = modbus15(s,device,address,Mout)


% Read Coils from PLC (Modbus Mode 2)
% modbus2.m reads 40 consecutive coils

address = '0800';  % address in Hex


[Min, err] = modbus2(s,device,address)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Write and read registers (integer values)

% Write registers (words) to PLC
% modbus16.m writes 16 consecutive integers

address = '1000';  % address in Hex

% Generate data to send 1x16
Dout = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];

[Dout, err] = modbus16(s,device,address,Dout)


% Read Words/registers from PLC (Modbus Mode 3)
% modbus3.m reads 16 consecutive words

address = '1000';  % address in Hex

[Din, err] = modbus3(s,device,address)






