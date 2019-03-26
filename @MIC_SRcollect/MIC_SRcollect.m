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
% CITATION: Sandeep Pallikuth(1) and Gert-Jan Bakker(2) 
% (1)LidkeLab, 2018 
% (2)Microscopy Imaging Center, Radboud University Medical Center, The Netherlands, 2018.

% >>>> TO DO TEMPORARY: 
% > Pop up window to force selection between widefield or TIRF
% microscopy session. Eventually this must be replaced by a light source
% control object with its own gui, to control the laser
% hardware (not the AOTF). Lasers will only emit after
% selection of TIRF or Widefield, with the related maximum mW's.

% >>>> TO DO:
% > Fix initiation error of stage!
% > Fix the issue with the stage adapter, it is in open loop config!
% > Also, abberation correction can be slightly improved by comparing the 
% position setpoint, instead of the measured position. But, there is not 
% such a function as getPositionSetpoint yet.
% > Focus lamp snapshot not possible. Also save option for focus images? 
% > Function to make z-step for every sequence; >>> Done 20-3-2019, use obj.ZstackStatus='on' to initiate the z step mode. obj.Zstep contains the Zstep size in um.
% > The laser is already on before the camera is running; !!! Trigger cable !!! >>> Temporary workaround  with timer works!
% > Reset 405 slider after measurement; >>> Fixed 
% > H5 files are corrupted, no data numbering even when there is only one
% sequence. ?>>> Fixed, also metadata of instrument state properly saved.
% > Test: is 405 actuated when changed during measurement? >>> Yes
% > Focus lamp is blocked when on wrong instrument mode, filter wheel should
%  move. >>> Fixed.
% > Closing focus only works by closing image. If pressing other focus button
% while running another focus instance, the program crashes. 
% > Bug: laser goes only on during first image series. >>> Fixed
% > Steps of the intensity are too big! >>> Fixed, 0.1% steps possible
% Calibration for 405, 488 and 561nm laser attenuation. >>> Done
% > Delay saving H5 files >>> solved, compression can now be adjusted and is
% set to 0 on a scale of 0-5 (no...max).

% Solve H5 warning: 
%Warning: Microscope_SRcollect:: Error writing to HDF5 file
%G:\Data\19-03-20\Test-2019-3-20-9-59-1.h5 
%> In MIC_Abstract/save2hdf5 (line 80)
%  In MIC_SRcollect/StartSequence (line 356)
%  In MIC_SRcollect/gui/Start (line 163) 
%ME = 
%  MException with properties:
%    identifier: 'MATLAB:structRefFromNonStruct'
%       message: 'Struct contents reference from a non-struct array object.'
%         cause: {}
%         stack: [4×1 struct]

% >>>> TO DO later:
% > function ChangeObjective(obj,UsedObjective)
% Apply this function when changing the objective hardware manually.
% Input: UsedObjective string, matching one of the cases
% decribed below. The right objective related parameters from
% above will be saved into the parameters file in the MIC_SRcollect folder
% and these parameters will be loaded during the initialization.
% After execution of this function, MIC_SRcollect must be
% closed and restarted!
% > Correction of the x,y,z position drift between sequences and / or 
% between different color measurements, using image correlation. 


    properties
        % Hardware objects
        CameraObj;      % Hamamatsu Camera
        StageObj;       % PI Piezo
        LaserObj639;       % Laser Class
        LaserObj561;       % Laser Class
        LaserObj488;       % Laser Class
        LaserObj405;       % Laser Class for increase of blinking.
        LampObj;           % Thorlabs LED
        FilterWheelObj;    % Thorlabs FW102C filterwheel with emission filters
        
        % Camera params
        ExpTime_Focus_Set=.05;          % Exposure time during focus
        ExpTime_Sequence_Set=.01;       % Exposure time during sequence
        ExpTime_Sequence_Actual=.02;
        ExpTime_Capture=.05;
        NumFrames=5000;                   % Number of frames per sequence
        NumSequences=10;                % Number of sequences per acquisition
        CameraGain=1;                   % Flag for adjusting camera Gain
        CameraROI=1;                    % Camera ROI (see gui for specifics)
        
        % Objective related parameters
        % I could build a function to select the used objective. Upon
        % selection of an objective, a .mat file is (over)written in the
        % SR_Collect folder, containing the settings of the parameters
        % related to that objective. This file will stay and even if
        % SR_Collectr is restarted, the right settings are being selected.
        UsedObjective;                  % Name string of the used objective, should match cases in ChangeObjective function.
        PixelSizeO60xTIRF=0.1;
        PixelSizeO60xSiOil=0.1;
        PixelSize;                      % Pixel size determined from parameter file
        ZshiftO60xTIRF561=-0.338;          % These parameters need to be calibrated!
        ZshiftO60xTIRF488=-0.439;
        ZshiftO60xSiOil561=0.5;         % For both objective types, check the z-aberration.
        ZshiftO60xSiOil488=0.7;
        Zshift561=-0.338;                    % If there is a parameter file present, these values will be overwritten by loading the parameter file during initialization of MIC_SRcollect.
        Zshift488=-0.439;                    % But, that still has to be implemented, also for the pixel size. FOR NOW, CALIBRATE THESE VALUES TO CORRECT FOR ABERRATION
        
        
        % Light source params
        LaserObj;           % Object to duplicate one of the three Laser Class excitation lasers above
        LaserLow;           % Low power  laser, assigned later to one of the three excitation lasers below
        LaserHigh;          % High power  laser, assigned later to one of the three excitation lasers below
        LaserLow639;        % Low power  laser
        LaserHigh639;       % High power  laser
        LaserLow561;        % Low power  laser
        LaserHigh561;       % High power  laser
        LaserLow488;        % Low power  laser
        LaserHigh488;       % High power  laser
        LaserMax405;        % Maximum 405nm power to be set with the ruler in the GUI
        LaserFlag405;       % Flag for using 405 laser during acquisition
        LampFlag;           % Flag for using lamp during acquisition
        LampWait=0.5;       % Lamp wait time
        LaserFocusFlag=0;   % Flag for using laser during focus
        LampFocusFlag=0;    % Flag for using Lamp during focus
        TIRFflag=0;         % Flag for using TIRF mode, e.g. to reduce laser power used.
        
        % Other things
        SaveDir='G:\Data';  % Save Directory, please update the default save directory
        BaseFileName='Test';   % Base File Name, please update the default value
        AbortNow=0;     % Flag for aborting acquisition
        SaveFileType='h5'  %Save to *.mat or *.h5.  Options are 'mat' or 'h5'
        InstrMode='639nm';    % Instrument mode selector, default setting after initialization. 
        UsedInstrMode;        % The instrument mode used during the measurement.
        InstalledFilters={'LP655', 'BP565/133', 'BP525/50', 'BP605/52', 'Quad446/523/600/677', ''};
        ZstackStatus='off';     % If Zstack mode is activated by setting Obj.ZstackStatus='on', the stage will increment the height by the obj.Zstep value for every recorded next sequence. 
        Zstep=0.050;               % Zstep value to increment the height of the stage with Obj.Zstep = XX µm for every recorded next sequence. 
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
            
            % Get calibrated pixel size and aberration related to the used
            % objective, from the PixelSize.mat file in the MIC_SRcollect
            % folder, in case the file is present.
%             [p,~]=fileparts(which('MIC_SRcollect'));
%             pix = load(fullfile(p,'PixelSize.mat'));  % please make sure the pixel data is avaialable
%             obj.PixelSize = pix.PixelSize;
%             obj.Zshift561 = pix.Zshift561;
%             obj.Zshift488 = pix.Zshift488;
            
            
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
                fprintf('Initializing lasers\n')
                obj.LaserObj639 =MIC_AOTF639('Dev1','ao2');		% Removed: ,'Port0/Line4' blanking is not necessary and can only be used if the laser class is used for one object at a time.
                obj.LaserLow639 = 0.1;			% please update the default value 
                obj.LaserHigh639 = 100;			% please update the default value
                obj.LaserObj561 =MIC_AOTF561('Dev1','ao3');	% the 639 object is not calibrated for the 561 and 488 laser + AOTF, let's see if it works. If not, copy object, change name and re-calibrate	
                obj.LaserLow561 = 0.1;			% please update the default value
                obj.LaserHigh561 = 100;			% please update the default value
                obj.LaserObj488 =MIC_AOTF488('Dev1','ao1');		
                obj.LaserLow488 = 0.1;			% please update the default value
                obj.LaserHigh488 = 100;			% please update the default value  
                obj.LaserObj405 =MIC_AOTF405('Dev1','ao0','Port0/Line0');	% Re-do for 405nm, likely the calibration curve is different because it is physically a different AOTF. 
                obj.LaserMax405 = 100;           % maximum power (% of the  AOTF range) of the 405nm laser that can be set from the gui.
                % Lamp
                fprintf('Initializing lamp\n')
                obj.LampObj=MIC_ThorlabsLEDonoffOnly('Dev1','Port0/Line8');
                % Filterwheel
                obj.FilterWheelObj=MIC_FilterWheelFW102C(11, obj.InstalledFilters);
           catch ME
               ME
                error('hardware startup error'); 
           end
            
            % Set save directory
            %user_name = java.lang.System.getProperty('user.name'); % Windows login user name to use as directory name.
            timenow=clock;
            obj.SaveDir=sprintf('%s%s%02.2g-%02.2g-%02.2g\\',obj.SaveDir,filesep,timenow(1)-2000,timenow(2),timenow(3));
            
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
        
        function SetInstrumentMode(obj) 
            % Set the instrument mode to the instrument mode shown in the
            % gui or in the default parameters.
            % multiply LaserLow and LaserHigh by microscope setting factor, TIRF=0.5 and WF=1.0? Temporary solution for not having remote control over the laser units yet. 
            fprintf(['The instrument mode selected is ' obj.InstrMode '\n'])
            fprintf(['The instrument mode used previously is ' obj.UsedInstrMode '\n'])
            
            if isempty(obj.UsedInstrMode)             % Initialize parameter UsedInstrMode.
                obj.UsedInstrMode=obj.InstrMode; % before a first measurement has been performed, this parameter must be set equal to InstrMode,  otherwise error.
            end                                  % It must be the sam because there is no previous measurement and thus no aberration in z. 
            
            % determination of the assigned z-aberration offset value during the previous measurement
            switch obj.UsedInstrMode
                case '639nm'
                    previousOffset=0;
                case 'Dual 488nm'                  % these strings can be found in the gui instrument mode drop down menu, cell array with strings
                    previousOffset=obj.Zshift488;
                case 'Triple 488nm'
                    previousOffset=obj.Zshift488;
                case 'Triple 561nm'
                    previousOffset=obj.Zshift561;
                case 'Fast TIRFM quad band'
                    previousOffset=0;               % no z-aberration offset for the TIRF mode, multiple laser lines at the same time.
            end
            
            % Set the laser and filter properties according to the selected instrument mode and determine the assigned z-aberration offset value for the next measurement.
            switch obj.InstrMode                    
                case '639nm'                         
                    obj.LaserObj=obj.LaserObj639;
                    obj.LaserLow=obj.LaserLow639;
                    obj.LaserHigh=obj.LaserHigh639;
                    obj.FilterWheelObj.setFilter(1);
                    nextOffset=0;
                case 'Dual 488nm'
                    obj.LaserObj=obj.LaserObj488;
                    obj.LaserLow=obj.LaserLow488;
                    obj.LaserHigh=obj.LaserHigh488;
                    obj.FilterWheelObj.setFilter(2);
                    nextOffset=obj.Zshift488; 
                case 'Triple 488nm'
                    obj.LaserObj=obj.LaserObj488;
                    obj.LaserLow=obj.LaserLow488;
                    obj.LaserHigh=obj.LaserHigh488;
                    obj.FilterWheelObj.setFilter(3);
                    nextOffset=obj.Zshift488;
                case 'Triple 561nm'
                    obj.LaserObj=obj.LaserObj561;
                    obj.LaserLow=obj.LaserLow561;
                    obj.LaserHigh=obj.LaserHigh561;
                    obj.FilterWheelObj.setFilter(4);
                    nextOffset=obj.Zshift561;
                case 'Fast TIRFM quad band'
                    fprintf('The Fast TIRF microscopy mode is not implemented yet, the 639nm instrument mode will be selected.\n')
                    obj.LaserObj=obj.LaserObj639;
                    obj.LaserLow=obj.LaserLow639;
                    obj.LaserHigh=obj.LaserHigh639;
                    obj.FilterWheelObj.setFilter(1);% when implemented pos 5
                    nextOffset=0;                   % no z-aberration offset for the TIRF mode, multiple laser lines at the same time.
                otherwise
                    error('SetInstrumentMode:: the instrument mode used as an input is not listed, the 639nm instrument mode will be selected. ')
                    obj.LaserObj=obj.LaserObj639;
                    obj.LaserLow=obj.LaserLow639;
                    obj.LaserHigh=obj.LaserHigh639;
                    obj.FilterWheelObj.setFilter(1);
                    nextOffset=0;
            end
            obj.UsedInstrMode=obj.InstrMode;
            fprintf(['The instrument mode being set for the measurement is ' obj.UsedInstrMode '\n'])
            
            % Set a z-position with the stage, to correct axial aberration
            % of the objective apon changing excitation wavelength
            [xPos,yPos,zPos] = obj.StageObj.getCurrentPosition;
            fprintf(['Before executing SetInstrumentMode, the XYZ(um) stage position was ' num2str(xPos,5) ' ' num2str(yPos,5) ' ' num2str(zPos,5)  '\n'])
            zPosNew = zPos + nextOffset - previousOffset;
            obj.StageObj.setzPosition(zPosNew);
            [xPos,yPos,zPos] = obj.StageObj.getCurrentPosition;
            fprintf(['After executing SetInstrumentMode, the new the XYZ(um) stage position is ' num2str(xPos,5) ' ' num2str(yPos,5) ' ' num2str(zPos,5)  '\n'])
        end
              
        function focusLow(obj)
            % Focus function using the low laser settings
            % Lasers set up to 'low' power setting, 405nm laser off
            obj.SetInstrumentMode; 
            obj.LampObj.off;
            obj.LaserObj405.off;
            obj.LaserObj.setPower(obj.LaserLow);
            T = timer('StartDelay',1,'TimerFcn',@(x,y)obj.LaserObj.on); % Temporary workaround: create delay, such that the laser starts after the camera starts. 
            %obj.LaserObj.on;
            % Aquiring and diplaying images
            start(T)
            obj.CameraObj.ROI=obj.getROI();
            obj.CameraObj.ExpTime_Focus=obj.ExpTime_Focus_Set;
            obj.CameraObj.start_focus();
            delete(T)
            % Turning laser/lamp off
            obj.LaserObj.off;
        end

        function focusHigh(obj)
            % Focus function using the high laser settings
            % Laser set up to 'high' power setting, 405nm laser on
            obj.SetInstrumentMode;
            obj.LampObj.off;
            obj.LaserObj405.on; 
            obj.LaserObj.setPower(obj.LaserHigh);
            T = timer('StartDelay',1,'TimerFcn',@(x,y)obj.LaserObj.on); % Temporary workaround: create delay, such that the laser starts after the camera starts. 
            %obj.LaserObj.on;
            % Aquiring and displaying images
            start(T)
            obj.CameraObj.ROI=obj.getROI();
            obj.CameraObj.ExpTime_Focus=obj.ExpTime_Focus_Set;
            obj.CameraObj.start_focus();
            delete(T)
            % Turning laser/lamp off
            obj.LaserObj.off;
            obj.LaserObj405.off;
        end
             
        function focusLamp(obj)
            % Continuous display of image with lamp on. Useful for focusing of
            % the microscope.
            obj.FilterWheelObj.setFilter(1); % The filter in position 1 is transparent for the lamp.
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
                    MIC_H5.createGroup(FileH5,'Data');
                    MIC_H5.createGroup(FileH5,'Data/Channel01');
                    
                    S=obj.InstrumentName;
                    MIC_H5.createGroup(FileH5,S);
                    obj.save2hdf5(FileH5,S);
                otherwise
                    error('StartSequence:: unknown file save type')
            end
            
            %Setup Camera, InstrumentMode and lasers
            obj.CameraObj.ExpTime_Sequence=obj.ExpTime_Sequence_Set;
            obj.CameraObj.SequenceLength=obj.NumFrames;
            obj.CameraObj.ROI=obj.getROI();
            obj.SetInstrumentMode; 
            obj.LaserObj.setPower(obj.LaserHigh);
            
            %Get current stage position in case the Zstack mode is activated 
            if strcmp(obj.ZstackStatus,'on')
                [~,~,zPos1] = obj.StageObj.getCurrentPosition;
                fprintf(['The current stage position Z = ' num2str(zPos1,5) ' µm.\n'])
            end
           
            %loop over sequences
            for nn=1:obj.NumSequences
                if obj.AbortNow; obj.AbortNow=0; break; end
                nstring=strcat('Acquiring','...',num2str(nn),'/',num2str(obj.NumSequences));
                set(guihandles.Button_ControlStart, 'String',nstring,'Enable','off');
                
                % Create delay, to start laser after imaging is initiated. As a temporary work around before applying triggering.            
                if nn==1
                    T = timer('StartDelay',0.7,'TimerFcn',@(x,y)obj.LaserObj.on); % Create delay, such that the laser starts after the camera starts. 
                    T2 = timer('StartDelay',0.7,'TimerFcn',@(x,y)obj.LaserObj405.on);
                    start(T)
                    start(T2)
                    %Collect
                    sequence=obj.CameraObj.start_sequence();
                    delete(T)
                    delete(T2)
                else
                    T = timer('StartDelay',0.5,'TimerFcn',@(x,y)obj.LaserObj.on); % Create delay, such that the laser starts after the camera starts. 
                    T2 = timer('StartDelay',0.5,'TimerFcn',@(x,y)obj.LaserObj405.on);
                    start(T)
                    start(T2)
                    %Collect
                    sequence=obj.CameraObj.start_sequence();
                    delete(T)
                    delete(T2)
                end
%                 obj.LaserObj405.on;
%                 obj.LaserObj.on; % Now the laser is on before the camera runs. We should trigger the laser by the camera.
%                 %Collect
%                 sequence=obj.CameraObj.start_sequence();
                
                %Turn off Laser
                obj.LaserObj.off;
                obj.LaserObj405.off;
                
                %Increase stage height by Zstep in case Zstack mode is activated, as long as it is not the last sequence.
                if strcmp(obj.ZstackStatus,'on') && (nn < obj.NumSequences)
                    newZpos=zPos1+obj.Zstep*nn;
                    obj.StageObj.setzPosition(newZpos);
                end
                
                %Save
                switch obj.SaveFileType
                    case 'mat'
                        fn=fullfile(obj.SaveDir,[obj.BaseFileName '#' num2str(nn,'%04d') s]);
                        Params=exportState(obj); %#ok<NASGU>
                        save(fn,'sequence','Params');
                    case 'h5' %This will become default
                        S=sprintf('Data%04d',nn);
                        compression=0;
                        MIC_H5.writeAsync_uint16(FileH5,'Data/Channel01',S,sequence,compression);
                    otherwise
                        error('StartSequence:: unknown SaveFileType')
                end
                
                %Show the stage height for the next sequence in case Zstack mode is activated, as long as it is not the last sequence.
                if strcmp(obj.ZstackStatus,'on') && (nn < obj.NumSequences)
                    [~,~,zPos2] = obj.StageObj.getCurrentPosition;
                    fprintf(['The stage position for sequence step ' num2str((nn+1)) ' Z = ' num2str(zPos2,5) ' µm.\n'])
                end
            end
            
             % in case of HDF5, save instrument state into HDF5 file:            
            switch obj.SaveFileType
                case 'mat'
                    %Nothing to do
                case 'h5' %This will become default
                    S=obj.InstrumentName;%'Channel01/Zposition001'; % This was not correct, it was overwriting the path names for the data and the data location got lost.
                    MIC_H5.createGroup(FileH5,S);
                    obj.save2hdf5(FileH5,S);  % This works. Use h5disp('path\name.h5') to see instrument state and dataset characteristics.
                otherwise
                    error('StartSequence:: unknown SaveFileType')
            end
            
            %Go back to the initial stage Z-position before sequence recording, in case Zstack mode is activated.
            if strcmp(obj.ZstackStatus,'on')
                obj.StageObj.setzPosition(zPos1);
                fprintf(['The recording of the sequence has finished, the stage is returned to its initial position Z = ' num2str(zPos1,5) ' µm.\n'])
            end
        end
        
        function ROI=getROI(obj) % it would be better if this is in the gui.
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
            % and SRcollect settings. Take care, the value of an object can
            % be different from the value filled in in the gui. This
            % might occur if the current state is exported after changing
            % values in the gui and not right after running the actual 
            % focus mode or measurement. 
            
            % Children
            [Children.Camera.Attributes,Children.Camera.Data,Children.Camera.Children]=...
                obj.CameraObj.exportState();
            
            [Children.Stage.Attributes,Children.Stage.Data,Children.Stage.Children]=...
                obj.StageObj.exportState();
            
            [Children.Laser.Attributes,Children.Laser.Data,Children.Laser.Children]=...
                obj.LaserObj.exportState();
            
            [Children.Laser405.Attributes,Children.Laser405.Data,Children.Laser405.Children]=...
                obj.LaserObj405.exportState();
                      
            [Children.Lamp.Attributes,Children.Lamp.Data,Children.Lamp.Children]=...
                obj.LampObj.exportState();            
            
            % Our Properties
            Attributes.ExpTime_Focus_Set = obj.ExpTime_Focus_Set;
            Attributes.ExpTime_Sequence_Set = obj.ExpTime_Sequence_Set;
            Attributes.NumFrames = obj.NumFrames;
            Attributes.NumSequences = obj.NumSequences;
            Attributes.CameraROI = obj.getROI;
            Attributes.CameraPixelSize=obj.PixelSize;
            Attributes.InstrumentMode=obj.InstrMode; 
            Attributes.UsedObjective=obj.UsedObjective;
            Attributes.SaveDir = obj.SaveDir;
            Attributes.LaserLow = obj.LaserLow;
            Attributes.LaserHigh = obj.LaserHigh;
            Data=[];
        end
    end
    
    methods (Static)
        
        function State = unitTest()
            State = obj.exportState();
        end
        
    end
end


