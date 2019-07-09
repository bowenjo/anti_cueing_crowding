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
% timing info
isiTime = 1; % pre-cue time
cueTime = 200/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
cuedRectProb = [.5 .5]; % probability of cue location

% orientation information
orientProb = [.5 .5];
orientCh = [45 135];

%% Example Experiment 1: Informative/ long SOA
% Independent variables
soaTime = 600/1000; %600 ms
cueValidProb = .8; % probability the cue is valid
spaceCh = [100, 80]; % define your spacing choices in pixels
spaceProb = [1, 0]; % decide the proportion of each choice  

% Make the widow and get the rectangle postions
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% initialize the block of trials module with the parameters
Block1 = CueRects(window, windowRect, cuedRectProb, cueValidProb, ...
    spaceProb, orientProb, spaceCh, orientCh, ...
    isiTime, cueTime, soaTime, stimTime);

% Block1.run(10, 'block_1') % run 5 example trials from the block
sca;
% Block1.results
% Block1.expDesign('T_orient')

%% Example Experiment 2: Non-Informative/ short SOA
% Independent variables
soaTime = 40/1000; % 40ms
cueValidProb = .5; % probability the cue is valid
spaceCh = [100, 200]; % define your spacing choices in pixels
spaceProb = [.5, .5]; % decide the proportion of each choice (just doing one spacing for example purposes)

% Make the widow 
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% initialize the block of trials module
Block2 = CueRects(window,windowRect, cuedRectProb, cueValidProb, ...
    spaceProb, orientProb, spaceCh, orientCh, ...
    isiTime, cueTime, soaTime, stimTime);

% Block2.run(5) % run 5 example trials from the block
sca;

%% Build full experiments
% You can define as many blocks as you want with all different
% parameters above and append them to the full experiment. This will
% hopefully allow the design to be flexible if we want to change the
% ordering of the blocks, the number of trials, the proportions, etc.

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
Exp = Experiment();

% Build a waitscreen 
iMessage = 'Informative  \n press space bar to start';
nMessage = 'Non-Informative \n press space bar to start'; 
iWait = WaitScreen(window, iMessage, 70); 
nWait = WaitScreen(window, nMessage, 70);   
% append blocks and corresponding number of tri a ls 
Exp.append_block('1', iWait, 0) 
Exp.append_block('2', Block1, 10) % Block 1: Informative/Long SOA for 10 trials
Exp.append_block('3', nWait, 0) 
Exp.append_block('4', Block2, 10)  % Block 2: Non-informative/ Short SOA for 10 trials
Exp.run() % run all blocks   
sca; 
  
% TODOs: 
% need to decide when to check fixations DURING a trial
% Choose the fixed params correctly and change them in CuedRectParams

