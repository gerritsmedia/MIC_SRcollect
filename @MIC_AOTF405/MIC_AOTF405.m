classdef MIC_AOTF405 < MIC_LightSource_Abstract
   
    % MIC_AOTF405: Matlab Instrument Class for attenuation 
    % control of the Coherent OPSL MX series laser Genesis639.
    % Controls laser power, setting power within the range of 0 to
    % 100% (measured on 4/11/2018 US date stamp). The power modulation 
    % is done by providing input analog voltage to the laser controller 
    % from a NI card (range 0 to 10V).
    % Needs input of NI Device and AO Channel.
    %
    % Example: obj=MIC_AOTF405('Dev2','ao0','Port0/Line0');
    % Functions: on, off, State, setPower, delete, shutdown, exportState
    %
    % REQUIREMENTS: 
    %   MIC_Abstract.m
    %   MIC_LightSource_Abstract.m
    %   MATLAB software version R2016b or later
    %   Data Acquisition Toolbox
    %   MATLAB NI-DAQmx driver installed via the Support Package Installer
    %
    % CITATION: Sandeep Pallikkuth, Lidkelab, 2017; 
    % Code modified by Gert-Jan Bakker, Microscopy Imaging Center, 
    % Radboud University Medical Center, The Netherlands, 2018.
    %
    %  2018-8-9 >>>> Adapt for 405 laser, recalibrate V,P! >>> 2018-9-11 done!
    
    properties(SetAccess = protected)
        InstrumentName='AOTF405'; %Instrument Name
    end
    properties (SetAccess=protected)
        MinPower=0; % Minimum Power of laser
        MaxPower=100; % Maximum power of laser
        PowerUnit='%'; % Laser power units
        IsOn=0; % ON/OFF state of laser (1/0)
        Power=0; % Current power of laser
    end
    
    properties(Hidden)
        NIVolts=0; % NI Analog Voltage modulation AOTF Initialisation
        NIblankingChannel=1; % NI digital out blanking AOTF Initialisation
        DAQ; % NI card session. 
        % Below: voltage (V) and related fraction of the maximum output
        % power (P), for calibration. Interpolation generated using script
        % 'TestLaser.m' in combination with power(V) measurements. 
        V = [0 0.1 0.2 0.3 0.4 0.5 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 8.5 9.0]; %DAQ voltage settings 405
        P = [0.001 0.002 0.003 0.008 0.014 0.020 0.079 0.303 0.651 1.08 1.54 1.96 2.30 2.51 2.58 2.61]; % measured power just before beam expander, 405 at 10mW.
        PP;
        VV;
    end
    
    properties
        StartGUI; % Laser Gui
    end
    
    methods
        function obj=MIC_AOTF405(NIDevice,AOChannel,DOChannel)
            % Set up object
            if nargin<3
                error('NIDevice, AOChannel and DOChannel must be defined')
            end
            obj=obj@MIC_LightSource_Abstract(~nargout);
            obj.DAQ = daq.createSession('ni'); %Set up the NI Daq object. It is possible to start independent sessions, e.g. to separate attenuation and blanking of all channels. 
            addAnalogOutputChannel(obj.DAQ,NIDevice,AOChannel, 'Voltage'); % Adding analog channel for power control
            addDigitalChannel(obj.DAQ,NIDevice,DOChannel,'OutputOnly'); % Add digital channel to turn on the blanking input, otherwise there will be no transmission.
            obj.Power=obj.MinPower; % sets laser power to min_Power
            obj.off; % NEW
            DS1='This Laser provides software control over the relative power (% of maximum) in the sample plane. Use calibration for absolute values';
            disp(DS1);
            % Generate Power-Voltage curve by interpolation;
            Pnorm = 100*(obj.P./obj.P(16));
            obj.PP = 0:.1:100;
            obj.VV = spline(Pnorm,obj.V,obj.PP);        % interpolation function to estimate voltage settings to obtain powers in between the measured values.
            obj.VV(obj.VV<0)=0;                     % remove negative voltages!
            %plot(Pnorm,obj.V,'o',obj.PP,obj.VV)
        end
        
        function on(obj)
            % Turns on Laser. 
            outputSingleScan(obj.DAQ,[obj.NIVolts obj.NIblankingChannel]);
            obj.IsOn=1; % Sets laser state to 1, just a flag.
            %obj.setPower(obj.Power); % Sets laser power to the last set power value. After off(obj) this will be 0.
        end
       
        function off(obj)
            % Turns off Laser. 
            % obj.setPower(0);   % Sets power to 0
            outputSingleScan(obj.DAQ,[0 obj.NIblankingChannel]);
            obj.IsOn=0;   % Sets laser state to 0, just a flag.
        end

        function delete(obj)
            % Destructor
            obj.shutdown();
            clear obj.DAQ;
            delete(obj);
        end

        function shutdown(obj)
            % Shuts down obj
            obj.setPower(0);
            obj.off();
        end
        
        function [Attributes,Data,Children]=exportState(obj)     
            % Export current state of the Laser
            Attributes.IsOn=obj.IsOn;
            Attributes.Power=obj.Power;
            Data = [];
            Children = [];
        end
        
        function setPower(obj,Power_in)
            % Sets power for the Laser. Example: set.Power(obj,Power_in)
            % Power_in range : 0 - 100%. 
            obj.Power=max(obj.MinPower,Power_in); % Makes sure the input power is greater than min_Power
            obj.Power=min(obj.MaxPower,obj.Power); % Makes sure the input power is smaller than max_power
          
            f=round(obj.Power,1);
            i= abs(obj.PP-f)<0.05;  % Steps are 0.1%, it will find the step closest
            obj.NIVolts = obj.VV(i); % calculates voltage corresponding to Power_in
            if obj.IsOn==1
                outputSingleScan(obj.DAQ,[obj.NIVolts obj.NIblankingChannel]); % sets voltage and blanking =1 at NI card for Power_in
            end
        end
    end
            methods (Static=true)
            function unitTest(NIDevice,AOChannel,DOChannel)
                % unit test of object functionality
                % Example:
                % MIC_CoherentObis.unitTest('Dev1','ao2','Port0/Line4');
                fprintf('Creating Object\n')
                DL=MIC_CoherentAOTF405(NIDevice,AOChannel,DOChannel);
                fprintf('Setting to Max Output\n')
                DL.setPower(100); pause(5);
                fprintf('Turn On\n')
                DL.on();pause(5);
                fprintf('Turn Off\n')
                DL.off();pause(5);
                fprintf('Turn On\n')
                DL.on();pause(5);
                fprintf('Setting to 50 Percent Output\n')
                DL.setPower(50); pause(5);
                fprintf('Exporting state of laser\n')
                Abc=DL.exportState();disp(Abc);pause(3);clear Abc;
                fprintf('Delete Object\n')
                delete(DL);
                fprintf('Test for delete, try turning on the laser\n')
                try
                    CL.on();
                catch E
                    error(E.message);
                end
                
            end
            
        end
 
end
