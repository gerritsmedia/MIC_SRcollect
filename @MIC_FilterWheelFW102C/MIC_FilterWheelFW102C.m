classdef MIC_FilterWheelFW102C < MIC_Abstract
    %  MIC_NDFilterWheel: Matlab Instrument Control for Thorlabs FW102C 
    %  Filter wheel containing filters that can be listed as an input.
    %  Filter wheel is connected via a USB port, which can seen as a COM
    %  (RS232) port in Windows (see device manager for port numbers).
    %
    %  This class works with the 6-position filter wheel.
    %  To create a MIC_NDFilterWheel object the filter name
    %  of each filter must be specified. The names are given as an
    %  array of strings, with the order corresponding to the positions in
    %  the filter wheel. Furthermore, the com port needs to be specified.
    %
    %  Example: obj=MIC_NDFilterWheel(Comport,Filters);
    %          Comport: COM port integer
    %          Filters: 6-element cell array of characters containing six 
    %          filter names.
    %  Example:
    %  FWobj = MIC_FilterWheelFW102C(11, {'LP655', 'BP565/133', 'BP525/50', 'BP605/52', 'Quad446/523/600/677',''})
    %  Functions: setFilter, exportState, delete, gui.
    %
    %  REQUIRES
    %   Matlab 2014b or higer
    %   MIC_Abstract.m
    %   Installation of the filterwheel drivers
    %
    % CITATION: Original code from MIC_NDFilterWheel.m, written by
    % Marjolein Meddens, Lidke Lab, 2017. Modified by Gert-Jan Bakker,
    % Radboudumc, 2018.
    
    properties (SetAccess=protected)
        InstrumentName = 'MIC_FilterWheelFW102C';
        CurrentFilterPos; % Current filter number, as obtained from calling filterwheel.
        CurrentFilterName; % Current filter name, derived from current pos
    end
    
    properties (Hidden)
        StartGUI = 0; % Flag for starting GUI when object of class is created
        RS232=[];
        setPosStr;
        test1;
        test2;
    end
    
    properties
        Comport;
        Filters; % N-element cell array containing six filter names
    end
    
    methods
        function obj=MIC_FilterWheelFW102C(Comport, Filters)
            % Object constructor
            
            % pass AutoName input into base classes
            obj = obj@MIC_Abstract(~nargout);
            
            % check input
            if nargin <2
                error('MIC_FilterWheelFW102C:narginlow','Not enough input arguments, 2 inputs required');
            elseif nargin >2
                error('MIC_FilterWheelFW102C:narginhigh','Too many input arguments, 2 inputs required');
            end
            if Comport < 1 || Comport > 255
                error('MIC_FilterWheelFW102C:id','Invalid COMport number');
            end
            if numel(Filters) ~= 6
                error('MIC_FilterWheelFW102C:InputSizes','The cell array of filters should have 6 elements');
            elseif ~iscellstr(Filters)
                error('MIC_FilterWheelFW102C:FiltersType','Invalid type of FracTransmVals input, must be numeric');
            end
            
            % Initialize Filterwheel
            obj.RS232 = serial(['COM',num2str(Comport)],'BaudRate', 115200, 'Terminator', 'CR','DataBits',8, 'Parity', 'none', 'Stopbits',1 ,'FlowControl', 'none');
            fopen(obj.RS232);
            
            % initialize properties
            obj.Comport = Comport;
            obj.Filters = Filters;            
            
            % move to first position
            obj.setFilter(2); % First to a position nearby,
            obj.setFilter(1); % then the final first position to hear it move
        end
        
        function setFilter(obj,SetFilterPos)
            % Sets filter to SetFilterPos
            % INPUT
            %   SetFilterPos - number of filter to switch to
            % check input
            if ~round(SetFilterPos)==(SetFilterPos) || SetFilterPos>numel(obj.Filters)
                error('MIC_FilterWheelFW102C:SetFilterPos',...
                    'Invalid input, SetFilterPos should be an integer between 1 and 6, corresponding to a filter position');
            else
                % move filter
                obj.setPosStr=['pos=', num2str(SetFilterPos)];
                fprintf(obj.RS232,obj.setPosStr); % command to move to the recquired position SetFilterPos
                pause(3)
                %fprintf(obj.RS232,'baud?')  %>>> Somehow it does not work to listen to the output. It gives Jabberish, each time something else, like an echo of a previous command. Contact Thorlabs.    
                %pause(0.1)
                %fscanf(obj.RS232); % Listen to the output
                %test=fscanf(obj.RS232); % Listen to the output                
                %fprintf(['The test is ' test ' ' num2str(SetFilterPos) '\n']); 
                
                obj.CurrentFilterPos = SetFilterPos; %str2num(test(strfind(test,num2str(SetFilterPos))) ); % In case the filterwheel did not move to the set position, strfind will be empty and an empty character array will be found.
                if obj.CurrentFilterPos~=SetFilterPos% || obj.CurrentFilterPos~=2% If it did not move position, then error message:
                    error('MIC_FilterWheelFW102C:SetFilter','Filterwheel does not respond to obj.setFilter(position) command');
                else
                    obj.CurrentFilterName = obj.Filters(obj.CurrentFilterPos);
                    fprintf(['Filterwheel ', obj.InstrumentName, ' moved to position ',num2str(obj.CurrentFilterPos), ' Filter ', char(obj.CurrentFilterName), '.\n'])
                    obj.updateGui();%  ,  cellstr(obj.CurrentFilterName),
                end
            end
        end
        
        
        function updateGui(obj)
            % find button group
            if isempty(obj.GuiFigure) || ~isvalid(obj.GuiFigure)
                return
            end
            for ii = 1 : numel(obj.GuiFigure.Children)
                if strcmp(obj.GuiFigure.Children(ii).Tag,'buttonGroup')
                    % set the selected filter to the current filter
                    tagCellStr = {obj.GuiFigure.Children(ii).Children.Tag};
                    tagCellNum = cellfun(@(x) str2double(x),tagCellStr,'UniformOutput',false);
                    tagNum = cell2mat(tagCellNum);
                    obj.GuiFigure.Children(ii).SelectedObject = obj.GuiFigure.Children(ii).Children(tagNum == obj.CurrentFilterPos);
                end
            end
        end
        
        function delete(obj)
            fclose(obj.RS232); % In addition to what is implemented in MIC.abstract, the port also needs to be closed before the object is deleted.
        end
               
        function [Attributes,Data,Children] = exportState(obj)
            % Exports current state of MIC_NDFilterWheel object
            Attributes.InstrumentName = obj.InstrumentName;
            Attributes.CurrentFilterPos = obj.CurrentFilterPos;
            Attributes.CurrentFilterName = obj.CurrentFilterName;
            Attributes.Filters = obj.Filters;
            Attributes.Comport = obj.Comport;
            Data=[];
            Children = [];            
        end
    end
    
    methods(Static)
        function State = unitTest(Comport, Filters)
            % MIC_FilterWheelFW102C.unitTest(Comport, Filters)
            % performs test of all MIC_FilterWheelFW102C functionality
            %
            % INPUT Comport: COM port integer
            %       Filters: 6-element cell array of characters containing
            %       filter names.
            % example: MIC_FilterWheelFW102C.unitTest(11, {'LP655', 'BP565/133', 'BP525/50', 'BP605/52', 'Quad446/523/600/677',''})
            
            fprintf('\nTesting MIC_FilterWheelFW102C class...\n')
            % constructing and deleting instances of the class
            FWobj = MIC_FilterWheelFW102C(Comport, Filters);
            FWobj.delete;
            clear FWobj;
            fprintf('* Construction and Destruction of object works\n')
            fprintf('* Did you hear/see the filter wheel move?\n')
            fprintf('  If you saw/heard that, changing the filter works works\n');
            FWobj = MIC_FilterWheelFW102C(Comport, Filters);
            % loading and closing gui
            GUIfig = FWobj.gui;
            close(GUIfig);
            FWobj.gui;
            fprintf('* Opening and closing of GUI works, please test GUI manually within 10 seconds\n');
            % Change filter
            fprintf('* Export of current state works, please check workspace for it\n')
            pause(10)
            % export state
            State = FWobj.exportState;
            fprintf('Finished testing MIC_NDFilterWheel class.\n');
            FWobj.delete;
        end
    end
end