function [res] = read_temp2(obj)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
% YT apr 4, 2017 - change from dec2hex to dec2bin, and define the # of
% digits
% 

disp 'onboard temp sensor'

%    reg_incr = 2;
    reg_temp = 7;
  
    outstring = obj.read_register(reg_temp,1,7);

%    res = 0.03125*double(outstring)'
    x= dec2hex(single(outstring),2)'
    x=x(:)'
    res = hex2dec(x)*0.03125  ; 
    
end