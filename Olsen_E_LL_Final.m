% Title: Apollo Simulator
% Date: November 10th, 2021
% Developer: Evan Olsen

% **HAVE SPEAKERS UP DURING GAME**
clc; clear; close all;
%% MOUSE POSITION AND KEYBOARD FUNCTION REGISTERING
[fig1] = createFigure();
global mousPos mousClick
mousPos = [0,0];
mousClick = false;
% Registers WindowButtonMotionFcn to allow figure window to track mouse
set(fig1, 'WindowButtonMotionFcn', @MouseMoveTracker)
% Registers WindowButtonDownFunction to allow figure to detect mouse click
set(fig1, 'WindowButtonDownFcn', @MouseClickListener)
% Registers WindowButtonUpFcn to allow figure to detect mouse button release
set(fig1, 'WindowButtonUpFcn', @MouseReleaseListener)
% Registers KeyDownListener to allow figure to detect key presses
set(fig1,'KeyPressFcn',@KeyDownListener)
global KeyID f T_max
%% MAIN CODE
% Setting Initial Values
m_f = 8300;               % Units: kilograms (kg)
m_o = 10300;              % Units: kilograms (kg)
m(1) = m_o;               % Units: kilograms (kg)
fuel(1) = m_o-m_f;        % Units: kilograms (kg)
m_sp = 3.28e-4;           % Units: kilograms per newton second (kg/s)/N
T_max = 45000;            % Units: newtons (N)
f = 0;                    % Units: percent (%)
theta = 0;                % Units: radians (rad)
x(1) = 100; y(1) = 500;   % Units: meters (m)
vx(1) = 40; vy(1) = -8;   % Units: meters per second (m/s)
ax(1) = 0; ay(1) = 0;     % Units: meters per square second (m/s^2)
t(1) = 0;                 % Units: seconds (s)
int = 0.05;               % Units: seconds (s)
n = 1;
% Title Sequence
title = text(.20,.8,'Apollo Simulator','Color','white','FontName',...
'Courier New','FontWeight','bold','FontSize',40);
start = text(.275,.75,'Press Enter to Start','Color',[.8 .8 .8],...
'FontName','Courier New','FontWeight','bold','FontSize',24);
directions = text(.05,.075,sprintf('Directions: Point your mouse to the direction you want to travel,\n        use "w" and "s" to increase and decrease thrust.'),...
'Color','white','FontName','Courier New','FontWeight','bold','FontSize',14);

KeyID = "space";
% Waits for user to hit return
while(KeyID ~= "return")
    pause(0.01);
end

% Audio Playback (Interstellar Theme)
filename = 'BGMusic.wav';
[audio,Fs] = audioread(filename);
player = audioplayer(audio,Fs);
play(player);
% Audio Playback for Crash
filename2 = 'Fail.wav';
[audio2,Fs2] = audioread(filename2);
player2 = audioplayer(audio2,Fs2);
% Audio Playback for Successful Landing ("...and for our next trick.")
filename3 = 'Success.wav';
[audio3,Fs3] = audioread(filename3);
player3 = audioplayer(audio3,Fs3);

% Calls to the plotLandscape() function which uses given points to plot the
% landscape for our lunar mission.
[Landscape_Scale,Landscape_Shape] = createLandscape();

% Calls to createLander() which firstly creates the patches and shapes 
% needed for our lander using given points.
[Lander_Shape,Lander_Patch,Door_Shape,Door_Patch,Square,Square_Patch,...
 Circle1,Circle1_Patch,Circle2,Circle2_Patch,Circle3,Circle3_Patch,...
 Circle4,Circle4_Patch,Circle5,Circle5_Patch,Circle6,Circle6_Patch,...
 Circle7,Circle7_Patch] = createLander();

% Calls to createText() which creates text to later be updated by current
% runtime data of position, velocity, acceleration, mass, etc. which are
% updated during the loop runtime.
[dispPosition] = createText();

% While loop 
while(mousClick == false)
    T = f*T_max; % Calculates current thrust
    
%    Calls to updateLander() which takes in initial or previous position,
%    velocity, acceleration, mass, and angle data and uses euler's method
%    to calculate the data for the next timestep. Function then takes the
%    calculated position data and updates the position of the lander patch
%    to reflect it.
    [vx,vy,ax,ay,m,m_dot,x,y,theta,View_Dist,Lander_Patch,Door_Patch,...
     Square_Patch,Circle1_Patch,Circle2_Patch,Circle3_Patch,Circle4_Patch,...
     Circle5_Patch,Circle6_Patch,Circle7_Patch] = updateLander(m,m_sp,...
     ax,ay,vx,vy,int,n,x,y,T,mousPos,Landscape_Scale,Lander_Shape,Lander_Patch,...
     Door_Shape,Door_Patch,Square,Square_Patch,Circle1,Circle1_Patch,...
     Circle2,Circle2_Patch,Circle3,Circle3_Patch,Circle4,Circle4_Patch,...
     Circle5,Circle5_Patch,Circle6,Circle6_Patch,Circle7,Circle7_Patch);
%   Sets game bounds
    if(x(n) < 3 || x(n) > 890)
        break;
    end
    [top_altitude(n),bottom_altitude(n),slope(n)] = calcAltitude(x(n),y(n),Landscape_Shape);
%   Calls to updateText() which tapes in current position data to update
%   the position of the text on the screen, and takes in any other data
%   which one would want to display on the figure window.
    fuel(n) = m(n) - m_f; % Calculates current fuel level
%   If there is no fuel left, thrust is set to 0N, and it ensures the
%   displayed fuel level is 0kg.
    if(fuel(n) <= 0)
        fuel(n) = 0;
        T_max = 0;
    end
    if(top_altitude(n) <= 0 || bottom_altitude(n) <= 0)
        bottom_altitude(n) = 0;
        break;
    end
    updateText(dispPosition,Landscape_Scale,ax(n),ay(n),vx(n),vy(n),x(n),y(n),bottom_altitude(n),fuel(n),T,View_Dist);
    
    
    t(n+1) = t(n) + int; % Increments time by int
    n = n + 1;           % Increments n
%   Pauses before next iteration (seconds)
    pause(int);
end
%   Determining Successful Landing
landingText = text(0,0,''); % Creates textbox to display Success or Crashed
if(vx(end) < 2 && vy(end) > -4 && vy(end) < 0 && abs(slope(end)) < 0.1 && theta < .1)
%   Success!
    set(landingText,'Position',[x(end)-25,y(end)+50],'String','Landed Successfully!','Color','green','FontName','Courier New','FontWeight','bold','FontSize',20);
    play(player3);
elseif(vx(end) < 6 && vy(end) > -8 && vy(end) < 0 && abs(slope(end)) < .2 && theta < .2)
%   Medium Crash
    set(landingText,'Position',[x(end)-10,y(end)+50],'String','Crashed!','Color','yellow','FontName','Courier New','FontWeight','bold','FontSize',20);
    play(player2);
else
%   Severe Crash
    set(landingText,'Position',[x(end)-10,y(end)+50],'String','Crashed!','Color','red','FontName','Courier New','FontWeight','bold','FontSize',20);
    play(player2);
end
stop(player); % Stops audio from playing
%% MOUSE AND KEY FUNCTIONS
function MouseMoveTracker(source, eventdata)
    global mousPos;
    mousPos = get(gca,'CurrentPoint');
end
function MouseClickListener(source, eventdata)
    global mousClick;
    mousClick = true;
end
function MouseReleaseListener(source, eventdata)
    global mousClick;
    mousClick = false;
end
function KeyDownListener(src,event)
    global KeyID f T_max curr_fuel
    KeyID = event.Key;
    
    f_inc = 0.02; % Increments the thrust by a certain fraction
    if(KeyID == 'w') % If user presses w, thrust is incremented
        if(f < 1)
            f = f + f_inc;
        end
    elseif(KeyID == 's') % If user presses s, thrust is decremented
        if(f > 0)
            f = f - f_inc;
        end
    end
end
%% OTHER FUNCTIONS
function [top_altitude,bottom_altitude,m] = calcAltitude(x,y,Landscape_Shape)
%   Seperates Landscape data into X and Y
    Landscape_X = Landscape_Shape(1,:);
    Landscape_Y = Landscape_Shape(2,:);
%   sets the initial minimum value
    min = abs(Landscape_X(1)-x);
    min_n = 0;
%   Loops through the vector to find the value closest to the current X
%   position
    for n=1:length(Landscape_X)
        if(abs(x - Landscape_X(n)) < min)
            min = abs(x - Landscape_X(n));
            min_n = n;
        end
    end
%   Branch structure calculates the slope of the landscape between the
%   lander and determines the y value directly below the lander
    if(Landscape_X(min_n) < x)
        m = (Landscape_Y(min_n+1)-Landscape_Y(min_n))/(Landscape_X(min_n+1)-Landscape_X(min_n));
        Landscape_Height = m*(x-Landscape_X(min_n))+Landscape_Y(min_n);
    elseif(Landscape_X(min_n) > x)
        m = (Landscape_Y(min_n)-Landscape_Y(min_n-1))/(Landscape_X(min_n)-Landscape_X(min_n-1));
        Landscape_Height = m*(Landscape_X(min_n)-x)+Landscape_Y(min_n-1);     
    else
        m = 0;
        Landscape_Height = Landscape_Y(min_n);
    end
%   Altitude from the top of the lander and from the bottom of the lander
%   are outputted
    top_altitude = y + 3.5 - Landscape_Height;
    bottom_altitude = y - 3.53 - Landscape_Height;
end
function [fig1] = createFigure()
    fig1 = figure('Name','Apollo Simulator','NumberTitle','off');
    
    Scale = 2;
    x = 100;        % Left side of figure
    y = 100;        % Bottom of figure
    w = 400*Scale;  % Width of figure
    h = 400*Scale;  % Height of figure
    
    set(fig1,'Position',[x,y,w,h],'Toolbar','none','Menubar','none');
    axes('Position',[0 0 1 1]);
    set(gca,'xtick',[],'ytick',[],'color','black');
    axis equal
end
function [Lander_Shape,Lander_Patch,Door_Shape,Door_Patch,Square,Square_Patch,Circle1,Circle1_Patch,Circle2,Circle2_Patch,Circle3,Circle3_Patch,Circle4,Circle4_Patch,Circle5,Circle5_Patch,Circle6,Circle6_Patch,Circle7,Circle7_Patch] = createLander()
    %% POINTS
    Lander_Shape = [-1.57 -1.44 -1.22 -0.86 -1.76 -2.03 -2.07 -1.97 -1.95 -2.05 -2.18 -2.35	-2.51 -2.61	-2.61 -2.53	-2.38 -2.18	-2.07 -1.87	-1.84 -1.93	-1.82 -1.62	-1.71 -1.78	-1.84 -1.84	-1.93 -2.12	-2.02 -1.93	-1.87 -2.07	-2.03 -1.86	-0.97 -1.18	-1.5 -1.66 -1.27 -1.22 -1.22 -1.57 -1.22 -1.22 -1.17 -1.04	-0.82	-0.57	-0.31	-0.31	-0.39	-0.42	-0.9	-1.08	-0.9	-0.42	-0.48	-0.9	-0.48	-0.52	-1.32	-0.52	-0.6	-1.04	-0.6	-0.63	-0.78	-1	-1.04	-1.17	-1.27	-1.32	-1.32	-1.3	-1.54	-1.54	-1.56	-1.6	-1.65	-1.68	-1.67	-1.64	-1.58	-1.56	-1.54	-1.54	-1.38	-1.29	-1.38	-1.38	-1.38	-1.54	-1.64	-1.38	-1.64	-1.7	-1.7	-1.67	-1.66	-1.77	-1.76	-1.73	-1.73	-1.84	-1.84	-1.95	-2.06	-2.06	-1.97	-1.84	-1.83	-1.73	-1.78	-1.78	-1.66	-1.65	-1.69	-1.59	-1.57	-1.59	-1.54	-1.3	-1.25	-1.22	-1.17	-1.08	-1.04	-0.82	-0.57	-0.31	-0.29	0.28	0.31	0.31	-0.31	-0.31	-0.17	-0.002	0.16	0.31	0.28	0.23	0.23	0.29	0.33	0.32	0.25	0.14	0.05	-0.04	-0.15	-0.24	-0.31	-0.32	-0.32	-0.28	-0.22	-0.22	-0.86	-0.22	-0.22	-0.22	-0.14	-0.02	0.12	0.23	0.23	0.84	1.09	1.25	1.22	1.31	1.18	1.31	1.4	1.4	1.4	1.45	1.56	1.5	1.65	1.5	1.4	1.42	1.4	1.3	1.3	1.3	1.25	1.09	1.3	1.35	1.39	1.58	1.58	1.37	1.35	1.58	1.58	1.7	1.64	1.64	1.78	1.78	1.75	1.81	1.81	1.96	2.04	2.04	1.94	1.82	1.82	1.73	1.79	1.79	1.67	1.67	1.69	1.53	1.3	1.32	1.32	1.3	1.53	1.53	1.55	1.6	1.64	1.67	1.67	1.66	1.61	1.56	1.53	1.53	1.3	1.22	1.14	1.02	0.87	0.65	0.33	0.02	-0.22	-0.48	-0.63	0.65	0.59	1.04	0.59	0.52	1.32	0.52	0.48	0.9	1.07	0.9	0.48	0.42	0.9	0.42	0.38	0.31	0.31	0.46	0.67	0.85	1	1.07	1.15	1.21	1.28	1.3	1.39	1.53	1.58	1.7	1.75	1.81	1.81	1.82	1.82	1.82	2.1	2.55	2.55	2.13	2.04	2.13	1.96	1.82	1.96	2.1	2.55	2.1	2.1	2.55	2.1	2	2.1	3.05	3	3.19	3.22	3.95	3.89	4.23	4.66	4.6	4.45	4.26	4.15	4	3.88	3.8	3.76	4.23	4.14	3.83	3.89	3.83	3.81	3.08	3.19	3.11	2.97	3	2.97	2.16	2.16	2.1	2.16	2.08	1.94	1.9	2.16	1.9	1.7	1.61	0.75	1.61	1.58	1.58	0.77	1.58	1.58	0.77	1.58	0.65	1.58	1.58	0.77	1.58	1.58	1.82	2.1	2.16	2.16	2.35	2.35	2.6	2.35	2.36	2.4	2.45	2.51	2.55	2.58	2.6	2.6	2.6	2.58	2.53	2.46	2.41	2.38	2.35	2.35	2.89	3.75	2.89	2.19	2.04	2.19	2.47	2.35	2.16	2.35	2.35	2.16	2.16	0.75	0.75	1.02	1.02	0.75	0.75	0.68	0.65	0.68	-0.63	-0.63	0.63	0.63	-0.69	-0.63	-0.69	-0.84	-0.63	-0.84	-1.58	-0.84	-1.36	-1.59	-1.36	-1.59	-1.36	-0.84	-1.34	-1.45	-1.34	-1.58	-1.34	-1.45	-1.38	-1.45	-1.58	-1.45	-1.58	-1.58	-1.82	-2.17	-2.01	-1.89	-1.73	-1.59	-1.58	-1.59	-1.59	-1.58	-1.58	-1.58	-1.58	-1.82	-2.11	-3.03	-2.97	-3.18	-3.21	-3.92	-3.88	-4.23	-4.65	-4.58	-4.45	-4.3	-4.1	-3.92	-3.81	-3.73	-4.23	-4.12	-3.81	-3.88	-3.81	-3.79	-3.09	-3.18	-3.11	-2.96	-2.97	-2.96	-2.3	-2.87	-3.72	-2.87	-2.17	-2.45	-2.17	-2.04	-2.17	-2.17	-2.17	-2.17	-1.93	-1.89	-1.73	-1.66	-1.04	-1.95	-1.95	-1.04	-1.04	-0.75	-0.75	-0.75	-0.75	-2.04	-1.84	-1.73	-1.59	-1.5	-1.45	-1.45	1.48	1.48	1.53	1.62	1.73	1.9	-0.75	0	0.86	0	-0.84	-0.75	-0.84	-0.97	0.98	0.34	0.28	0.28	0.28	-0.31	-0.31	-0.31	-0.34	-0.09	-0.09	0.08	0.08	0.28	-0.31	0.08	0.08	0.28	-0.31	0.08	0.08	0.28	-0.31	0.08	0.08	0.28	-0.31	0.08	0.08	0.28	-0.31	0.08	0.08	0.86	0.06	0.06	-0.06	-0.06	-0.84	-0.34	-0.57	-0.67	0.63	0.55	0.34	0.05	0.05	0.45	0.35	0.21	0.03	-0.03	-0.13	-0.3	-0.41	-0.46	0.05	-0.05	-0.05	-0.84	-0.75	-0.75	-0.69	-0.63	-0.48	-0.9	-1.08	-1.17	-1.22	-1.22	-1.57;
                     1.58	2.19	2.33	2.63	2.63	2.4	2.37	2.51	2.68	2.83	2.92	2.92	2.83	2.7	2.53	2.4	2.3	2.3	2.37	2.14	2.19	2.3	2.4	2.18	2.09	2.11	2.05	1.98	1.9	2.12	2.21	2.11	2.14	2.37	2.4	2.54	2.54	2.36	2.54	2.54	2.3	2.33	1.7	1.58	1.7	1.54	1.68	1.86	2.09	2.23	2.32	2.19	2.19	1.9	1.79	1.81	1.79	1.9	1.3	1.79	1.3	1	1	1	0.25	0.25	0.25	-0.11	-0.01	0.21	0.25	0.44	0.68	0.92	1.2	1.26	1.26	1.08	1.12	1.15	1.13	1.1	1.05	1.02	1.02	1.04	1.08	0.84	0.78	0.78	0.78	0.62	0.78	0.84	0.87	0.62	0.87	0.89	0.87	0.81	0.71	0.72	0.83	0.87	0.9	0.94	1.08	1.02	1.01	1.14	1.14	1.1	1.24	1.25	1.37	1.46	1.46	1.37	1.26	1.27	1.58	1.27	1.26	1.26	1.43	1.54	1.68	1.81	1.86	2.09	2.23	2.32	2.51	2.51	2.32	2.19	2.19	2.32	2.35	2.36	2.36	2.32	2.51	2.51	2.92	3	3.11	3.26	3.38	3.46	3.5	3.5	3.46	3.39	3.3	3.21	3.09	3	2.92	2.63	2.63	2.63	2.51	2.92	2.87	2.84	2.86	2.92	2.63	2.63	2.46	2.58	2.63	2.7	2.8	2.7	2.76	2.92	2.76	2.8	2.68	2.63	2.52	2.63	2.58	2.36	2.58	2.54	2.32	2.54	2.58	2.46	2.32	2.27	1.26	1.26	1.58	1.68	2.27	1.58	1.26	1.25	1.37	1.46	1.45	1.37	1.25	1.23	1.12	1.13	1.13	1.02	1.02	1.06	0.92	0.89	0.78	0.71	0.71	0.83	0.89	0.85	0.77	0.92	1.07	1.26	1.26	1.07	1.13	1.15	1.14	1.1	1.06	1.02	1.02	1.02	1.05	0.85	0.77	0.57	0.38	0.23	0.06	-0.11	-0.23	-0.26	-0.25	-0.17	-0.11	-0.11	0.25	0.25	0.25	1	1	1	1.32	1.79	1.79	1.79	1.32	1.89	1.79	1.89	2.19	2.19	2.32	2.28	2.18	2.05	1.9	1.79	1.69	1.56	1.35	1.26	1.26	1.26	1.26	1.25	1.25	1.23	1.12	1.06	0.92	0.7	-0.32	0.11	0.68	1.1	1.13	1.1	0.64	0.7	0.64	0.51	0.68	0.51	0.29	0.11	0.29	0.06	-0.32	-0.69	-0.81	-1.11	-1.09	-2.61	-2.64	-3.35	-3.35	-3.43	-3.5	-3.54	-3.54	-3.51	-3.46	-3.41	-3.35	-3.35	-3.35	-2.67	-2.64	-2.67	-2.69	-1.17	-1.11	-1.15	-0.84	-0.81	-0.84	-2.03	-0.34	-0.32	-0.52	-0.58	-0.61	-0.61	-0.86	-0.61	-0.59	-0.56	-0.86	-0.56	-0.53	-0.49	-0.35	-0.49	-0.34	-0.35	-0.34	-0.11	-0.34	0.57	-0.35	0.57	0.7	0.7	-0.32	-0.34	-1.6	-1.6	-1.27	-1.27	-1.27	-1.21	-1.16	-1.14	-1.14	-1.15	-1.19	-1.23	-1.27	-2.01	-2.05	-2.09	-2.1	-2.09	-2.06	-2.02	-1.86	-2.29	-2.56	-2.29	-2.29	-2.17	-2.29	-1.95	-1.86	-1.86	-1.86	-1.6	-1.6	-2.17	-2.17	-1.3	-1.3	-2.17	-2.17	-0.35	-0.35	-0.11	-0.35	-0.35	-0.51	-0.51	-0.35	-0.35	-0.11	-0.35	-0.35	-0.11	-0.35	-0.49	-0.35	-0.35	-0.18	-0.35	-0.35	-0.35	-0.35	0.27	-0.28	0.27	0.06	0.27	0.41	0.62	0.41	0.41	0.41	0.57	0.7	0.7	-0.56	-0.61	-0.62	-0.6	-0.54	-0.49	-0.35	-0.18	0.06	0.41	0.57	0.7	0.7	-0.35	-0.69	-0.81	-1.11	-1.09	-2.61	-2.63	-3.35	-3.35	-3.42	-3.49	-3.53	-3.53	-3.48	-3.42	-3.35	-3.35	-3.35	-2.67	-2.63	-2.67	-2.68	-1.18	-1.11	-1.16	-0.83	-0.81	-0.83	-1.83	-2.29	-2.54	-2.29	-2.29	-1.95	-2.29	-2.19	-2.19	-1.99	-0.37	-0.83	-0.62	-0.62	-0.6	-0.57	-0.76	-0.76	-1.91	-1.91	-0.76	-0.86	-0.35	-0.86	-2.17	-2.19	-2.18	-2.21	-2.26	-2.36	-2.48	-2.56	-2.56	-2.46	-2.35	-2.26	-2.19	-2.17	-2.17	-0.68	-2.38	-2.68	-2.38	-2.17	-2.38	-2.34	-2.34	-2.56	-2.56	-0.83	-0.94	-0.94	-0.83	-2.56	-2.56	-2.64	-0.94	-0.94	-1.2	-1.2	-1.2	-1.2	-1.47	-1.47	-1.47	-1.47	-1.73	-1.73	-1.73	-1.73	-1.99	-1.99	-1.99	-1.99	-2.25	-2.25	-2.25	-2.25	-2.65	-2.38	-0.79	-0.51	-0.51	-0.79	-2.38	-2.56	-2.56	-3.08	-3.08	-2.56	-2.56	-2.66	-3.35	-3.35	-3.44	-3.49	-3.53	-3.53	-3.51	-3.46	-3.39	-3.33	-3.33	-3.33	-2.66	-2.38	-2.17	-0.35	-0.35	-0.11	1.3	1.79	1.81	1.68	1.54	1.7	1.58];
    Door_Shape = [-0.39	0.38	0.42	0.42	0.38	-0.38	-0.42	-0.42	-0.39	-0.42	-0.37	0.34	0.42	0.38	-0.39;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	
                   0.87	0.87	0.83	0.21	0.15	0.15	0.2	0.83	0.87	0.91	1.11	1.11	0.91	0.87	0.87];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																													
    Circle1 = [-0.28	-0.25	-0.24	-0.24	-0.26	-0.29	-0.32	-0.32	-0.31	-0.28;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																						
                0.59	0.58	0.56	0.53	0.51	0.51	0.52	0.56	0.58	0.59];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	

    Circle2 = [-0.31	-0.27	-0.25	-0.25	-0.27	-0.31	-0.35	-0.38	-0.38	-0.34	-0.31;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																			
                1.31	1.3	1.28	1.22	1.2	1.19	1.2	1.23	1.27	1.3	1.31];
    Circle3 = [-0.31	-0.28	-0.26	-0.28	-0.31	-0.35	-0.35	-0.31																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																								
                1.58	1.58	1.55	1.51	1.5	1.52	1.56	1.58];
    Circle4 = [0.01	0.06	0.11	0.11	0.06	0.01	-0.06	-0.1	-0.12	-0.08	-0.03	0.01;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																		
               1.61	1.58	1.53	1.46	1.4	1.38	1.4	1.44	1.51	1.57	1.6	1.61];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	
    Circle5 = [0.3	0.34	0.35	0.34	0.31	0.28	0.27	0.28	0.3;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																				
               1.61	1.59	1.57	1.54	1.52	1.54	1.57	1.6	1.61];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																					
    Circle6 = [0.19	0.24	0.265	0.24	0.19	0.14	0.12	0.15	0.19;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																				
               2.02	2	1.96	1.91	1.9	1.92	1.99	2.02	2.02];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	
    Circle7 = [-2.28	-2.23	-2.2	-2.21	-2.24	-2.27	-2.32	-2.35	-2.35	-2.32	-2.28;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
                2.67	2.65	2.61	2.58	2.53	2.53	2.55	2.59	2.63	2.66	2.67];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																			
    Square = [-0.17	-0.08	0.07	0.17	0.09	0.09	0.17	0.07	-0.06	-0.17	-0.09	-0.09	-0.17;																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																	
               3.34	3.26	3.26	3.33	3.25	3.1	3	3.08	3.08	3	3.09	3.25	3.34];																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																
    %% PATCHES
    linewidth = 0.2;
    Lander_Patch  = patch(Lander_Shape(1,:),Lander_Shape(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Door_Patch    = patch(Door_Shape(1,:),Door_Shape(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle1_Patch = patch(Circle1(1,:),Circle1(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle2_Patch = patch(Circle2(1,:),Circle2(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle3_Patch = patch(Circle3(1,:),Circle3(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle4_Patch = patch(Circle4(1,:),Circle4(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle5_Patch = patch(Circle5(1,:),Circle5(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle6_Patch = patch(Circle6(1,:),Circle6(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Circle7_Patch = patch(Circle7(1,:),Circle7(2,:),'black','EdgeColor','white','LineWidth',linewidth);
    Square_Patch  = patch(Square(1,:),Square(2,:),'black','EdgeColor','white','LineWidth',linewidth);
end
function [Landscape_Scale,Landscape] = createLandscape()
    Landscape_Scale = 500;
    Landscape_Shape = [0	0.01	0.04	0.06	0.08	0.1	0.11	0.12	0.14	0.15	0.17	0.175	0.184	0.199	0.211	0.23	0.245	0.253	0.267	0.28	0.293	0.305	0.321	0.343	0.353	0.37	0.377	0.387	0.406	0.415	0.424	0.432	0.454	0.476	0.487	0.493	0.503	0.507	0.514	0.526	0.53	0.534	0.537	0.544	0.549	0.554	0.567	0.587	0.622	0.625	0.637	0.6448	0.653	0.645	0.653	0.659	0.666	0.703	0.706	0.712	0.7186	0.722	0.727	0.735	0.747	0.753	0.758	0.765	0.769	0.794	0.8	0.809	0.83	0.834	0.84	0.845	0.852	0.857	0.86	0.869	0.874	0.883	0.917	0.963	0.975	1	1.008	1.03	1.053	1.074	1.1	1.116	1.135	1.157	1.179	1.187	1.196	1.1995	1.203	1.21	1.214	1.219	1.222	1.225	1.229	1.234	1.238	1.253	1.258	1.265	1.272	1.272	1.284	1.29	1.306	1.309	1.313	1.316	1.319	1.331	1.337	1.34	1.347	1.356	1.363	1.369	1.376	1.378	1.384	1.388	1.39	1.397	1.403	1.412	1.423	1.434	1.447	1.452	1.459	1.464	1.494	1.497	1.503	1.515	1.52	1.525	1.527	1.541	1.553	1.557	1.568	1.578	1.587	1.594	1.5956	1.603	1.6096	1.621	1.644	1.666	1.671	1.688	1.697	1.702	1.706	1.719	1.732	1.74	1.749	1.755	1.759	1.771	1.777	1.784	1.79	1.798	1.802	1.816	1.821	1.83	1.839	1.848	1.862	1.877	1.884	1.909	1.918	1.924	1.949	1.956	1.962	1.966	1.973	1.97	0	0
                       ;0.69	0.7	0.71	0.7	0.69	0.69	0.68	0.69	0.7	0.71	0.71	0.702	0.699	0.699	0.705	0.72	0.73	0.731	0.728	0.72	0.717	0.713	0.711	0.714	0.722	0.733	0.733	0.74	0.756	0.763	0.771	0.776	0.792	0.806	0.816	0.828	0.845	0.851	0.858	0.868	0.866	0.86	0.857	0.847	0.838	0.828	0.789	0.736	0.603	0.584	0.556	0.536	0.51	0.536	0.511	0.49	0.473	0.358	0.347	0.338	0.328	0.325	0.316	0.305	0.285	0.275	0.266	0.256	0.25	0.225	0.214	0.198	0.154	0.15	0.142	0.134	0.123	0.118	0.117	0.112	0.106	0.105	0.094	0.094	0.101	0.101	0.096	0.087	0.087	0.084	0.0814	0.092	0.103	0.103	0.103	0.109	0.114	0.119	0.125	0.134	0.143	0.15	0.157	0.166	0.173	0.187	0.195	0.232	0.242	0.257	0.266	0.266	0.287	0.305	0.345	0.356	0.363	0.371	0.381	0.4	0.406	0.413	0.421	0.438	0.45	0.468	0.484	0.493	0.513	0.528	0.543	0.57	0.602	0.638	0.678	0.711	0.737	0.748	0.754	0.763	0.79	0.797	0.803	0.81	0.812	0.812	0.81	0.802	0.79	0.782	0.772	0.758	0.744	0.738	0.732	0.725	0.721	0.713	0.711	0.709	0.706	0.706	0.715	0.717	0.722	0.725	0.722	0.714	0.71	0.704	0.696	0.685	0.672	0.659	0.649	0.645	0.641	0.642	0.644	0.645	0.651	0.656	0.6603	0.656	0.653	0.652	0.65	0.646	0.647	0.653	0.656	0.66	0.663	0	0	0.686];
    Landscape_Shape2 = [Landscape_Shape(1,:);Landscape_Shape(2,:)-10/Landscape_Scale];
    Landscape_Shape3 = [Landscape_Shape(1,:);Landscape_Shape(2,:)-20/Landscape_Scale];
    Landscape_Shape4 = [Landscape_Shape(1,:);Landscape_Shape(2,:)-30/Landscape_Scale];
    Landscape = Landscape_Shape*Landscape_Scale;
    Landscape2 = Landscape_Shape2*Landscape_Scale;
    Landscape3 = Landscape_Shape3*Landscape_Scale;
    Landscape4 = Landscape_Shape4*Landscape_Scale;
    patch(Landscape(1,:),Landscape(2,:),[.5 .5 .5],'EdgeColor','white','LineWidth',0.75);
    patch(Landscape2(1,:),Landscape2(2,:),[.45 .45 .45],'EdgeColor',[.45 .45 .45]);
    patch(Landscape3(1,:),Landscape3(2,:),[.4 .4 .4],'EdgeColor',[.4 .4 .4]);
    patch(Landscape4(1,:),Landscape4(2,:),[.35 .35 .35],'EdgeColor',[.35 .35 .35]);
end
function [dispPosition] = createText()
    xpos = -100; ypos = -100;
    dispPosition = text(xpos,ypos,'','color','white','FontSize',12);
end
function [vx,vy,ax,ay,m,m_dot,x,y,theta,View_Dist,Lander_Patch,Door_Patch,...
          Square_Patch,Circle1_Patch,Circle2_Patch,Circle3_Patch,Circle4_Patch,...
          Circle5_Patch,Circle6_Patch,Circle7_Patch] = updateLander(m,m_sp,...
          ax,ay,vx,vy,int,n,x,y,T,mousPos,Landscape_Scale,Lander_Shape,...
          Lander_Patch,Door_Shape,Door_Patch,Square,Square_Patch,Circle1,...
          Circle1_Patch,Circle2,Circle2_Patch,Circle3,Circle3_Patch,Circle4,...
          Circle4_Patch,Circle5,Circle5_Patch,Circle6,Circle6_Patch,Circle7,Circle7_Patch)
    %% ANGLE CALCULATIONS
    %   Method to calculate angle creates a right triangle between the mouse
    %   cursor and the position of the ship. 

    %   Calculates the length x and y of said right triangle
    mouse_y = mousPos(1,2) - y(n);
    mouse_x = mousPos(1,1) - x(n);
    %   Calculates theta by taking the arctangent
    theta = atan(mouse_y/mouse_x);
    %   Calls detTheta() to correct for any miscalculations when using arctan
    %   Calculates correction for theta based on which quadrant the cursor lies
    %   in. This is because the values for theta can only be from 0-90 degrees.
    theta = detTheta(theta,mouse_x,mouse_y);
    %   Rotation matrix for any object one would want to rotate in a circular
    %   path.
    R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
    %   Uses matrix multiplication in order to calculate new points,
    %   and store those in the vector.
    LANDER_R = R*Lander_Shape;
    DOOR_R = R*Door_Shape;
    C1_R = R*Circle1;
    C2_R = R*Circle2;
    C3_R = R*Circle3;
    C4_R = R*Circle4;
    C5_R = R*Circle5;
    C6_R = R*Circle6;
    C7_R = R*Circle7;
    SQUARE_R = R*Square;
    %% POSITION CALCULATIONS
    % Constants
    g = 1.62;    % Acceleration Due to Gravity on the Moon (m/s^2)
    R = 1.738e6; % Radius of the moon (m)
    % Calculations
    m_dot(n) = T*m_sp;
    
    ay(n) = (T*cos(theta))/m(n) - (g - (vx(n)^2)/(R+y(n)));
    ax(n) = -(T*sin(theta))/m(n);
    
    x(n+1) = x(n) + vx(n)*int;
    y(n+1) = y(n) + vy(n)*int;
    
    vx(n+1) = vx(n) + ax(n)*int;
    vy(n+1) = vy(n) + ay(n)*int;
    m(n+1) = m(n) - m_dot(n)*int; % Calculates current mass
    %% UPDATES PATCH
    set(Lander_Patch,'XData',LANDER_R(1,:)+x(n),'YData',LANDER_R(2,:)+y(n));
    set(Door_Patch,'XData',DOOR_R(1,:)+x(n),'YData',DOOR_R(2,:)+y(n));
    set(Square_Patch,'XData',SQUARE_R(1,:)+x(n),'YData',SQUARE_R(2,:)+y(n));
    set(Circle1_Patch,'XData',C1_R(1,:)+x(n),'YData',C1_R(2,:)+y(n));
    set(Circle2_Patch,'XData',C2_R(1,:)+x(n),'YData',C2_R(2,:)+y(n));
    set(Circle3_Patch,'XData',C3_R(1,:)+x(n),'YData',C3_R(2,:)+y(n));
    set(Circle4_Patch,'XData',C4_R(1,:)+x(n),'YData',C4_R(2,:)+y(n));
    set(Circle5_Patch,'XData',C5_R(1,:)+x(n),'YData',C5_R(2,:)+y(n));
    set(Circle6_Patch,'XData',C6_R(1,:)+x(n),'YData',C6_R(2,:)+y(n));
    set(Circle7_Patch,'XData',C7_R(1,:)+x(n),'YData',C7_R(2,:)+y(n));
    %% UPDATES FRAME
    View_Dist = 75;
    setFrame(x(n),y(n),Landscape_Scale,View_Dist);
end
function [theta] = detTheta(theta,x,y)
    if(y > 0 && x > 0)
        theta = theta - pi/2;
    elseif(y > 0 && x < 0)
        theta = theta + pi/2;
    elseif(y < 0 && x > 0)
        theta = theta - pi/2;
    elseif(y < 0 && x < 0)
        theta = theta + pi/2;
    end
end
function setFrame(X,Y,Landscape_Scale,view_dist)
    max_dist = 1.793*Landscape_Scale;
    if(X >= view_dist && Y >= view_dist && X < max_dist - view_dist)
        xlim([X-view_dist,X+view_dist])
        ylim([Y-view_dist,Y+view_dist])
    elseif(X >= view_dist && Y < view_dist && X < max_dist-view_dist)
        xlim([X-view_dist,X+view_dist])
        ylim([0,view_dist*2])
    elseif(X < view_dist && Y >= view_dist)
        xlim([0,view_dist*2])
        ylim([Y-view_dist,Y+view_dist])
    elseif(X < view_dist && Y < view_dist)
        xlim([0,view_dist*2])
        ylim([0,view_dist*2])
    elseif(X >= view_dist && Y >= view_dist && X >= max_dist-view_dist)
        xlim([max_dist - view_dist*2, max_dist])
        ylim([Y-view_dist,Y+view_dist])
    elseif(X >= view_dist && Y < view_dist && X >= max_dist-view_dist)
        xlim([max_dist - view_dist*2, max_dist])
        ylim([0,view_dist*2])
    end
end
function [] = updateText(dispPosition,Landscape_Scale,ax,ay,vx,vy,X,Y,altitude,fuel,thrust,View_Dist)
%   Grabs the correct position of the text based on if the lunar lander is
%   near the edge of the map or not.
    textFrame = getFrame(X,Y,Landscape_Scale,View_Dist);
%   Updates our text handle with the new text position and new positional data
    set(dispPosition,'Position',textFrame,'String',sprintf('ALTITUDE:%7.2fm                                     a_x:%5.2fm/s^2 a_y:%5.2fm/s^2\nTHRUST: %8.0fN                                     v_x:%5.2fm/s  v_y:%5.2fm/s\nFUEL: %9.2fkg',altitude,ax,ay,thrust,vx,vy,fuel),'FontName','Courier New','FontWeight','bold')
end
function [textFrame] = getFrame(X,Y,Landscape_Scale,View_Dist)
    max_dist = 896.5; % Based on Landscape_Scale*1.793
    textFrame = [-100,-100];
    xinc = 145;
    yinc = 10;
    if(X >= View_Dist && Y >= View_Dist && X < max_dist - View_Dist)
        textFrame = [X+View_Dist-xinc,Y+View_Dist-yinc];
    elseif(X >= View_Dist && Y < View_Dist && X < max_dist-View_Dist)
        textFrame = [X+View_Dist-xinc,View_Dist*2-yinc];
    elseif(X < View_Dist && Y >= View_Dist)
        textFrame = [View_Dist*2-xinc,Y+View_Dist-yinc];
    elseif(X < View_Dist && Y < View_Dist)         
        textFrame = [View_Dist*2-xinc,View_Dist*2-yinc];     
    elseif(X >= View_Dist && Y >= View_Dist && X >= max_dist-View_Dist)
        textFrame = [max_dist-xinc,Y+View_Dist-yinc];
    elseif(X >= View_Dist && Y < View_Dist && X >= max_dist-View_Dist)
        textFrame = [max_dist-xinc,View_Dist*2-yinc];
    end
end




