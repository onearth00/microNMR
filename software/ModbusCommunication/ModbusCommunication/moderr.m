function errback = moderr(out,mode)
% errback = moderr(out,mode)
% Function for displaying error messages related to incorrect reply of a
% Eaton PLC modbus controller, this may vary by brand
% out is the string of hex numbers returned by the PLC, mode is the
% operation mode calling moderr
% errback is yet undefined
%
% used in modbus2.m, modbus3.m, modbus15.m, modbus16.m

if length(out) >= 7  
    funct = out(4:5);
    errnum = hex2dec(out(6:7));
else
    funct = '';
    errnum = 0;
end
disp('----------------------------------------------------------')
disp(datestr(now))
disp('Error in Modbus return signal')
disp(['In modbus communication mode ',num2str(mode)])
disp(['Error function code is: ',funct])
disp(['Exception code: ',num2str(errnum)])


if errnum == 0
    disp('String too short to obtian exception code')
elseif errnum == 1
    disp('01 Illegal command code: The command code received in the')
    disp('command message is not available for the ELC.')
elseif errnum == 2
    disp('02 Illegal device address: The device address received in ')
    disp('the command message is not available for the ELC.')
elseif errnum == 3
    disp('03 Illegal device value: The device value received in the ')
    disp('command message is not available for the ELC.')
elseif errnum == 7
    disp('07 Check Sum Error Check if the check Sum is correct Illegal')
    disp('command messages The command message is too short. Command ')
    disp('message length is out of range.')
else
    disp('Unknown Exception Code:')
end

disp(['Return signal is:  ',out])

pause(.5)
errback = 0;

