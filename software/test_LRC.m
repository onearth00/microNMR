% test LRC and CRC

% LRC
device = 1;
sendstring = [ device, 3,0,2,0,1,37,202];

%try the string
device='01';
sendstring = [':', device, '03', '00', '02', '01'];

[r,ss]=LRC(sendstring,2)

