classdef MIC_SRcollect < MIC_Abstract
% MIC_SRcollect SuperResolution data collection software.
% Works with Matlab Instrument Control (MIC) classes 
%
%  usage: SRC=MIC_TIRF_SRcollect();
%
% REQUIRES:
%   Matlab 2014b or higher
%   MIC_Abstract
%   MIC_LightSource_Abstract
%   MIC_Camera 			% Please update the correct camera class
%   MIC_Laser			% Please update the correct laser class
%   MIC_ThorlabsLEDonoffOnly
%   MIC_PIPiezo			
%
% CITATION: Sandeep Pallikuth, LidkeLab, 2018


    properties
        % Hardware objects
        CameraObj;      % Hamamatsu Camera
        StageObj;       % PI Piezo
        LaserObj;       % Laser Class
        LampObj;        % Thorlabs LED
        
        % Camera params
        ExpTime_Focus_Set=.01;          % Exposure time during focus
        ExpTime_Sequence_Set=.01;       % Exposure time during sequence
        ExpTime_Sequence_Actual=.02;
        ExpTime_Capture=.05;
        NumFrames=20;                 % Number of frames per sequence
        NumSequences=20;                % Number of sequences per acquisition
        CameraGain=1;                   % Flag for adjusting camera Gain
        CameraROI=1;                    % Camera ROI (see gui for specifics)
        PixelSize;                       % Pixel size determined from calibration
        
        % Light source params
        LaserLow;    % Low power  laser
        LaserHigh;   % High power  laser
        LaserAq;     % Flag for using 405 laser during acquisition
        LampAq;         % Flag for using lamp during acquisition
        LampWait=0.5;   % Lamp wait time
        focusLaserFlag=0;       % Flag for using laser during focus
        focusLampFlag=0;  % Flag for using Lamp during focus
        
        % Other things
        SaveDir='E:\';  % Save Directory, please update the default save directory
        BaseFileName='Cell1';   % Base File Name, please update the default value
        AbortNow=0;     % Flag for aborting acquisition
        SaveFileType='mat'  %Save to *.mat or *.h5.  Options are 'mat' or 'h5'
    end
    
    properties (SetAccess = protected)
        InstrumentName = 'Microscope_SRcollect'; % Descriptive name of "instrument"
    end
    
    properties (Hidden)
        StartGUI=false;       %Defines GUI start mode.  Set to false to prevent gui opening before hardware is initialized.
    end
    
    methods
        function obj=MIC_SRcollect()
            % MIC_SRcollect constructor
            %   Constructs object and initializes all hardware
            
            % Enable autonaming feature of MIC_Abstract
            obj = obj@MIC_Abstract(~nargout);
            % Get calibrated pixel size
%             [p,~]=fileparts(which('MIC_SRcollect'));
%             pix = load(fullfile(p,'PixelSize.mat'));  % please make sure the pixel data is avaialable
%             obj.PixelSizeX = pix.PixelSizeX;
%             obj.PixelSizeY = pix.PixelSizeY;
            
            
            % Initialize hardware objects
            try
                % Camera
                fprintf('Initializing Camera\n')
                obj.CameraObj=MIC_HamamatsuCamera(); 	% please update the correct class name
                obj.CameraObj.ReturnType='matlab';
                % Stage
                fprintf('Initializing Stage\n')
                obj.StageObj=MIC_PIPiezo();		
                obj.StageObj.gui;
                % Laser
                fprintf('Initializing laser\n')
                obj.LaserObj =MIC_CoherentGenesis639('Dev1','ao2','Port0/Line4');		
                obj.LaserLow = 0;			% please update the default value
                obj.LaserHigh = 100;			% please update the default value
                % Lamp
                fprintf('Initializing lamp\n')
                obj.LampObj=MIC_ThorlabsLEDonoffOnly('Dev1','Port0/Line8');
           catch ME
               ME
                error('hardware startup error');
                
            end
            
            %Set save directory
            user_name = java.lang.System.getProperty('user.name');
            timenow=clock;
            obj.SaveDir=sprintf('E:\\%s%s%02.2g-%02.2g-%02.2g\\',user_name,filesep,timenow(1)-2000,timenow(2),timenow(3));
            
            % Start gui (not using StartGUI property because GUI shouldn't
            % be started before hardware initialization)
            obj.gui();
        end
        
        function delete(obj)
            %delete all objects
            delete(obj.GuiFigure);
            close all force;
            clear;
        end
        
              
        function focusLow(obj)
            % Focus function using the low laser settings
    %        Lasers set up to 'low' power setting
             obj.LampObj.off;
             obj.LaserObj.setPower(obj.LaserLow);
             obj.LaserObj.on;
            % Aquiring and diplaying images
            obj.CameraObj.ROI=obj.getROI();
            obj.CameraObj.ExpTime_Focus=obj.ExpTime_Focus_Set;
            obj.CameraObj.start_focus();
            % Turning laser/lamp off
            obj.LaserObj.off;
        end

        function focusHigh(obj)
            % Focus function using the high laser settings
    %        Laser set up to 'high' power setting
            obj.LampObj.off;
            obj.LaserObj.setPower(obj.LaserHigh);
            obj.LaserObj.on;
            % Aquiring and displaying images
            obj.CameraObj.ROI=obj.getROI();
            obj.CameraObj.ExpTime_Focus=obj.ExpTime_Focus_Set;
            obj.CameraObj.start_focus();
            % Turning laser/lamp off
            obj.LaserObj.off;
        end
             
        function focusLamp(obj)
            % Continuous display of image with lamp on. Useful for focusing of
            % the microscope.
            obj.LampObj.on;
            obj.CameraObj.ROI=obj.getROI();
            obj.CameraObj.ExpTime_Focus=obj.ExpTime_Focus_Set;
            obj.CameraObj.start_focus();
            obj.LampObj.off;
        end
        
        function StartSequence(obj,guihandles)
            
            %create save folder and filenames
            if ~exist(obj.SaveDir,'dir');mkdir(obj.SaveDir);end
            timenow=clock;
            s=['-' num2str(timenow(1)) '-' num2str(timenow(2))  '-' num2str(timenow(3)) '-' num2str(timenow(4)) '-' num2str(timenow(5)) '-' num2str(round(timenow(6)))];
                                 
           switch obj.SaveFileType
               case 'mat'
               case 'h5'
                   FileH5=fullfile(obj.SaveDir,[obj.BaseFileName s '.h5']);
                   MIC_H5.createFile(FileH5);
                   MIC_H5.createGroup(FileH5,'Channel01');
                   MIC_H5.createGroup(FileH5,'Channel01/Zposition001');
               otherwise
                   error('StartSequence:: unknown file save type')
           end
           
            %loop over sequences
            for nn=1:obj.NumSequences
                if obj.AbortNow; obj.AbortNow=0; break; end
                
                nstring=strcat('Acquiring','...',num2str(nn),'/',num2str(obj.NumSequences));
                set(guihandles.Button_ControlStart, 'String',nstring,'Enable','off');
                               
                %Setup laser for aquisition
                    obj.LaserObj.setPower(obj.LaserHigh);
                    obj.LaserObj.on;
                    
                %Setup Camera
                obj.CameraObj.ExpTime_Sequence=obj.ExpTime_Sequence_Set;
                obj.CameraObj.SequenceLength=obj.NumFrames;
                obj.CameraObj.ROI=obj.getROI();
                
                %Collect
                sequence=obj.CameraObj.start_sequence(); 
                
                %Turn off Laser
                obj.LaserObj.off;
                obj.LampObj.off;
                
                %Save
                switch obj.SaveFileType
                    case 'mat'
                        fn=fullfile(obj.SaveDir,[obj.BaseFileName '#' num2str(nn,'%04d') s]);
                        Params=exportState(obj); %#ok<NASGU>
                        save(fn,'sequence','Params');
                    case 'h5' %This will become default
                        S=sprintf('Data%04d',nn);
                        MIC_H5.writeAsync_uint16(FileH5,'Channel01/Zposition001',S,sequence);
                    otherwise
                        error('StartSequence:: unknown SaveFileType')
                end
            end
            
            switch obj.SaveFileType
                case 'mat'
                    %Nothing to do
                case 'h5' %This will become default
                    S='Channel01/Zposition001'; 
                    MIC_H5.createGroup(FileH5,S);
                    obj.save2hdf5(FileH5,S);  %Working
                otherwise
                    error('StartSequence:: unknown SaveFileType')
            end
  
        end
        
        function ROI=getROI(obj)
            % these could be set from camera size;
            switch obj.CameraROI
                case 1
                    ROI=[1 2048 1 2048]; %full
                case 2
                    ROI=[875 1174 875 1174];% center300
                otherwise
                    error('SRcollect: ROI not found')
            end
        end
        
        function [Attributes,Data,Children] = exportState(obj)
            % exportState Exports current state of all hardware objects
            % and SRcollect settings
            
            % Children
            [Children.Camera.Attributes,Children.Camera.Data,Children.Camera.Children]=...
                obj.CameraObj.exportState();
            
            [Children.Stage.Attributes,Children.Stage.Data,Children.Stage.Children]=...
                obj.StageObj.exportState();
            
            [Children.Laser.Attributes,Children.Laser.Data,Children.Laser.Children]=...
                obj.LaserObj.exportState();
                      
            [Children.Lamp.Attributes,Children.Lamp.Data,Children.Lamp.Children]=...
                obj.LampObj.exportState();            
            
            % Our Properties
            Attributes.ExpTime_Focus_Set = obj.ExpTime_Focus_Set;
            Attributes.ExpTime_Sequence_Set = obj.ExpTime_Sequence_Set;
            Attributes.NumFrames = obj.NumFrames;
            Attributes.NumSequences = obj.NumSequences;
            Attributes.CameraROI = obj.getROI;
            Attributes.CameraPixelSize=obj.PixelSize;
            
            
            Attributes.SaveDir = obj.SaveDir;
            
            % light source properties
            Attributes.LaserLow = obj.LaserLow;
            Attributes.LaserHigh = obj.LaserHigh;
            Attributes.LampPower = obj.LampPower;
            Data=[];
        end
    end
    
    methods (Static)
        
        function State = unitTest()
            State = obj.exportState();
        end
        
    end
end


