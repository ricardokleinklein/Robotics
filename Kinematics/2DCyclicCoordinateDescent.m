function [] =  2DCCDRobot()
%--------------------------------------------------------------%
%                       Initialization                         %
%--------------------------------------------------------------%
close all
clc
clear 
fondo = [0.4 0.7 0.1]; % Color de fondo de la interfaz
greybackg = [0.95 0.95 0.95]; % Color de fondo gris
handles.boxL = []; %Interfaz
handles.nlinktext = [];% Interfaz
handles.joints = []; % Coordenadas de las articulaciones
%--------------------------------------------------------------%
%             Creation of the elements of the GUI                      
%--------------------------------------------------------------%
% Figure
handles.mainFigure = figure('units','normalized',...
    'position',[0 0 0.999 0.965],...
    'menubar','none',...
    'resize','on',...
    'NumberTitle','off',...
    'name','TRABAJO 2 - RICARDO FAUNDEZ-CARRASCO POBLACION - M15107 - 51140082L',...
    'color',fondo);
% User-program communication elements (grouped within a panel)
uipanel('units','normalized',...
    'position',[0.05 0.7 0.25 0.25],'FontWeight','bold',...
    'Title','Insert Robot Parameters','TitlePosition','centertop',...
    'BorderType','beveledin','HighlightColor','k','ShadowColor','k');
% Pop-up menu to choose the number of DOF
uicontrol('style','text','units','normalized','position',[0.07 0.88 0.04 0.025],...
    'string','Nº of DOF: ','back',greybackg);
handles.pop_ngdl = uicontrol('style','pop',...
    'units','normalized',...
    'position',[0.12 0.88 0.03 0.03],...
    'string',{'2','3','4','5','6','7'});
% Editbox to choose the tolerance of the method to converge
uicontrol('style','text','units','normalized','position',[0.07 0.83 0.04 0.025],...
    'string','Tolerance: ','back',greybackg);
handles.edit_tolerance = uicontrol('style','edit',...
    'units','normalized',...
    'position',[0.12 0.83 0.03 0.03],...
    'string','0.5');
% Radio buttons to choose between default and personalized length sizes
handles.radio_default = uicontrol('style','radio',...
    'units','normalized',...
    'position',[0.18 0.88 0.11 0.03],...,
    'Tag','Defrad',...
    'string','Default lengths ( Li = 10/N )','value',1);
handles.radio_personalized = uicontrol('style','radio',...
    'units','normalized',...
    'position',[0.18 0.83 0.11 0.03],...
    'Tag','Persrad',...
    'string','Personalized lengths');
set([handles.radio_default,handles.radio_personalized],'call',{@radios,handles});
set([handles.radio_personalized,handles.pop_ngdl],'call',{@edit_lengths,handles});
% Checkbox to see the path of the extremal
handles.check_path = uicontrol('style','check',...
    'units','normalized',...
    'position',[0.068 0.75 0.16 0.04],...
    'value',0,...
    'string','Plot path of the extreme of the robot');
%--------------------------------------------------------------%
%               Elements of the Axis interaction               % 
%--------------------------------------------------------------%
handles.points = []; % Holds the handles to the points
handles.CM = uicontextmenu;
handles.deletemenu = uimenu(handles.CM,...
    'label','Delete Points',...
    'callback',{@deletepuntos,handles});
%-------------------------------------------------------------%
%             Boxes with origin and goal positions            %
%-------------------------------------------------------------%
uicontrol('style','text','units','normalized','position',[0.52 0.19 0.08 0.03],...
    'FontSize',9,'string','ORIGIN','backg',[1 1 0.5]);
uicontrol('style','text','units','normalized','position',[0.52 0.16 0.08 0.03],...
    'FontSize',9,'string','   X       |       Y  ','backg',[0.3 0.3 0.9]);
handles.boxorigin(1) = uicontrol('style','edit','units','normalized',...
    'position',[0.52 0.13 0.04 0.03],'string','N/A');
handles.boxorigin(2) = uicontrol('style','edit','units','normalized',...
    'position',[0.56 0.13 0.04 0.03],'string','N/A');
uicontrol('style','text','units','normalized','position',[0.67 0.19 0.08 0.03],...
    'FontSize',9,'string','GOAL','backg',[0.5 1 1]);
uicontrol('style','text','units','normalized','position',[0.67 0.16 0.08 0.03],...
    'FontSize',9,'string','   X       |       Y  ','backg',[0.3 0.3 0.9]);
handles.boxgoal(1) = uicontrol('style','edit','units','normalized',...
    'position',[0.67 0.13 0.04 0.03],'string','N/A');
handles.boxgoal(2) = uicontrol('style','edit','units','normalized',...
    'position',[0.71 0.13 0.04 0.03],'string','N/A');
%-------------------------------------------------------------%
%            Axis where to point and see robot                %
%-------------------------------------------------------------%
handles.mainaxis = axes('units','normalized',...
    'position',[0.45 0.3 0.4 0.55],...
    'XTick',[-10 -8 -6 -4 -2 0 2 4 6 8 10],...
    'YTick',[-10 -8 -6 -4 -2 0 2 4 6 8 10]);
axis([-11 11 -11 11])
grid on
title('Planar robot')
set(handles.mainaxis,'buttondownfcn',{@ax_bdfcn,handles},'uicontextmenu',handles.CM);
guidata(handles.mainFigure,handles);


function[] = radios(varargin)
h = varargin{1};
handles = guidata(gcbo);
name = get(h,'Tag');
if strcmp(name(1),'D'),
    if get(h,'value') == 1,
        set(handles.radio_personalized,'value',0);
        if isempty(handles.boxL) ~= 1,
            delete(handles.boxL);
            delete(handles.nlinktext);
            handles.boxL = []; handles.nlinktext = [];
            guidata(gcbo,handles);
        end
    end
else
    if get(h,'value') == 1,
        set(handles.radio_default,'value',0);
    end
end
guidata(gcbo,handles)


function [] = ax_bdfcn(varargin)
% Serves as the buttondownfcn for the axes.
handles = guidata(gcbo);  % Get the structure.
seltype = get(handles.mainFigure,'selectiontype'); % Right-or-left click?
L = length(handles.points);
gdl = get(handles.pop_ngdl,'value')+1;
paso = 0;
if strcmp(seltype,'normal')
    p = get(handles.mainaxis, 'currentpoint'); % Get the position of the mouse.
    handles.points(L+1) = line(p(1),p(3),'Marker','x','Color','r');  % Make our plot.
    set(handles.points(L+1),'uicontextmenu',handles.CM)  % So user can click a point too.
    if L == 0,
        set(handles.boxorigin(1),'string',num2str(p(1)));
        set(handles.boxorigin(2),'string',num2str(p(3)));
        % COLOCAR AL ROBOT
        % Obtener las longitudes
        if get(handles.radio_default,'value') == 1,
            links = 10/gdl*ones(gdl+1,1);
        else
            % Coger longitudes variables, transformarlas y armar el brazo
            links = zeros(1,length(handles.boxL));
            for i = 1:length(handles.boxL),
               links(i+1) = 10*str2double(get(handles.boxL(i),'string')); 
            end
        end
        % Colocar el robot
        handles.joints(1,:) = [p(1) p(3)];
        for i = 2:gdl+1;
            handles.joints(i,1) = handles.joints(i-1,1) + links(i);
            handles.joints(i,2) = handles.joints(i-1,2);
        end
        hold on
        plot(handles.joints(:,1),handles.joints(:,2),'o-','LineWidth',2,'MarkerFaceColor','b')
        plot(handles.joints(1,1)+10*cos(0:0.01:2.01*pi),handles.joints(1,2)+10*sin(0:0.01:2.01*pi),'-.r') % Circulo alrededor
        axis([-11 11 -11 11])
        title('Planar robot')
    else
        set(handles.boxgoal(1),'string',num2str(p(1)));
        set(handles.boxgoal(2),'string',num2str(p(3)));
        % INTRODUCIR EL COMIENZO DEL CYCLIC COORDINATE DESCENT
        t = [p(1) p(3)];
        tolerancia = str2double(get(handles.edit_tolerance,'string'));
        X = handles.joints;
        error = dist(X(gdl+1,:),t');
        while error > tolerancia,
            for i = gdl:-1:1,
               e = X(gdl+1,:);
               j = X(i,:);
               a = (e-j)/norm(e-j);
               b = (t-j)/norm(t-j);
               theta = acosd(dot(a,b));
               dir = cross([a(1) a(2) 0],[b(1) b(2) 0]);
               if dir(3) < 0,
                   theta = -theta;
               end
               if theta > 15,
                   N = 10;
               else
                   N = 3;
               end
               for alpha = theta/N:theta/N:theta,
                   R = [cosd(theta/N) -sind(theta/N);sind(theta/N) cosd(theta/N)];
                   paso = paso + 1;
                   for k = gdl+1:-1:i+1,
                       ptoR = R*(X(k,:)-X(i,:))';
                       X(k,1) = ptoR(1) + X(i,1);
                       X(k,2) = ptoR(2) + X(i,2);
                   end
                   temp(paso,:) = X(gdl+1,:);
                plot(X(:,1),X(:,2),'o-','LineWidth',2,'MarkerFaceColor','b')
                grid on
                hold on
                title('Planar robot')
                plot([j(1) t(1)],[j(2) t(2)],'--g')
                plot([j(1) X(gdl+1,1)],[j(2) X(gdl+1,2)],'--k')
                plot(t(1),t(2),'xr')
                plot(handles.joints(1,1)+10*cos(0:0.01:2.01*pi),handles.joints(1,2)+10*sin(0:0.01:2.01*pi),'-.r') % Circulo alrededor
                if get(handles.check_path,'value') == 1,
                   plot(temp(:,1),temp(:,2),'k'); 
                end
                axis([-11 11 -11 11])
                hold off
                drawnow
               end
               error = dist(X(gdl+1,:),t');
            end
            handles.joints = X;
        end
    end
end
% Update structure.
set(handles.mainaxis,'ButtonDownFcn',{@ax_bdfcn,handles}); 
set(handles.deletemenu,'callback',{@deletepuntos,handles});
guidata(gcbo,handles)


function [] = deletepuntos(varargin)
% Callback for uimenu to delete the points.
handles = guidata(gcbo);  % Get the structure.
% delete(handles.points(:));  % Delete all the lines.
handles.points = [];  % And reset the structure. 
handles.joints = [];
cla % Clear plots
% Reset position boxes
set(handles.boxorigin(:),'string','N/A');
set(handles.boxgoal(:),'string','N/A');
set(handles.mainaxis,'ButtonDownFcn',{@ax_bdfcn,handles})
guidata(gcbo,handles)


function [] = edit_lengths(varargin)
handles = guidata(gcbo);
if (get(handles.radio_default,'value') == 1) && (get(handles.radio_personalized,'value') == 1),
    set(handles.radio_default,'value',0);
end
if get(handles.radio_personalized,'value') == 1,
    delete(handles.boxL);
    delete(handles.nlinktext);
    handles.boxL = [];
    handles.nlinktext = [];
    gdl = get(handles.pop_ngdl,'value')+1;
    for i = 1:gdl,
        handles.nlinktext(i) = uicontrol('style','text','units','normalized',...
            'position',[0.17 0.65-0.04*i 0.03 0.025],...
            'string',strcat('Link  ',num2str(i)),'back',[0.4 0.7 0.1]);
        handles.boxL(i) = uicontrol('style','edit','units','normalized',...
            'string','X %','position',[0.2 0.65-0.04*i 0.03 0.03]);
    end
else
    % Do nothing
end
guidata(gcbo,handles);
