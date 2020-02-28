function set_tuning_bias(obj,value)
% serial connection to uNMR pcb
% set the tuning bias voltage of the tuning varactors.
% Input range: 0-4096. DAC output 0-2.5 V
%
% YS nov 30, 2016
% YS feb 2017
%
% 


reg_DAC = 3;
theReg = reg_DAC;

    if nargin <=1
        disp 'Tuning DAC set to zero.'
        theValue = 0;
    else
        fprintf(1,'Tuning DAC value %d',value);
        theValue = value;
    end

    obj.write_1register(theReg,theValue);

end

