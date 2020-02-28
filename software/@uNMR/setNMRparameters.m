function [res] = setNMRparameters(obj,index,invalue)
% Set the NMR parameters via status_register
% index : 16 bits, index to the NMR parameter record
% value : 32 bits, value for the parameter
% total 3 registers

    status_register = 103;     % same as the status register
    value = floor(invalue);
    
    v1 = floor(value / 2^16);
    v2 = mod(value, 2^16);

    obj.write_registers(status_register,[index,v1, v2]);

   
	res = [index,v1, v2];
end


% enum p_index {
% 	i_asci_ver = 1,
% 	i_tuningcap,
% 	i_recgain,
% 	i_na,
% 	i_ds,
% 	i_dwell,
% 	i_T90,
% 	i_T180,
% 	i_TE,
% 	i_TD,
% 	i_freq
% };