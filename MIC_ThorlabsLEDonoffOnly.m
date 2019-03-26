classdef MIC_ThorlabsLEDonoffOnly < MIC_LightSource_Abstract
    % MIC_ThorlabsLED Matlab Instrument Class to turn on/off the Thorlabs
    % LED. The brightness is controlled locally by knob on the LEDD1B led
    % driver unit.
    %  
    % Requires a digital Output channel of NI card to turn the LED ON/OFF.
    % BNC cable is needed to connect to device.
    % Set switch on LEDD1B to 'TRIG'.
    %   
    % Example: obj=MIC_ThorlabsLEDonoffOnly('Dev1','Port0/Line8');
    % Functions: on, off, delete, shutdown, exportState 
    %
    % REQUIREMENTS: 
    %   MIC_Abstract.m
    %   MIC_LightSource_Abstract.m
    %   MATLAB software version R2016b or later
    %   Data Acquisition Toolbox
    %   MATLAB NI-DAQmx driver installed via the Support Package Installer
    %
    % CITATION: Mohamadreza Fazel and Hanieh Mazloom-Farsibaf Lidkelab, 2017.
    
   
   properties (SetAccess=protected)
        InstrumentName='MIC_ThorlabsLEDonoffOnly' % Descriptive Instrument Name
        Power=100;            % Currently Set Output Power is not used, real LED intensity is set manually on LED driver.
        PowerUnit='Percent' % Power Unit 
        MinPower=0;         % Minimum Power Setting, is also not used.
        MaxPower=100;       % Maximum Power Setting, is also not used.
        IsOn=0;             % On or Off State.  0,1 for off,on
        LampWait=0.2;         % Wait time in the on function
   end
    
    properties (SetAccess=protected)      
        DAQ_DC=[];  % NI DAQ Session for Digital channel
    end
    
    properties 
        StartGUI;
    end
    
    methods
        function obj=MIC_ThorlabsLEDonoffOnly(NIDevice,DOChannel)
            % Creates a MIC_ThorlabsLEDonoffOnly object and turns off LED. 
            % Example: RS=MIC_ThorlabsLEDonoffOnly('Dev1','Port0/Line8');
            obj=obj@MIC_LightSource_Abstract(~nargout);
            if nargin<2
                error('MIC_ThorlabsLEDonoffOnly::NIDevice,DOChannel must be defined.')
            end
            %Set up the NI Daq Object
            %to turn off/on 
            obj.DAQ_DC = daq.createSession('ni');
            addDigitalChannel(obj.DAQ_DC,NIDevice,DOChannel, 'OutputOnly');

            %Set to minimum power
            outputSingleScan(obj.DAQ_DC,[0]);
            fprintf('LED power is controlled locally, by hand, on Thorlabs LED driver.\n');
        end
        function delete(obj)
            % Destructor
            delete(obj.GuiFigure);
            obj.shutdown();
        end
        function setPower(obj,Power_in)
            % Sets output power in percentage of maximum >> is not used but is necessary to fullfill requirements for Lightsource abstract.
            obj.Power=max(obj.MinPower,Power_in);
            obj.Power=min(obj.MaxPower,obj.Power);
            %fprintf('LED power is controlled locally, by hand, on Thorlabs LED driver.\n');
            obj.updateGui;
        end
        function on(obj)
            % Turn on LED to currently set power. 
            obj.IsOn=1;
            outputSingleScan(obj.DAQ_DC,[1]);
            pause(obj.LampWait);
            obj.updateGui;
        end
        function off(obj)
            % Turn off LED. 
            outputSingleScan(obj.DAQ_DC,[0]);
            obj.IsOn=0;
            pause(obj.LampWait);
            obj.updateGui;
        end
        function [State, Data,Children]=exportState(obj)
            % Export the object current state
            State.instrumentName=obj.InstrumentName;
            State.IsOn=obj.IsOn;
            State.Power=obj.Power;
            Data=[];
            Children=[];
        end
        function shutdown(obj)
            % Set power to zero and turn off. 
            obj.setPower(0);
            obj.off();
        end
        
    end
        methods (Static=true)
            function unitTest(NIDevice,DOChannel)
                % Unit test of object functionality
                
                try
                   TestObj=MIC_ThorlabsLEDonoffOnly(NIDevice,DOChannel);
                   fprintf('The object was successfully created.\n');
                   on(TestObj); 
                   fprintf('The lamp is turned on.\n');pause(1);
                   off(TestObj);
                   fprintf('The lamp is off.\n');pause(1);
                   delete(TestObj);
                   fprintf('The device is deleted.\n');
                   fprintf('The class is successfully tested :)\n');
               catch E
                   fprintf('Sorry, an error occured :(\n');
                   error(E.message);
               end
            end
            
        end
    
end

