%% Set up
% Run the following cells one at a time to see the various examples of how
% the block modules can be defined and how a entire experiment can be
% created and run from a combination of modules.

% Clear the workspace and the screen
sca; 
close all;
clearvars;
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
backgroundGrey = white / 2;

utilsPath = [pwd '/utils'];
addpath(utilsPath)

%% Fixed Params
cuedGrey = black;
nonCuedGrey = white;

% buld rectangles
baseRect = [0 0 400 200]; % base rectangle size in pixels

% timing info
isiTime = 1; % pre-cue time
cueTime = 200/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time

% rectangle cueing information
postCuedRect = [2 1]; % post cue rectangle indices to present stimulus when valid
cuedRectProb = [.5 .5]; % probability of cue location
cueLineSize = 6;
lineSize = 2;

% orientation information
orientProb = [.5 .5];
orientCh = [45 135];

% grating info
spatialFrequency = .03;
diameter = 80;
contrast = 1;


%% Example Experiment 1: Informative/ long SOA
% Independent variables
soaTime = 600/1000; %600 ms
cueValidProb = .8; % probability the cue is valid
spaceCh = [100, 80]; % define your spacing choices in pixels
spaceProb = [1, 0]; % decide the proportion of each choice  

% Make the widow and get the rectangle postions
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
squareXpos = [.25 .75] .* screenXpixels;
squareYpos = [.5 .5] .* screenYpixels;

% initialize the block of trials module with the parameters
Block1 = CueRects(window,windowRect, baseRect, squareXpos, squareYpos, cuedGrey,...
    nonCuedGrey, cueLineSize, lineSize, postCuedRect, cuedRectProb, cueValidProb, ...
    spaceProb, orientProb, spaceCh, orientCh, ...
    spatialFrequency, diameter, contrast, ...
    isiTime, cueTime, soaTime, stimTime);

Block1.run(5) % run 5 example trials from the block
sca;

%% Example Experiment 2: Non-Informative/ short SOA
% Independent variables
soaTime = 40/1000; % 40ms
cueValidProb = .5; % probability the cue is valid
spaceCh = [100, 200]; % define your spacing choices in pixels
spaceProb = [.5, .5]; % decide the proportion of each choice (just doing one spacing for example purposes)

% Make the widow 
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% initialize the block of trials module
Block2 = CueRects(window, windowRect, baseRect, squareXpos, squareYpos, cuedGrey,...
    nonCuedGrey, cueLineSize, lineSize, postCuedRect, cuedRectProb, cueValidProb, ...
    spaceProb, orientProb, spaceCh, orientCh, ...
    spatialFrequency, diameter, contrast, ...
    isiTime, cueTime, soaTime, stimTime);

Block2.run(5) % run 5 example trials from the block
sca;

%% Build full experiments
% You can define as many blocks as you want with all different
% parameters above and append them to the full experiment. This will
% hopefully allow the design to be flexible if we want to change the
% ordering of the blocks, the number of trials, the proportions, etc.

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
Exp = Experiment();
% append blocks and corresponding number of trials
Exp.append_block('1', Block1, 10) % Block 1: Informative/Long SOA for 10 trials
Exp.append_block('2', Block2, 10) % Block 2: Non-informative/ Short SOA for 10 trials
Exp.run() % run all blocks

sca;

% NOTES:
% The sizes are not the ones we'll use in the experiments. I just chose
% these ones because I do not know what they should be yet cause I haven't
% looked at the monitor in the eye-tracking room.

% TODOs:
% 1) Still need to add code to obtain and measure subject responses.
% 2) Need to add in instruction/break screens between blocks
% 3) Need to add in eye-tracking stuff 

