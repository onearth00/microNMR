function [data_temp] = read_temp_24bit(obj)
% serial connection to uNMR pcb
% YS nov 30, 2016 -- 
% YT apr 4, 2017 - change from dec2hex to dec2bin, and define the # of
% digits
% YT sep 29 2017 - modify the code to pull temperature readings from the 24-bit temp
% sensor
%

disp 'offboard temp sensor'


   reg_temp = 8;
  
   outstring = obj.read_register(reg_temp,2,9); %two words

 % res = 0.03125*double(outstring)'
% 
%    x= dec2hex(single(outstring),4)'
%    x=x(:)'
   
   y= dec2hex(single(outstring),2)';
   y=y(:)';
    
   res = hex2dec(y);  
   
   R_REF = 1650;                %             # Reference Resistor 
   PGA = 4;                     %            # ADS1248 gain
   Res0 = 100.0;                %             # Resistance at 0 degC
   a = 0.00385;
   b = -0.000000577500;
%   b = 0
   c = -0.00000000000418301;
   % RTD resistance
   Res_RTD = ((res*0.196695e-6)/4)/1e-3
   %print (Res_RTD)  

    temp_C1 = -(a*Res0) + sqrt(a*a*Res0*Res0 - 4*(b*Res0)*(Res0 - Res_RTD));
 
    data_temp =(temp_C1/(2*(b*Res0)));
      
end