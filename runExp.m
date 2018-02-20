% control+c to terminate 
% SetMouse to the center of the response wheel. 
% order -> r,w,n1,n2,n3
% conf from 6 to 4 levels 
% 4th -- tricky 
% high priority: size of EEG trace
% check the overlap 
% dual display --- Screen('openwindow') 
% after click, wait for the release of the mouse 
% while 1
%  [stat]=getmouse()
%    if state = released
%        break
%     end
% end 
% clear the screen
% add trial number (1/720) at the top of screen 
%
% ask Mu to change the EEG images 

% 1. add delay with screen refresh
% 2. add escape option to quit the task

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File created by: Jay Kim
% Date created: 2017-08-16
% Date modified: 2017-09-01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ****************************************************
% Before running this function: 
% 1. Change saveDir to save response data files. 
% 2. Change imageDir to where the images are saved. 
% ****************************************************


% ****************************************************
% Things to be done:
% 1. Make a function(s) for layouts; may need to change
%    variable names; make a struct and hand over the
%    struct maybe. 
% 2. May need choose which night is being used for the
%    experiment; the night ID/date might be reflected
%    in the directory name or file names - not sure. 
%    If reflected in dir/file names, use strcat or some
%    tool to filter by the names (might be a better way)
%    but I think I'd filter it this way. 
% (3. There are some redundant variables, because I 
%    made the 'trial' struct last-minute, and the 
%    redundant variables can be removed. I wouldn't do 
%    this though - it works well without delay. )
% ****************************************************

function runExp

runExp_init

%% Subject ID
% Copied from Julian's code
subj.initials = input('Enter subject initials:\n','s'); % 'JM'
subj.number = input('Enter block number, 01-99:\n','s'); % '99'
subj.level = input('Enter subject experience level (1,2 or 3):\n','s'); % 1-3
subj.dataset = input('Enter sleep subject dataset (1,5,7,13,14,..):\n')

%% Files and directories
% Define directories
saveDir = PARTICIPANT_RESULT_SAVE_DIR;
whichData = subj.dataset; %1,5,7,13,14
Dataname = strcat('ccshs_1800',num2str(whichData,'%03d'),'_1EEGv2/');
imageDir = strcat(IMAGE_DIR, Dataname);

% Read in image file names
disp('Creating trials...')
fileNames = dir(strcat(imageDir,'*.png')); % Later: need to select which night


% Create a random order
epochID = epochSampling(whichData); % whichData: 1,5,7,13,14


orderMat = [(1:length(epochID))',epochID']; % Col1: order in file Name; Col2: order being shown

nFiles = length(orderMat);

if nFiles == 0
    error
end
%% Window layout //Put into a separate file later //pretty much copied from Julian's code
% Window size (blank is full screen)
%Exp.Cfg.WinSize_ori = round(get(0, 'Screensize')*2/3); % Get rid of 2/3 later for full screen
Exp.Cfg.WinSize_ori = round(get(0, 'Screensize')); % Get rid of 2/3 later for full screen
Exp.Cfg.WinSize = Exp.Cfg.WinSize_ori;
Exp.Cfg.WinSize(3) = Exp.Cfg.WinSize(3)*0.95; % Did this to make room for 
    % confidence level colour legend bar; it was a last-min addition and 
    % didn't want to change a bunch of things (wanted to keep 1:1 ratio 
    % b/w EEG image + pentagon)--legend bar fits into the 5% of the entire
    % window on the RHS. Don't worry too much about this one. 
winHor = Exp.Cfg.WinSize(3); % Width of the window
winVert = Exp.Cfg.WinSize(4); % Height of the window

% Get screen info
Exp.Cfg.screens = Screen('Screens');

% Apparently (Julian) this makes things robust--I'm not sure what it is
if isunix
    % Exp.Cfg.screenNumber = min(Exp.Cfg.screens); % Attached monitor
    Exp.Cfg.screenNumber = max(Exp.Cfg.screens); % Main display
else
    % Exp.Cfg.screenNumber = max(Exp.Cfg.screens); % Attached monitor
    Exp.Cfg.screenNumber = min(Exp.Cfg.screens); % Main display
end

% Define colours
Exp.Cfg.Color.white = WhiteIndex(Exp.Cfg.screenNumber); % Define white colour
Exp.Cfg.Color.black = BlackIndex(Exp.Cfg.screenNumber); % Define black colour
Exp.Cfg.Color.gray = round((Exp.Cfg.Color.white+Exp.Cfg.Color.black)/2); % Define gray colour
backgroundColour = [177, 187, 217, 255]; % Background; pastel purple
lightYellow = [255,255,224, 150]; % Will use later for highlighting

% Open a new window
[Exp.Cfg.win, Exp.Cfg.windowRect] = Screen('OpenWindow', ...
	Exp.Cfg.screenNumber , Exp.Cfg.Color.gray, Exp.Cfg.WinSize_ori, [], 2, 0);

% Find window size
[Exp.Cfg.width, Exp.Cfg.height] = Screen('WindowSize', Exp.Cfg.win);

% Font
Screen('TextFont', Exp.Cfg.win, 'Arial');

% Blending mode (for transparency effect - for highlighting)
Screen('BlendFunction', Exp.Cfg.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%% Pentagon coordinates
% Number of partitions within pentagon structure
nPartition = 5; % 4 confidence levels + hollow centre

% Diameter of the outer pentagon
Exp.Cfg.rs = (winHor*2/5)*0.95; % Outermost diameter
pentDiameter = []; % Pentagon diameters; length = nPartition
for i = 1:nPartition
    pentDiameter = [pentDiameter, Exp.Cfg.rs*((nPartition-i+1)/nPartition)];
end
pentRad = pentDiameter/2; % pentagon radii

% Pentagon position; the right half of the window
buttonOffset_x = winHor/2; % Centre of the right half
buttonOffset_y = winVert*0.7; % Mid-height

% Pentagon coordinates
pentCoord_y = []; % y coords of pentagons; rows = diff pentagons; row 1 = largest
pentCoord_x = []; % x coords of pentagons; rows = diff pentagons; row nPartition = smallest
for i = 1:nPartition
    pentCoord_y = -[-pentCoord_y; pentRad(i), cos(2*pi/5)*pentRad(i), ...
        -cos(pi/5)*pentRad(i), -cos(pi/5)*pentRad(i), ...
        cos(2*pi/5)*pentRad(i), pentRad(i)]; % Functions for symmetrical pentagon
    pentCoord_x = [pentCoord_x; 0, sin(2*pi/5)*pentRad(i), ...
        sin(4*pi/5)*pentRad(i), -sin(4*pi/5)*pentRad(i), ...
        -sin(2*pi/5)*pentRad(i), 0]; % Functions for symmetrical pentagon
end
pentCoord_y = pentCoord_y + buttonOffset_y; % Offset to position on the RHS
pentCoord_x = pentCoord_x + buttonOffset_x; % Offset to position on the RHS


%% Background colour
% Set background colour
Screen('FillRect',  Exp.Cfg.win, backgroundColour); % Fill the whole window rectangle


%% Pentagon colours
% Colour in the pentagons (distinguish confidence levels)
pentColour = []; % Will be used for legend
for i = 1:nPartition-1
    pentColour = [pentColour, Exp.Cfg.Color.gray-(i-1)* ...
        (Exp.Cfg.Color.gray-Exp.Cfg.Color.white)/(nPartition-1)]; 
            % Record which grays were used for each pentagon; will use
            % later for the legend bar
    Screen('FillPoly', Exp.Cfg.win, pentColour(i), ...
        horzcat(pentCoord_x(i,:)', pentCoord_y(i,:)'));
            % Fill in the pentagons from large to small with darker
            % monochrome. 
end

% Fill the innermost pentagon in background colour to make it look hollow
Screen('FillPoly', Exp.Cfg.win, backgroundColour, ...
    horzcat(pentCoord_x(nPartition,:)', pentCoord_y(nPartition,:)'));


%% Pentagon outlines
% Draw button outlines
lineWidth = 1;
for i = 1:5
    % Pentagon outliine
    for j = 1:nPartition
        Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(j,i), ...
            pentCoord_y(j,i), pentCoord_x(j,i+1), pentCoord_y(j,i+1), lineWidth)
    end
    
    % Lines across pentagons
    Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(1,i), ...
        pentCoord_y(1,i), pentCoord_x(nPartition,i), pentCoord_y(nPartition,i), lineWidth)
end


%% Sleep class text on pentagon
% Sleep class text position coordinates; where to put sleep class texts
sleepClassTextPos_x = []; % x-coord
sleepClassTextPos_y = []; % y-coord
tmp_max = 0;
tmp_min = 0;
for i = 1:5 % 5 because there are 5 classes (pentagon)
    % Centre of second largest + smallest pentagon coordinates; x-coord
	tmp_max = max([pentCoord_x(2,i), pentCoord_x(2,i+1), ...
        pentCoord_x(nPartition,i), pentCoord_x(nPartition,i+1)]);
	tmp_min = min([pentCoord_x(2,i), pentCoord_x(2,i+1), ...
        pentCoord_x(nPartition,i), pentCoord_x(nPartition,i+1)]);
	sleepClassTextPos_x = [sleepClassTextPos_x; (tmp_max+tmp_min)/2];
	
    % Centre of second largest + smallest pentagon coordinates; x-coord
    tmp_max = max([pentCoord_y(2,i), pentCoord_y(2,i+1), ...
        pentCoord_y(nPartition,i), pentCoord_y(nPartition,i+1)]);
	tmp_min = min([pentCoord_y(2,i), pentCoord_y(2,i+1), ...
        pentCoord_y(nPartition,i), pentCoord_y(nPartition,i+1)]);
	sleepClassTextPos_y = [sleepClassTextPos_y; (tmp_max+tmp_min)/2];
end

% Put sleep class text
Screen('TextSize',Exp.Cfg.win, floor((Exp.Cfg.WinSize_ori(3)-...
    Exp.Cfg.WinSize(3))*0.4)); % Sleep class texts size
sleepClassTexts = {'Wake', 'N1', 'N2', 'N3', 'REM'}; % Sleep class texts
for i = 1:5 % 5 because there are 5 classes (pentagon)
	DrawFormattedText(Exp.Cfg.win, sleepClassTexts{i}, ... % Put texts
		sleepClassTextPos_x(i), sleepClassTextPos_y(i), [0 0 0]);
end


%% Legend bar for confidence level colours
% Position offsets for thelegend bar
legendPos_x = (Exp.Cfg.WinSize_ori(3)-Exp.Cfg.WinSize(3))*0.1+Exp.Cfg.WinSize(3); 
legendPos_y = Exp.Cfg.WinSize(4)*0.1;

% Use 80% of the window height for the legend bar
barLength = Exp.Cfg.WinSize(4)*0.8; 

% Use 80% of the width allocated (5% of window size) for the legend bar 
barWidth = (Exp.Cfg.WinSize_ori(3)-Exp.Cfg.WinSize(3))*0.8; 


for i = 1:nPartition-1
    % Divide up the legend bar and fill with confidence level colorus
    Screen('FillRect', Exp.Cfg.win, pentColour(i), ... 
        [legendPos_x, legendPos_y+barLength*((i-1)/(nPartition-1)), ...
        legendPos_x+barWidth, legendPos_y+barLength*(i/(nPartition-1))]);
    
    % Put confidence level numbers inside the legend bar
    DrawFormattedText(Exp.Cfg.win, int2str(nPartition-i), ... 
        legendPos_x+barWidth/3, legendPos_y+barLength*((i-0.3)/...
        (nPartition-1)), [0 0 0]);
end

% Texts above and below; 'Sure' and 'Not sure' //may need to fix
Screen('TextSize', Exp.Cfg.win, floor(barWidth/2));
DrawFormattedText(Exp.Cfg.win, 'Sure', legendPos_x, ...
    legendPos_y - 5*barWidth/8, [0 0 0]);
DrawFormattedText(Exp.Cfg.win, 'Not\nsure', legendPos_x, ...
    legendPos_y + barLength + barWidth/2, [0 0 0]);


%% Pentagon region divisions; which levels/classes does the click belong to?
% Confidence level mask
confidenceMask = []; % Using mask to later check which pentagon partition was clicked
for i = 1:nPartition
    confidenceMask{i} = poly2mask(pentCoord_x(i,:), pentCoord_y(i,:), ...
        Exp.Cfg.WinSize_ori(4),Exp.Cfg.WinSize_ori(3));
end
for i = 1:nPartition-1
    confidenceMask{i} = confidenceMask{i} - confidenceMask{i+1};
end

% Sleep classification coordinates
classCoord_x = [];
classCoord_y = [];
for i = 1:5 % 5 because there are 5 classes (pentagon)
    classCoord_x = [classCoord_x; pentCoord_x(1,i), pentCoord_x(1,i+1), ...
        pentCoord_x(nPartition,i+1), pentCoord_x(nPartition,i), pentCoord_x(1,i)];
    classCoord_y = [classCoord_y; pentCoord_y(1,i), pentCoord_y(1,i+1), ...
        pentCoord_y(nPartition,i+1), pentCoord_y(nPartition,i), pentCoord_y(1,i)];
end

% Sleep class mask
classMask = [];
for i = 1:5
    classMask{i} = poly2mask(classCoord_x(i,:), classCoord_y(i,:), ...
        Exp.Cfg.WinSize_ori(4),Exp.Cfg.WinSize_ori(3));
end


%% Run the experiment
% Size of displayed image
image_rect = [0, 0, winHor*19/20, floor(winHor*0.25)]; % Size of object images; ratio ok??
subjectResponse = [];

% Saving all the results in trial struct
% NB: I wasn't using this struct before, and some variables are redundant;
% i.e. I have other names for some of the things being saved in this struct
% such as file names, order of files presented, response and confidence. 
trial = []; % Subject trial results struct
    % trial.number = []; % Trial number
    % trial.fileName = []; % Name of the file presented in the trial
    % trial.fileID = []; % Alphabetical order of the file in the directory (may not need)
    % trial.tStart = []; % The time at which EEG image was presented
    % trial.tDuration = []; % Trial duration
    % trial.response = []; % Which sleep class was chosen
    % trial.confidence = []; % The confidence level

trialLabelRect = []; 

for m = 1:nFiles
    % Save trial number, file name and file ID
    trial(m).number = m;
    fprintf('%d',m)
    trial(m).fileName = fileNames(orderMat(m,2)).name;
    trial(m).fileID = orderMat(m,2);
    
    % Load the image in queue
    showImage = imread(strcat(imageDir,fileNames(orderMat(m,2)).name)); % Read image
    Probe_Tex = Screen('MakeTexture', Exp.Cfg.win, showImage);

    % Image position; centre of the left half
	imageOffset_x = winHor/2;
	imageOffset_y = (winVert)/6;
    showImageProbe = CenterRectOnPoint(image_rect, imageOffset_x, imageOffset_y);

    if m==1 % From the second image, we want ot update images a bit later
        % Draw correct images to screen
        Screen('DrawTextures', Exp.Cfg.win, Probe_Tex, [], showImageProbe, 0);
        
        % Display trial label
        if ~isempty(trialLabelRect)
            Screen('FillRect', Exp.Cfg.win, backgroundColour, trialLabelRect);    
        end

        [nx, ny, trialLabelRect] = DrawFormattedText(Exp.Cfg.win, ['Trial ' int2str(m) ' of ' int2str(nFiles)], ...
            winHor*0.85, winVert/2, [0 0 0]);

        % Present everything
        Screen('Flip',Exp.Cfg.win, [], 1);

        % Trial start time
        trial(m).tStart = GetSecs();
    end
    
    if m>1
        % Time delay
        WaitSecs(0.5);
        
        % ########################### make a pentagon layout func + call it
                % Colour in the pentagons
                pentColour = []; % Will be used for legend
                for i = 1:nPartition-1
                    pentColour = [pentColour, Exp.Cfg.Color.gray-(i-1)* ...
                        (Exp.Cfg.Color.gray-Exp.Cfg.Color.white)/(nPartition-1)];
                    Screen('FillPoly', Exp.Cfg.win, pentColour(i), ...
                        horzcat(pentCoord_x(i,:)', pentCoord_y(i,:)'));
                end
                Screen('FillPoly', Exp.Cfg.win, backgroundColour, ...
                    horzcat(pentCoord_x(nPartition,:)', pentCoord_y(nPartition,:)'));   
                % Draw lines
                for i = 1:5
                    % Pentagon outliine
                    for j = 1:nPartition
                        Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(j,i), ...
                            pentCoord_y(j,i), pentCoord_x(j,i+1), pentCoord_y(j,i+1), lineWidth)
                    end

                    % Lines across pentagons
                    Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(1,i), ...
                        pentCoord_y(1,i), pentCoord_x(nPartition,i), pentCoord_y(nPartition,i), lineWidth)
                end
                % Draw correct images to screen
                Screen('DrawTextures', Exp.Cfg.win, Probe_Tex, [], showImageProbe, 0);
                % Put sleep class text
                Screen('TextSize',Exp.Cfg.win, floor(barWidth/2));
                sleepClassTexts = {'Wake', 'N1', 'N2', 'N3', 'REM'}; % hard-coded
                for i = 1:5 % 5 because there are 5 classes (pentagon)
                    DrawFormattedText(Exp.Cfg.win, sleepClassTexts{i}, ...
                        sleepClassTextPos_x(i), sleepClassTextPos_y(i), [0 0 0]);
                end
                
                % Display trial label
                if ~isempty(trialLabelRect)
                    Screen('FillRect', Exp.Cfg.win, backgroundColour, trialLabelRect+1);    
                end

                [nx, ny, trialLabelRect] = DrawFormattedText(Exp.Cfg.win, ['Trial ' int2str(m) ' of ' int2str(nFiles)], ...
                    winHor*0.85, winVert/2, [0 0 0]);
                
                % Present everything
                Screen('Flip',Exp.Cfg.win, [], 1);
        % ############################################################# end

        % Trial start time
        trial(m).tStart = GetSecs();
        %save
    end
    
    save
    
    stay = 1;
    tmpMask = [];
    confidenceLevel = 0;
    sleepClass = 0;
    
    % added by Nao 17 Sep 7
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    if keyIsDown
        clear screen 
        save
        keyboard 
        return
    end
    
    while (stay)
        % The following code is adapted from https://github.com/Psychtoolbox-3/Psychtoolbox-3/blob/master/Psychtoolbox/PsychBasic/GetMouse.m
        % It waits for the combination of mouse click and release before
        % registering that it is a click.
        [click_x, click_y, buttons] = GetMouse(Exp.Cfg.win);
        while any(buttons) % if already down, wait for release
            [click_x, click_y, buttons] = GetMouse(Exp.Cfg.win);
        end
        while ~any(buttons) % wait for press
            [click_x, click_y, buttons] = GetMouse(Exp.Cfg.win);
        end
        while any(buttons) % wait for release
            [click_x, click_y, buttons] = GetMouse(Exp.Cfg.win);
        end        

        % If user reaches here, that means that have click and release the
        % mouse.
        if click_x<winHor && click_y<winVert && click_x>winHor/3 && ...
                click_y>1 % This is to prevent out-of-bound index error
            % Which confidence level
            for i = 1:(nPartition-1)
                if confidenceMask{i}(round(click_y), round(click_x))
                    confidenceLevel = i; % Trial confidence

                    % Trial confidence
                    trial(m).confidence = i;

                    % Which sleep class
                    for j = 1:5
                        if classMask{j}(round(click_y), round(click_x))==1
                            sleepClass = j; % Trial response

                            % Trial response
                            trial(m).response = j;                                

                            % Trial duration time
                            trial(m).tDuration = GetSecs()-trial(m).tStart;
                            disp(trial(m).tDuration);
                            break;
                        end
                    end
                    if sleepClass>0 % Was it clear which class was clicked?                            
                        % May move onto the next trial
                        stay = 0;

                        % Highlight the selection
                        Screen('FillPoly', Exp.Cfg.win, lightYellow, ...
                            [pentCoord_x(confidenceLevel,sleepClass), ...
                                pentCoord_y(confidenceLevel,sleepClass); ...
                                pentCoord_x(confidenceLevel,sleepClass+1), ...
                                pentCoord_y(confidenceLevel,sleepClass+1); ...
                                pentCoord_x(confidenceLevel+1,sleepClass+1), ...
                                pentCoord_y(confidenceLevel+1,sleepClass+1); ...
                                pentCoord_x(confidenceLevel+1,sleepClass), ...
                                pentCoord_y(confidenceLevel+1,sleepClass)]);
                        subjectResponse = [subjectResponse; ...
                            orderMat(m,2), confidenceLevel, sleepClass];
                        Screen('Flip',Exp.Cfg.win, [], 1);
                    end
                    break;
                end
            end
        end
    end 
    WaitSecs(0.5)
    save
    
end
Screen('Flip',Exp.Cfg.win, [], 1);
WaitSecs(0.5)
% Subject response
cd(saveDir)
save(strcat(subj.initials, '_', subj.number, '_', subj.level,'_',subj.dataset),'trial','subj');
disp('Save')
% ########################### make a pentagon layout func + call it
        % Colour in the pentagons
        pentColour = []; % Will be used for legend
        for i = 1:nPartition-1
            pentColour = [pentColour, Exp.Cfg.Color.gray-(i-1)* ...
                (Exp.Cfg.Color.gray-Exp.Cfg.Color.white)/(nPartition-1)];
            Screen('FillPoly', Exp.Cfg.win, pentColour(i), ...
                horzcat(pentCoord_x(i,:)', pentCoord_y(i,:)'));
        end
        Screen('FillPoly', Exp.Cfg.win, backgroundColour, ...
            horzcat(pentCoord_x(nPartition,:)', pentCoord_y(nPartition,:)'));   
        % Draw lines
        for i = 1:5
            % Pentagon outliine
            for j = 1:nPartition
                Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(j,i), ...
                    pentCoord_y(j,i), pentCoord_x(j,i+1), pentCoord_y(j,i+1), lineWidth)
            end

            % Lines across pentagons
            Screen('DrawLine', Exp.Cfg.win,Exp.Cfg.Color.black, pentCoord_x(1,i), ...
                pentCoord_y(1,i), pentCoord_x(nPartition,i), pentCoord_y(nPartition,i), lineWidth)
        end
        % Draw correct images to screen
        Screen('DrawTextures', Exp.Cfg.win, Probe_Tex, [], showImageProbe, 0);
        % Put sleep class text
        Screen('TextSize',Exp.Cfg.win, floor(barWidth/2));
        sleepClassTexts = {'Wake', 'REM', 'N1', 'N2', 'N3'}; % hard-coded
        for i = 1:5 % 5 because there are 5 classes (pentagon)
            DrawFormattedText(Exp.Cfg.win, sleepClassTexts{i}, ...
                sleepClassTextPos_x(i), sleepClassTextPos_y(i), [0 0 0]);
        end
        % Present everything
        Screen('Flip',Exp.Cfg.win, [], 1);
% ############################################################# end
disp('Pentagon')
       
%% Done screen //This causes sync error on my laptop
Screen('FillRect',  Exp.Cfg.win, backgroundColour);
DrawFormattedText(Exp.Cfg.win, 'Done :)', ...
				winHor/2, winVert/2, [0 0 0]);
Screen('Flip',Exp.Cfg.win, [], 1);
WaitSecs(1);
sca;

disp('Done')
%% Save all workspace variables
% Clear unnecessary variables
clearvars showImage confidenceMask classMask;

% % Subject response
% cd(saveDir)
% save(strcat(subj.number, '_', subj.initials, '_', subj.level),'trial','subj');
end

