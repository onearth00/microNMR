%/! SUtsuzawa (4/13/2017)
% function  obj = init_serial(obj)
function  obj = init_serial(obj, varargin)
%!/

% serial connection to uNMR pcb
% Input: none
% Output: s1, used for future serial operation
%
% YS nov 30, 2016 -  
%
% 

%/! SUtsuzawa (4/13/2017)
% if isempty(obj.serial_port)
if isempty(obj.serial_port)
    if  ~isempty(varargin)      % if a portID is given
%!/

%     obj.serial_port = serial('/dev/cu.usbserial-FTYTWHRQ');    % Yiqiao's USB dongle
    %obj.serial_port = serial('/dev/cu.usbserial-FTZ6DV8U');  % DM's usb dongle
    % port name is specific to the USB dongle
    
%/! SUtsuzawa (4/13/2017)
%     obj.serial_port = serial('com5');
    portID = varargin{1};
    obj.serial_port = serial(portID);
%!/
    else
        % no portID
        myport = getserialport();
        obj.serial_port = serial(myport); % 
    end
end

% currently used for uNMR serial port

% CRC, for RTU mode, 8 bit data, binary
% input is not a string, but a decimal numbers
% also no ':'


obj.device = 1;

% ASCII mode
% device = '01';
%sendstring = [':',device, '03', '00', '07','00', '01'];


    if ~isempty(obj.serial_port)
        set(obj.serial_port,'BaudRate',57600,'DataBits',8,'parity','even'); % work on Yiqiao's macpro up to 115200
        %set(obj.serial_port,'BaudRate',128000,'DataBits',8,'parity','even');
        %% changed to 128000 on Oct 1, 2017. Does not work for Yiqiao's macpro
        
        set(obj.serial_port,'timeout',1);
        % Specify Terminator
        obj.serial_port.terminator='';

        obj.serial_port;

        if obj.serial_port.Status(1:4) == 'clos'
            fopen(obj.serial_port);
            if obj.serial_port.Status(1:4) == 'clos'
                disp 'Serial port not open'
            end
        end
    else
        %uNNR_serial
        fprintf(1, 'Serial device found (%s)\r',obj.serial_port.port);
    end

end


function [portname] = getserialport()

    
        x = seriallist;
    for ii=1:length(x)
        fprintf ('%d: %s\n', ii,x(ii))
    end
    fprintf ('\n')
    
    s = input('Select a port by its number=')
    portname = x(s);
end

