%/! SUtsuzawa (4/13/2017)
% classdef uNMR
classdef uNMR < handle
%!/
    properties   (Access= public)
        Pulses;
        pseq;   % pulse seq, 64 pulses
        Delays;
        PS;
        serial_port;
        device;
    end
   
	methods  (Access= public)
        %/! SUtsuzawa (4/13/2017)
%          function obj = uNMR(obj)         % constructor
       function obj = uNMR( portID )         % constructor
        %!/
            obj.Pulses = zeros(10,1);
            obj.Delays = zeros(10,1);
            obj.PS = char(zeros(4,64));    % pulse seq, 64 bit by 64
            obj.device = 1;                % RTU mode, device is a decimal number, in ASCII, device='01'

            % in unit of us
            obj.Delays = zeros(10,1);
            obj.Delays(1) = 1000000;
            obj.Delays(2) = 1000;

            obj.Pulses = zeros (10,1);
            obj.Pulses(1) = 10;
            obj.Pulses(2) = 20;
            
            obj.pseq = makeseq(obj);

            try
                obj = init_serial(obj, portID);
%                 obj = init_serial(obj);
            catch 
                disp  ' ------------------- '
                disp 'Serial port not initialized properly.'
                disp ' ------------------- '
            end
        end %uNMR()/
        

      
        function delete(obj)  % destructor, close the port if open
            %/! SUtsuzawa (4/13/2017)
%             if ~isempty(obj.serial_port) & (obj.serial_port.Status(1) == 'o')
            if ~isempty(obj.serial_port) && strcmpi(obj.serial_port.Status, 'open')
            %!/
                fclose(obj.serial_port);
            end
        end
      
        function close_serial(obj)  % destructor, close the port if open
            %/! SUtsuzawa (4/13/2017)
%             if ~isempty(obj.serial_port) & (obj.serial_port.Status(1) == 'o')
            if ~isempty(obj.serial_port) && strcmpi(obj.serial_port.Status, 'open')
            %!/
                fclose(obj.serial_port);
            end
        end

        function help(obj)
            %/! SUtsuzawa (4/13/2017)
%{
            disp 'List of functions:'
            disp 'set_device' 
            disp 'init_serial'
            disp 'read_temp'

            disp 'set_freq_PLL'
            disp 'set_tuning'
            disp 'run_NMR'
            disp 'read_NMRdata'
%}
            methods(obj)
        end
      
      
        function obj=set_device(obj,dev_num)
            if (dev_num > 0) && (dev_num < 255)
                obj.device = floor(dev_num);
            else
                fprintf(1,'Device number is incorrect, %d\r', dev_num);
            end
        end

        function test(obj)
            for ii=1:2
                fprintf(1,'I am here\r');
                obj.device  =50;
            end
        end
        
        %/- SUtsuzawa (4/13/2017)

        
   function [pseq] = makeseq(obj)
       pseq = zeros(64,2);
   end           
   
   function [pulse]= PlsGen(obj, width, 	...	 // RF pulse width, 24 bits, in US
        space, ...      					%// period after the RF pulse, 24 bits, in US
        amp,   ...      					%// amplitude of the RF pulse, 0-31
        phase,  ...     					%// phase of the RF pulse, 0-31
        acq,   ...      					%// turn on acq flag during the space period
        q,     ...      					%// turn on the reverse phase segment after the RF pulse, how long ?
        ls, le) ... 					%// loop start (ls) and loop end (le), to indicate the loop structure

        % TI clock is 15 MHz, thus 15 ticks per microsecond
        US_NMR = 15;
        % pulse is a 64 bit record
        % pls.dword[0] = pls.dword[1] = 0;

        %     // bit structure
        %     // dword[1]                         dword[0]
        %     // | width(24) | amp(5) | phase(5) | space(24) | q(3) | acq(1) | ls(1) | le(1) |
        %     //  31        8 7      3 2  0 31 30 29        6 5    3 2      2 1     1 0     0
        %    pls.dword[0]   |= (((space*US_NMR)&0xffffff) << 6) | (le&0x1) | ((ls&0x1) << 1) | ((acq&0x1) << 2) | ((q&0x7) << 3) | ((phase&0x03) << 30);

        %    pls.dword[1] 	= (((width*US_NMR)&0xffffff) << 8) | ((amp&0x1f) << 3) | ((phase&0x1c) >> 2);

        uint64 pulse;

        pulse1 = bitshift(space*US_NMR, 6, 'uint32');
        pulse1 = bitor(pulse1, bitand(le,1));
        pulse1 = bitor(pulse1, bitshift(bitand(ls,1),1) );
        pulse1 = bitor(pulse1, bitshift(bitand(acq,1),2) );
        pulse1 = bitor(pulse1, bitshift(bitand(q,3),3) );
        pulse1 = bitor(pulse1, bitshift(bitand(phase,3),30) );

        % second chunk
        pulse2 = bitshift(width*US_NMR, 8, 'uint32');
        pulse2 = bitor(pulse2, bitshift(bitand(amp,hex2dec('1f')),3) );
        pulse2 = bitor(pulse2, bitshift(bitand(phase,hex2dec('1c')),-2) );

%        dec2hex(bitor(bitshift(pulse1,32), pulse2))
        pulse = [pulse1, pulse2];
        
        obj.showPulse(pulse);
   end
   
   function [pulse] = PlsGenAddLoop(obj, pulse,  ls, le) % // loop start (ls) and loop end (le), to indicate the loop structure
    %thePls->dword[0] |=(le&0x1) | ((ls&0x1) << 1);
        pulse(1) = bitor(pulse(1), bitand(le,1));
        pulse(1) = bitor(pulse(1), bitshift(bitand(ls,1),1));
   end
   
   function pulse = PlsGenDelay(obj,delay)
       pulse = obj.PlsGen(0,delay,0,0,0,0,0,0);
   end
   
   function pulse = PlsGenPulse(obj,PulseWidth,  ampl,  phase,  q)
        acqDelay = 0;
        pulse = obj.PlsGen(PulseWidth,acqDelay,ampl,phase,0,q,0,0);
   end
   
   function pulse = PlsGenACQ(obj, dwell,  TD)
        PulseWidth = 0;
        PulseAmpl = 0;
        PulsePhase = 0;
        q = 0;
        AcqFlag = 1;
        Period = dwell*TD;

        pulse = obj.PlsGen(PulseWidth,Period,PulseAmpl,PulsePhase,AcqFlag,q,0,0);
   end

   function showPulse (obj,pulse)
       y = dec2bin(pulse,32);
       
       ylabel = '01234567890123456789012345678901';
       
       disp([y;ylabel])
   end
% 
% SglPls PlsGenDelay(Uint32 delay)
% {
%     return PlsGen(0,delay,0,0,0,0,0,0);
% }
% 
% SglPls PlsGenPulse(Uint32 PulseWidth, Uint32 ampl, Uint32 phase, Uint32 q)
% {
%     Uint32 acqDelay = 0; //US
% 
%     return PlsGen(PulseWidth,acqDelay,ampl,phase,0,q,0,0);
% }
% 
% SglPls PlsGenACQ(Uint32 dwell, Uint32 TD)
% {
%     Uint32 PulseWidth = 0;
%     Uint32 PulseAmpl = 0;
%     Uint32 PulsePhase = 0;
%     Uint32 q = 0;
%     Uint32 AcqFlag = 1;
%     Uint32 Period = dwell*TD;
% 
%     return PlsGen(PulseWidth,Period,PulseAmpl,PulsePhase,AcqFlag,q,0,0);
% }


      
   end % end of methods
   
%    events (Attributes) 
%       EventName
%    end
%    enumeration
%       EnumName
%    end
end