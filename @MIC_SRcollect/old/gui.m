
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
ysz=460;
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
handles.saveFileType = uicontrol('Parent',hFilePanel, 'Style', 'popupmenu', 'String',{'.mat','.h5'},'Enable','on','BackgroundColor',[1 1 1],'Position', [editst 10 250 21],'CallBack',@saveFile);

% Control Panel
cphp=275;
cph=cphp/ysz;    % Control panel height
pstartx=pstartx-(psep+cph);

hControlPanel = uipanel('Parent',guiFig,'Title','CAMERA AND LASER','Position',[ppad pstartx pw cph]);

% Camera controls
hCameraPanel = uipanel(hControlPanel,'Position',[ppad 0.38 pw 0.62]);


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
hLaserPanel = uipanel(hControlPanel,'Position',[ppad 0.01 pw 0.36]);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','Low Power: ','Enable','off','Position', [staticst 10 100 20]);
handles.Edit_LP = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','0.01','Enable','on','BackgroundColor',[1 1 1],'Position', [editst 10 50 20],'CallBack',@setLaserLow);
uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','High Power: ','Enable','off','Position', [175 10 100 20]);
handles.Edit_HP = uicontrol('Parent',hLaserPanel, 'Style', 'edit', 'String','50','Enable','on','BackgroundColor',[1 1 1],'Position', [275 10 50 20],'CallBack',@setLaserHigh);

% Button Panel
bphp=80;
bph=bphp/ysz;    % Button panel height
pstartx=pstartx-(5*psep+bph);

hButtonPanel = uipanel('Parent',guiFig,'Position',[ppad pstartx pw bph]);
handles.Button_ControlFocusLamp=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','Focus Lamp','Enable','on','Position', [staticst+2 42 110 30],'BackgroundColor',[1 1 .8],'Callback',@FocusLamp);
handles.Button_ControlFocusLaserLow=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','Focus Laser (Low)','Enable','on','Position', [staticst+122 42 110 30],'BackgroundColor',[1 .8 .8],'Callback',@FocusLow);
handles.Button_ControlFocusLaserHigh=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','Focus Laser (High)','Enable','on','Position', [staticst+244 42 110 30],'BackgroundColor',[1 0 0],'Callback',@FocusHigh);
handles.Button_ControlStart=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','START','Enable','on','Position', [staticst 5 175 30],'BackgroundColor',[0 1 0],'Callback',@Start);
handles.Button_ControlAbort=uicontrol('Parent',hButtonPanel, 'Style', 'pushbutton', 'String','ABORT','Enable','on','Position', [staticst+180 5 175 30],'BackgroundColor',[1 0 1],'Callback',@Abort);

%% Setup GUI Values

properties2gui();


%% Figure Callbacks

    function saveFile(~,~)
        file_val=get(handles.saveFileType,'value');
        switch file_val
            case 1
                obj.SaveFileType='mat';
            case 2
                obj.SaveFileType='h5';
        end
    end

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
    end

    function Abort(~,~)
        obj.AbortNow=1; 
        set(handles.Button_ControlStart, 'String','START','Enable','on');
    end

    function Start(~,~)
        gui2properties();
        set(handles.Button_ControlStart, 'String','Acquiring','Enable','off');
        obj.StartSequence(handles);
        set(handles.Button_ControlStart, 'String','START','Enable','on');
    end 
    
    function setLampPower(~,~)
        gui2properties();
        obj.setLampPower();  
    end
    
    function setLaserLow(~,~)
        obj.LaserObj.setPower(str2double(handles.Edit_LP.String));
    end

    function setLaserHigh(~,~)
        obj.LaserObj.setPower(str2double(handles.Edit_HP.String));
    end


    function FigureClose(~,~)
        gui2properties();
        delete(guiFig);
    end

% add function zoom_default, which sets zoom pullout case according to
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
        obj.SaveDir=get(handles.Edit_FileDirectory,'String');
        obj.BaseFileName=get(handles.Edit_FileName,'String');
        obj.CameraROI=get(handles.Popup_CameraROI,'value');
        obj.ExpTime_Focus_Set=str2double(get(handles.Edit_CameraExpTimeFocusSet,'string'));
        obj.ExpTime_Sequence_Set=str2double(get(handles.Edit_CameraExpTimeSeqSet,'string'));
        obj.NumFrames=str2double(get(handles.Edit_CameraNumFrames,'string'));
        obj.LaserLow=str2double(handles.Edit_LP.String);
        obj.LaserHigh=str2double(handles.Edit_HP.String);
        obj.NumSequences=str2double(get(handles.Edit_ControlNSequence,'string')); 
      
    end
   
    function properties2gui()
        %Set GUI values from object properties
        set(handles.Edit_FileDirectory,'String',obj.SaveDir);
        set(handles.Edit_FileName,'String',obj.BaseFileName);
        set(handles.Popup_CameraROI,'value',obj.CameraROI);
        set(handles.Edit_CameraExpTimeFocusSet,'string',num2str(obj.ExpTime_Focus_Set));
        set(handles.Edit_CameraExpTimeSeqSet,'string',num2str(obj.ExpTime_Sequence_Set));
        set(handles.Edit_CameraNumFrames,'string',num2str(obj.NumFrames));
        set(handles.Edit_LP,'string',obj.LaserLow);
        set(handles.Edit_HP,'string',obj.LaserHigh);
        set(handles.Edit_ControlNSequence,'string',num2str(obj.NumSequences));

    end
   
    



end

