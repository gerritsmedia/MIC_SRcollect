classdef MIC_PIPiezo < MIC_Abstract
    % MIC_PIPiezo: Matlab instrument class for PI piezo
    %
    % Class controls the PI piezo.
    % Detailed description on the piezo goes here
    %
    % Example: Piezo=MIC_PIPiezo()
    % Functions: setxPosition, setyPosition, setzPosition, setZero,
    % getCurrentPosition, centerXY, delete, exportState
    %
    % REQUIREMENTS:
    % MIC_Abstract
    % MATLAB 2014 or higher
    % Access to the MATLAB driver location. (private folder).
    %
    % CITATION: Sandeep Pallikkuth, LidkeLab, 2018
    
    properties
        StepSize=0.005;
        CurrentPosition;
        Max=[200,200,200];
        Min=[0,0,0];
    end
    properties (SetAccess = protected)
        InstrumentName='PIPiezo' % Descriptive Instrument Name
    end
    properties (SetAccess = private, GetAccess = public)
        DriverPath='C:\Users\Public\PI\PI_MATLAB_Driver_GCS2';
%         DriverPath='';
        Controller;
        stageType = 'E-727.3RDA';
        controllerSerialNumber;
        E727;
        boolE727connected;
    end
    
    properties
        StartGUI    % to pop up gui by creating an object for this class
    end
    
    methods
        
        function obj=MIC_PIPiezo()
            % constructor
            if isempty(obj.DriverPath)
                [obj.DriverPath]=uigetdir(matlabroot,'Select PI Driver Directory');
                if exist(obj.DriverPath,'dir')
                    addpath(obj.DriverPath);
                else
                    error('Not a valid path')
                end
            else
                if exist(obj.DriverPath,'dir')
                    addpath(obj.DriverPath);
                else
                    error('Not a valid path for driver')
                end
            end
            if(~exist('Controller','var'))
                obj.Controller = PI_GCS_Controller();
            end;
            % Use USB connection
            obj.controllerSerialNumber = '0116043635'; % Find the correct serial number
            obj.setup;
            obj.setZero;
        end
        
        function setup(obj)
            % Initialization
            obj.boolE727connected = false;
            if (~obj.boolE727connected)
                obj.E727 = obj.Controller.ConnectUSB(obj.controllerSerialNumber);
            end
            if (obj.E727.IsConnected)
                obj.boolE727connected = true;
            end
            % initialize controller
            obj.E727 = obj.E727.InitializeController();
        end
        
        
        function delete(obj)
            % destructor
            if(obj.boolE727connected)
                obj.setZero;
                obj.E727.CloseConnection;
                obj.Controller.Destroy;
                clear E727;
                clear Controller;
            end
            delete(obj.GuiFigure);
        end
        
        function setxPosition(obj,Pos)
            % moving stage to a set position on x direction
            if(Pos>obj.Max(1))
                warning('Input position out of range. Stage set to max position');
                Pos=obj.Max(1);
            elseif(Pos<obj.Min(1))
                warning('Input position out of range. Stage set to min position');
                Pos=obj.Min(1);
            end
            if(obj.boolE727connected)
                if(obj.E727.IsControllerReady)
                    obj.E727.MOV('1',Pos);
                    while(obj.E727.IsMoving('1'))    % waiting for the move
                        pause(0.1);
                    end
                end
            end
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            obj.CurrentPosition=[xPos,yPos,zPos];
       end
        
        function setyPosition(obj,Pos)
            % moving stage to a set position on y direction
            if(Pos>obj.Max(2))
                warning('Input position out of range. Stage set to max position');
                Pos=obj.Max(2);
            elseif(Pos<obj.Min(2))
                warning('Input position out of range. Stage set to min position');
                Pos=obj.Min(2);
            end
            if(obj.boolE727connected)
                if(obj.E727.IsControllerReady)
                    obj.E727.MOV('2',Pos);
                    while(obj.E727.IsMoving('2'))    % waiting for the move
                        pause(0.1);
                    end
                end
            end
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            obj.CurrentPosition=[xPos,yPos,zPos];
        end
        
        function setzPosition(obj,Pos)
            % moving stage to a set position on z direction
            if(Pos>obj.Max(3))
                warning('Input position out of range. Stage set to max position');
                Pos=obj.Max(3);
            elseif(Pos<obj.Min(3))
                warning('Input position out of range. Stage set to min position');
                Pos=obj.Min(3);
            end
            if(obj.boolE727connected)
                if(obj.E727.IsControllerReady)
                    obj.E727.MOV('3',Pos);
                    while(obj.E727.IsMoving('3'))    % waiting for the move
                        pause(0.1);
                    end
                end
            end
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            obj.CurrentPosition=[xPos,yPos,zPos];
        end
        
        function movexUp(obj,Step)
            % Moving x up by 'Step' in number of StepSize
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            newXPos=xPos+(Step*obj.StepSize);
            obj.setxPosition(newXPos);
        end

        function movexDown(obj,Step)
            % Moving x down by 'Step' in number of StepSize
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            newXPos=xPos-(Step*obj.StepSize);
            obj.setxPosition(newXPos);
        end

        function moveyUp(obj,Step)
            % Moving y up by 'Step' in number of StepSize
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            newYPos=yPos+(Step*obj.StepSize);
            obj.setyPosition(newYPos);
        end

        function moveyDown(obj,Step)
            % Moving y down by 'Step' in number of StepSize
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            newYPos=yPos-(Step*obj.StepSize);
            obj.setyPosition(newYPos);
        end

        function movezUp(obj,Step)
            % Moving z up by 'Step' in number of StepSize
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            newZPos=zPos+(Step*obj.StepSize);
            obj.setzPosition(newZPos);
        end

        function movezDown(obj,Step)
            % Moving z down by 'Step' in number of StepSize
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            newZPos=zPos-(Step*obj.StepSize);
            obj.setzPosition(newZPos);
        end

        function [xPos,yPos,zPos]=getCurrentPosition(obj)
            % getting current stage position
            if(obj.boolE727connected)
                if(obj.E727.IsControllerReady)
                    xPos=obj.E727.qPOS('1');
                    yPos=obj.E727.qPOS('2');
                    zPos=obj.E727.qPOS('3');
                end
            end
        end
        
        function setZero(obj)
            % move stage to 0 on all three axes
            if(obj.boolE727connected)
                if(obj.E727.IsControllerReady)
                    obj.E727.MOV('1',0);
                    while(obj.E727.IsMoving('1'))    % waiting for the move
                        pause(0.1);
                    end
                    obj.E727.MOV('2',0);
                    while(obj.E727.IsMoving('2'))    % waiting for the move
                        pause(0.1);
                    end
                    obj.E727.MOV('3',0);
                    while(obj.E727.IsMoving('3'))    % waiting for the move
                        pause(0.1);
                    end
                end
            end
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            obj.CurrentPosition=[xPos,yPos,zPos];
        end
        
        function centerXY(obj)
            % center the stage in XY
            if(obj.boolE727connected)
                if(obj.E727.IsControllerReady)
                    obj.E727.MOV('1',(obj.Max(1))/2);
                     while(obj.E727.IsMoving('1'))    % waiting for the move
                        pause(0.1);
                    end
                   obj.E727.MOV('2',(obj.Max(2))/2);
                    while(obj.E727.IsMoving('2'))    % waiting for the move
                        pause(0.1);
                    end
                end
            end
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            obj.CurrentPosition=[xPos,yPos,zPos];
        end
        
        function [Attributes,Data,Children]=exportState(obj)
            % Export the object current state
            [xPos,yPos,zPos]=obj.getCurrentPosition;
            Attributes.CurrentXPosition=xPos;
            Attributes.CurrentYPosition=yPos;
            Attributes.CurrentZPosition=zPos;
            Data=[];
            Children=[];
        end
    end
    methods (Static)
        function Success=unitTest()
            try
                fprintf('Creating Object\n')
                Piezo=MIC_PIPiezo() 
                fprintf('Displaying current status of stage\n')
                [xPos,yPos,zPos]=Piezo.getCurrentPosition
                pause(.1)
                fprintf('Moving stage to [3,5,7]\n')
                Piezo.setxPosition(3);
                Piezo.setyPosition(5);
                Piezo.setzPosition(7);
                fprintf('Displaying new position\n')
                Piezo.CurrentPosition
                pause(.1)
                fprintf('Setting stage back to (0,0,0)\n')
                Piezo.setZero;
                pause(.1)
                fprintf('Displaying exportState\n')
                [Attributes,Data,Children]=Piezo.exportState
                fprintf('Deleting object\n')
                Piezo.delete;
                Success=1;
            catch
                Success=0;
            end
        end
    end
end