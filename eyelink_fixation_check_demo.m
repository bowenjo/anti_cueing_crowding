% initialize psychtoolbox 
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
backgroundGrey = WhiteIndex(screenNumber)/2;

utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

% initialize the eyelink
expName = 'test_eyelink';
edfFile = [expName '.edf'];
EyelinkInit();

% open the psychtoolbox screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey, [0 0 640 480]);
[xCenter, yCenter] = RectCenter(windowRect); % center coordinates of the screen
[xRes, yRes] = Screen('WindowSize', window);
ifi = Screen('GetFlipInterval', window); % inter-frame interval for edfaccurate timing

% experiment parameters
fcv = CenterRectOnPoint([0 0 2 20], xCenter, yCenter); % vertical part of the cross 
fch = CenterRectOnPoint([0 0 20 2], xCenter, yCenter); % horizontal part of the cross
fixDiameter = 100; % radius of fixation threshold box in pixels
fixLoc = CenterRectOnPoint([0 0 fixDiameter fixDiameter], xCenter, yCenter);
fixBoxColors = [1 0 0; 0 1 0]; % color the fixation differently when fixated

% get the eyelink pointer 
el=EyelinkInitDefaults(window);
el.backgroundcolor = .5; % set the eyelink screen background color

% open the edf file to write to and set the tracker parameters
Eyelink('OpenFile', edfFile);
init_edf(expName, xRes, yRes);

% bring up the interactive set-up screen to calibrate, set pupil/corneal reflection
% thresholds, etc.
EyelinkDoTrackerSetup(el);

% run the experiment
Eyelink('StartRecording');
vbl = Screen('Flip', window);
respToBeMade = 1;
while respToBeMade
    % check fixation
    fix = check_fix(el, fixLoc);
    % draw fixation cross at center of the screen
    Screen('FillRect', window, .25, [fcv' fch']);
    Screen('FrameRect', window, fixBoxColors(fix+1,:), fixLoc, 2);
    DrawFormattedText(window, 'Hover eye/cursor over box to fixate', ...
        'center', .85*yRes, 1); 
    DrawFormattedText(window, 'Press q to exit', 'center', .90*yRes, 1);
    % flip the screen
    vbl = Screen('Flip', window, vbl + ifi/2);
    % get out by pressing q key
    [~, ~, keyCode] = KbCheck;
    if any(keyCode(KbName('Q')))
        respToBeMade = 0;
    end  
end

% stop recording, close and save edf file
Eyelink('StopRecording');
WaitSecs(0.1);
Eyelink('CloseFile');
WaitSecs(0.1);
Eyelink('ReceiveFile', edfFile, pwd, 1);
WaitSecs(0.2);
Eyelink('Shutdown')

sca;


