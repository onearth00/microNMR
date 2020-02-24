function [res]=setgain(obj,inGain)
% uNMR.setgain
% Read and set the receiver gain value.
% 
% Usage: setgain() - return the current gain value
% Usage: setgain(v) - set the gain to v and return the value

reg_ASIC_gain=102;
Default_gain = 15;



if nargin ==2
    if (inGain==0) | (inGain > 32)
        x=obj.write_1register(reg_ASIC_gain,Default_gain);
    else
        x=obj.write_1register(reg_ASIC_gain,inGain);
    end
end

    x=obj.read_1register(reg_ASIC_gain);
    
    x= dec2hex(double(x))';
    x=x(:)';
   
    res = hex2dec(x);
end