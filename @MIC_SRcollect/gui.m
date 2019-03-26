
function gui(obj)
% GUI SRcollect Gui for STORM microscope
%   Detailed explanation goes here

h = findall(0,'tag','SRcollect.gui');
if ~(isempty(h))
    figure(h);
    return;
end
%%
xsz=400;
ysz=550;
xst=100;
yst=100;
pw=.95; % panel width
psep=.001;  % panel separation
ppad=0.025; % panel padding
staticst=10;
editst=113;

guiFig = figure('Units','pixels','Position',[xst yst xsz ysz],...
    'MenuBar','none','ToolBar','none','Visible','on',...
    'NumberTitle','off','UserData',0,'Tag',...
    'TIRF-SRcollect.gui','HandleVisibility','off','name','SRcollect.gui','CloseRequestFcn',@FigureClose);

defaultBackground = get(0,'defaultUicontrolBackgroundColor');
set(guiFig,'Color',defaultBackground);
handles.output = guiFig;
guidata(guiFig,handles);

refh=1;

% File Panel
fphp=99;
fph=fphp/ysz;    % File panel height
pstartx=1-(psep+fph);
hFilePanel = uipanel('Parent',guiFig,'Title','FILE','Position',[ppad pstartx pw fph]);

uicontrol('Parent',hFilePanel, 'Style', 'edit', 'String', 'Save Directory:','Enable','off','Position', [staticst 60 100 20]);
handles.Edit_FileDirectory = uicontrol('Parent',hFilePanel, 'Style', 'edit', 'String','Set Auto','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 60 250 20]);
uicontrol('Parent',hFilePanel, 'Style', 'edit', 'String', 'Base FileName:','Enable','off','Position', [staticst 35 100 20]);
handles.Edit_FileName = uicontrol('Parent',hFilePanel, 'Style', 'edit', 'String','Set Auto','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 35 250 20]);
uicontrol('Parent',hFilePanel, 'Style', 'edit', 'String','File type:','Enable','off','Position', [staticst 10 100 20]);
handles.saveFileType = uicontrol('Parent',hFilePanel, 'Style', 'popupmenu', 'String',{'mat','h5'},'Enable','on','BackgroundColor',[1 1 1],'Position', [editst 10 250 21]); % ,'CallBack',@saveFile

% Control Panel
cphp=350;
cph=cphp/ysz;    % Control panel height
pstartx=pstartx-(psep+cph);

hControlPanel = uipanel('Parent',guiFig,'Title','Microscope control','Position',[ppad pstartx pw cph]);

% Instrument mode
hInstrPanel = uipanel(hControlPanel,'Position',[ppad 0.85 pw 0.12]);
uicontrol('Parent',hInstrPanel, 'Style', 'edit', 'String','Instrument Mode:','Enable','off','Position', [staticst 10 100 20]);
InstrModelist={'639nm','Dual 488nm', 'Triple 488nm', 'Triple 561nm', 'Fast TIRFM quad band'};
handles.Popup_InstrMode = uicontrol('Parent',hInstrPanel, 'Style', 'popupmenu', 'String',InstrModelist,'Enable','on','BackgroundColor',[1 1 1],'Position', [editst 10 115 20]); % ,'CallBack',@obj.SetInstrumentMode

% Camera controls
hCameraPanel = uipanel(hControlPanel,'Position',[ppad 0.43 pw 0.40]);

uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Camera ROI:','Enable','off','Position', [staticst 100 100 20]);
ROIlist={'Full','Center300'};
handles.Popup_CameraROI = uicontrol('Parent',hCameraPanel, 'Style', 'popupmenu', 'String',ROIlist,'Enable','on','BackgroundColor',[1 1 1],'Position', [editst 100 115 20]);

uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Zoom:','Enable','off','Position', [235 100 50 20]);
handles.Popup_CameraDispZoom = uicontrol('Parent',hCameraPanel, 'Style','popupmenu','String',{'50%','100%','200%','400%','1000%'},'Value',2,'Enable','on','BackgroundColor',[1 1 1],'Position', [290 100 57 20],'CallBack',@zoom_set);

uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Exp. Time Focus:','Enable','off','Position', [staticst 70 100 20]);
handles.Edit_CameraExpTimeFocusSet = uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','0.01','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 70 50 20]);
% uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Actual:','Enable','off','Position', [175 70 100 20]);
% handles.Edit_CameraExpTimeFocusActual = uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','','Enable','off','Position', [250 70 98 20]);

uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Exp. Time Seq.:','Enable','off','Position', [staticst 40 100 20]);
handles.Edit_CameraExpTimeSeqSet = uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','0.01','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 40 50 20],'CallBack',@sequence_set);
% uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Actual:','Enable','off','Position', [175 40 100 20]);
% handles.Edit_CameraExpTimeSeqActual = uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String',num2str(obj.CameraObj.SequenceCycleTime),'Enable','off','Position', [250 40 98 20]);

uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Num Frames:','Enable','off','Position', [staticst 10 100 20]);
handles.Edit_CameraNumFrames = uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','2000','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 10 50 20]);
uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','Number of Sequences:','Enable','off','Position', [175 10 132 20]);
handles.Edit_ControlNSequence = uicontrol('Parent',hCameraPanel, 'Style', 'edit', 'String','20','Enable','on','BackgroundColor',[1 1 1],'Position', [310 10 38 20]);

% Laser controls
hLaserPanel = uipanel(hControlPanel,'Position',[ppad 0.01 pw 0.41]);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','Low Power 639nm: ','Enable','off','Position', [staticst 105 100 20]);
handles.Edit_LP639 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','0.01','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 105 50 20],'CallBack',@setLaserLow639);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','High Power 639nm: ','Enable','off','Position', [175 105 100 20]);
handles.Edit_HP639 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','50','Enable','on','BackgroundColor',[1 1 1],'Position', [275 105 50 20],'CallBack',@setLaserHigh639);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','Low Power 561nm: ','Enable','off','Position', [staticst 75 100 20]);
handles.Edit_LP561 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','0.01','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 75 50 20],'CallBack',@setLaserLow561);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','High Power 561nm: ','Enable','off','Position', [175 75 100 20]);
handles.Edit_HP561 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','50','Enable','on','BackgroundColor',[1 1 1],'Position', [275 75 50 20],'CallBack',@setLaserHigh561);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','Low Power 488nm: ','Enable','off','Position', [staticst 45 100 20]);
handles.Edit_LP488 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','0.01','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 45 50 20],'CallBack',@setLaserLow488);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','High Power 488nm: ','Enable','off','Position', [175 45 100 20]);
handles.Edit_HP488 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','50','Enable','on','BackgroundColor',[1 1 1],'Position', [275 45 50 20],'CallBack',@setLaserHigh488);
% slider 405
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','Pumping 405nm: ','Enable','off','Position', [staticst 15 100 20]);
handles.Edit_405 = uicontrol('Parent',hLaserPanel, 'Style', 'slider','Min',0,'Max',50,'Value',0,'Enable','on','BackgroundColor',[1 1 1],'Position', [editst 15 194 20],'CallBack',@setLaser405);
handles.Text_Edit_405 = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String', num2str(handles.Edit_405.Value,3),'Enable','off','Position', [310 15 38 20]); % initial slider value


% Button Panel
bphp=80;
bph=bphp/ysz;    % Button panel height
pstartx=pstartx-(5*psep+bph);

hButtonPanel = uipanel('Parent',guiFig,'Position',[ppad pstartx pw bph]);
handles.Button_ControlFocusLamp=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','Brightfield','Enable','on','Position', [staticst+2 42 110 30],'BackgroundColor',[1 1 .8],'Callback',@FocusLamp);
handles.Button_ControlFocusLaserLow=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','Focus Laser (Low)','Enable','on','Position', [staticst+122 42 110 30],'BackgroundColor',[1 .8 .8],'Callback',@FocusLow);
handles.Button_ControlFocusLaserHigh=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','Focus Laser (High)','Enable','on','Position', [staticst+244 42 110 30],'BackgroundColor',[1 0 0],'Callback',@FocusHigh);
handles.Button_ControlStart=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','START','Enable','on','Position', [staticst 5 175 30],'BackgroundColor',[0 1 0],'Callback',@Start);
handles.Button_ControlAbort=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','ABORT','Enable','on','Position', [staticst+180 5 175 30],'BackgroundColor',[1 0 1],'Callback',@Abort);

%% Setup GUI Values

properties2gui();


%% Figure Callbacks

%     function saveFile(~,~)
%         file_val=get(handles.saveFileType,'value');
%         switch file_val
%             case 1
%                 obj.SaveFileType='mat';
%             case 2
%                 obj.SaveFileType='h5';
%         end
%     end

    function FocusLamp(~,~)
        gui2properties();
        obj.focusLamp();
    end

    function FocusLow(~,~)
        gui2properties();
        obj.focusLow();
    end

    function FocusHigh(~,~)
        gui2properties();
        obj.focusHigh();
        set(handles.Edit_405,'Value',0); % 405 laser back to 0
        handles.Text_Edit_405.String = num2str(0,3);
        obj.LaserObj405.setPower(handles.Edit_405.Value);
    end

    function Abort(~,~)
        obj.AbortNow=1; 
        set(handles.Button_ControlStart, 'String','START','Enable','on');
        set(handles.Edit_405,'Value',0); % 405 laser back to 0
        handles.Text_Edit_405.String = num2str(0,3);
        obj.LaserObj405.setPower(handles.Edit_405.Value);
    end

    function Start(~,~)
        gui2properties();
        set(handles.Button_ControlStart, 'String','Acquiring','Enable','off');
        obj.StartSequence(handles);
        set(handles.Button_ControlStart, 'String','START','Enable','on');
        set(handles.Edit_405,'Value',0); % 405 laser back to 0
        handles.Text_Edit_405.String = num2str(0,3);
        obj.LaserObj405.setPower(handles.Edit_405.Value);
    end 
    
    % These laserpower set functions are kind of double, since they are
    % also included in the functions FocusLow, High, Start in SR_collect.
    % The power values are exported to the classes with gui2properties.
    % Maybe the functions serve to adapt the laser power on the fly, during 
    % the imaging itself.
    function setLaserLow639(~,~)
        obj.LaserObj639.setPower(str2double(handles.Edit_LP639.String));
    end

    function setLaserHigh639(~,~)
        obj.LaserObj639.setPower(str2double(handles.Edit_HP639.String));
    end
    
    function setLaserLow561(~,~)
        obj.LaserObj561.setPower(str2double(handles.Edit_LP561.String));
    end

    function setLaserHigh561(~,~)
        obj.LaserObj561.setPower(str2double(handles.Edit_HP561.String));
    end
    
    function setLaserLow488(~,~)
        obj.LaserObj488.setPower(str2double(handles.Edit_LP488.String));
    end

    function setLaserHigh488(~,~)
        obj.LaserObj488.setPower(str2double(handles.Edit_HP488.String));
    end

    function setLaser405(~,~)
        obj.LaserObj405.setPower(handles.Edit_405.Value);
        handles.Text_Edit_405.String = num2str(handles.Edit_405.Value,3);
        %Newtext=num2str(get(handles.Edit_405,'value')); % (same with set and get)
        %set(handles.Text_Edit_405,'string',Newtext); % (same with set and get)
        %handles.Text_Edit_405 = uicontrol('Parent',hLaserPanel, 'Style','edit', 'String', Newtext,'Enable','on','Position', [310 15 38 20]); % (how I did it before)
    end

    function FigureClose(~,~)
        gui2properties();
        delete(guiFig);
    end

% TO DO add function zoom_default, which sets zoom pullout case according to
% camera ROI. The UIcontrol must be made slave instead of parent.
    function zoom_set(~,~)
        zoom_val = get(handles.Popup_CameraDispZoom,'Value');
        switch zoom_val
            case 1
                obj.CameraObj.DisplayZoom = 0.5;
            case 2
                obj.CameraObj.DisplayZoom = 1;
            case 3
                obj.CameraObj.DisplayZoom = 2;
            case 4
                obj.CameraObj.DisplayZoom = 4;
            case 5
                obj.CameraObj.DisplayZoom = 10;
        end
        
    end

    function gui2properties()
        %Get GUI values and update to object properties
        obj.SaveDir=get(handles.Edit_FileDirectory,'String'); % or ... =handles.Edit_FileDirectory.String? Are the set-get commands oldfashioned? I like the object oriented programming manner more.
        obj.BaseFileName=get(handles.Edit_FileName,'String');
        obj.CameraROI=get(handles.Popup_CameraROI,'value');
        obj.ExpTime_Focus_Set=str2double(get(handles.Edit_CameraExpTimeFocusSet,'string'));
        obj.ExpTime_Sequence_Set=str2double(get(handles.Edit_CameraExpTimeSeqSet,'string'));
        obj.NumFrames=str2double(get(handles.Edit_CameraNumFrames,'string'));
        obj.LaserLow639=str2double(handles.Edit_LP639.String);
        obj.LaserHigh639=str2double(handles.Edit_HP639.String);
        obj.LaserLow561=str2double(handles.Edit_LP561.String);
        obj.LaserHigh561=str2double(handles.Edit_HP561.String);
        obj.LaserLow488=str2double(handles.Edit_LP488.String);
        obj.LaserHigh488=str2double(handles.Edit_HP488.String);       
        obj.NumSequences=str2double(get(handles.Edit_ControlNSequence,'string')); 
        InstrVal=handles.Popup_InstrMode.Value;
        InstrList=handles.Popup_InstrMode.String;
        obj.InstrMode=InstrList{InstrVal};
        FileTypeVal=handles.saveFileType.Value;
        FileTypeList=handles.saveFileType.String; 
        obj.SaveFileType=FileTypeList{FileTypeVal};
        
    end
   
    function properties2gui()
        %Set GUI values from object properties
        set(handles.Edit_FileDirectory,'String',obj.SaveDir);
        set(handles.Edit_FileName,'String',obj.BaseFileName);
        set(handles.Popup_CameraROI,'value',obj.CameraROI);
        set(handles.Edit_CameraExpTimeFocusSet,'string',num2str(obj.ExpTime_Focus_Set));
        set(handles.Edit_CameraExpTimeSeqSet,'string',num2str(obj.ExpTime_Sequence_Set));
        set(handles.Edit_CameraNumFrames,'string',num2str(obj.NumFrames));
        set(handles.Edit_LP639,'string',obj.LaserLow639);
        set(handles.Edit_HP639,'string',obj.LaserHigh639);
        set(handles.Edit_LP561,'string',obj.LaserLow561);
        set(handles.Edit_HP561,'string',obj.LaserHigh561);
        set(handles.Edit_LP488,'string',obj.LaserLow488);
        set(handles.Edit_HP488,'string',obj.LaserHigh488);
        set(handles.Edit_405,'Max',obj.LaserMax405);    % to set ruler 405 between 0 and max value, to be set in SRcollect as a fixed value.    
        set(handles.Edit_ControlNSequence,'string',num2str(obj.NumSequences));
        
        InstrList=handles.Popup_InstrMode.String; 
        for i=1:length(InstrList) % find the right index of the pull out menu, 
            if isequal(InstrList{i},obj.InstrMode) % such that it shows the instrument mode of the object.
                set(handles.Popup_InstrMode,'value',i); % set the pull out menu to this index.
            end
        end
        
        FileTypeList=handles.saveFileType.String; 
        for i=1:length(FileTypeList) % find the right index of the pull out menu, 
            if isequal(FileTypeList{i},obj.SaveFileType) % such that it shows the instrument mode of the object.
                set(handles.saveFileType,'value',i); % set the pull out menu to this index.
            end
        end

    end
   
    



end

% Function to select instrument mode in an alternative manner, see Matlab example 'uicontrol'. 
%     function instrumentMode_set(source,event) %use 'CallBack', @instrumentMode_set
%         val = source.Value;
%         InstrModes = source.String;
%         obj.InstrMode=InstrModes{val};
    
%     function setLampPower(~,~)
%         gui2properties();
%         obj.setLampPower();  
%     end

