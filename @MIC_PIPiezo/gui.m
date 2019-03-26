function gui(obj)
%prevent opening more than one gui for an objext.
if ishandle(obj.GuiFigure)
    guiFig = obj.GuiFigure;
    figure(obj.GuiFigure);
    return
end

gw=500;
gh=200;
guiFig = figure('Resize','off','Units','pixels','Position',[100 800 gw gh],'MenuBar','none','ToolBar','none','Visible','on','NumberTitle','off','Name','PI Piezo Control','UserData',0);
defaultBackground=get(0,'defaultUicontrolBackgroundColor');
set(guiFig,'Color',defaultBackground)
handles.output= guiFig;
guidata(guiFig,handles)

% Button handles
handles.Button_CenterXY=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Center XY','Enable','on','Position', [40 100 115 30],'BackgroundColor',[1 1 .8],'Callback',@centerXY);
handles.Button_Zero=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Set Zero','Enable','on','Position', [40 40 115 30],'BackgroundColor',[1 1 .8],'Callback',@setZero);

uicontrol('Parent',guiFig, 'Style', 'edit', 'String','Step Number:','Enable','off','Position', [40 145 70 30]);
handles.Edit_StepNum = uicontrol('Parent',guiFig, 'Style', 'edit', 'String','100','Enable','on','BackgroundColor',[1 1 1],'Position', [120 145 35 30]);

% XYZ panel
uicontrol('Parent',guiFig, 'Style', 'edit', 'String','X Position:','Enable','off','Position', [180 150 100 30]);
handles.Edit_XPos = uicontrol('Parent',guiFig, 'Style', 'edit', 'String','0','Enable','on','BackgroundColor',[1 1 1],'Position', [290 150 50 30],'Callback',@setxPos);
handles.Button_XForward=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Forward','Enable','on','Position', [350 150 65 30],'BackgroundColor',[0.5 0.5 .5],'Callback',@xForward);
handles.Button_XBackward=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Backward','Enable','on','Position', [420 150 65 30],'BackgroundColor',[0.5 0.5 0.5],'Callback',@xBackward);

uicontrol('Parent',guiFig, 'Style', 'edit', 'String','Y Position:','Enable','off','Position', [180 90 100 30]);
handles.Edit_YPos = uicontrol('Parent',guiFig, 'Style', 'edit', 'String','0','Enable','on','BackgroundColor',[1 1 1],'Position', [290 90 50 30],'Callback',@setyPos);
handles.Button_YForward=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Forward','Enable','on','Position', [350 90 65 30],'BackgroundColor',[0.5 0.5 .5],'Callback',@yForward);
handles.Button_YBackward=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Backward','Enable','on','Position', [420 90 65 30],'BackgroundColor',[0.5 0.5 0.5],'Callback',@yBackward);

uicontrol('Parent',guiFig, 'Style', 'edit', 'String','Z Position:','Enable','off','Position', [180 30 100 30]);
handles.Edit_ZPos = uicontrol('Parent',guiFig, 'Style', 'edit', 'String','0','Enable','on','BackgroundColor',[1 1 1],'Position', [290 30 50 30],'Callback',@setzPos);
handles.Button_ZForward=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Forward','Enable','on','Position', [350 30 65 30],'BackgroundColor',[0.5 0.5 .5],'Callback',@zForward);
handles.Button_ZBackward=uicontrol('Parent',guiFig, 'Style', 'pushbutton', 'String','Backward','Enable','on','Position', [420 30 65 30],'BackgroundColor',[0.5 0.5 0.5],'Callback',@zBackward);

% Setup GUI Values
properties2gui();



%% Figure Callbacks

    function centerXY(~,~)
        set(handles.Button_CenterXY, 'String','Moving ...','Enable','off','BackgroundColor',[0 1 0]);
        obj.centerXY();
        set(handles.Button_CenterXY, 'String','Center XY','Enable','on','BackgroundColor',[1 1 .8]);
        properties2gui();
    end

    function setZero(~,~)
        set(handles.Button_Zero, 'String','Moving ...','Enable','off','BackgroundColor',[0 1 0]);
        obj.setZero();
        set(handles.Button_Zero, 'String','Set Zero','Enable','on','BackgroundColor',[1 1 .8]);
        properties2gui();
    end

    function setxPos(~,~)
        xPos=str2double(get(handles.Edit_XPos,'String'));
        obj.setxPosition(xPos);
        properties2gui();
    end

    function xForward(~,~)
        StepNum=str2double(get(handles.Edit_StepNum,'String'));
        obj.movexUp(StepNum);
        properties2gui();
    end

    function xBackward(~,~)
        StepNum=str2double(get(handles.Edit_StepNum,'String'));
        obj.movexDown(StepNum);
        properties2gui();
    end

    function setyPos(~,~)
        yPos=str2double(get(handles.Edit_YPos,'String'));
        obj.setyPosition(yPos);
        properties2gui();
    end

    function yForward(~,~)
        StepNum=str2double(get(handles.Edit_StepNum,'String'));        
        obj.moveyUp(StepNum);
        properties2gui();
    end

    function yBackward(~,~)
        StepNum=str2double(get(handles.Edit_StepNum,'String'));
        obj.moveyDown(StepNum);
        properties2gui();
    end

    function setzPos(~,~)
        zPos=str2double(get(handles.Edit_ZPos,'String'));
        obj.setzPosition(zPos);
        properties2gui();
    end

    function zForward(~,~)
        StepNum=str2double(get(handles.Edit_StepNum,'String'));
        obj.movezUp(StepNum);
        properties2gui();
    end

    function zBackward(~,~)
        StepNum=str2double(get(handles.Edit_StepNum,'String'));
        obj.movezDown(StepNum);
        properties2gui();
    end

    function properties2gui()
        [xPos,yPos,zPos]=obj.getCurrentPosition();
        set(handles.Edit_XPos,'string',num2str(xPos));
        set(handles.Edit_YPos,'string',num2str(yPos));
        set(handles.Edit_ZPos,'string',num2str(zPos));
    end


end