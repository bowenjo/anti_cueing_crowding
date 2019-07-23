%----------
% Set up
%----------
% Run the following script to see various examples of how
% the block modules can be defined and how an entire experiment can be
% created and run from a combination of modules.

% Clear the workspace and the screen and set up
sca; 
close all;
clearvars;
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
backgroundGrey = WhiteIndex(screenNumber)/2;
EyelinkInit()

utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

%-------------
% Fixed Params
%-------------
% timing info
isiTime = 1; % pre-cue time
cueTime = 200/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
cuedLocProb = [.5 .5]; % probability of cue location

% open ptb window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

%-----------------------------------------
% Example Block 1: Informative/ long SOA
%-----------------------------------------
% Independent variables
soaTime = 600/1000; %600 ms
cueValidProb = .8; % probability the cue is valid
spaceCh = [Inf, 1.5]; % define your spacing choices in pixels
spaceProb = [1, 0]; % decide the proportion of each choice  

% initialize the block of trials module with the parameters
Block1 = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spaceProb, spaceCh, isiTime, cueTime, soaTime, stimTime);

%---------------------------------------------
% Example Block 2: Non-Informative/ short SOA
%---------------------------------------------
% Independent variables
soaTime = 40/1000; % 40ms
cueValidProb = .5; % probability the cue is valid
spaceCh = [Inf, 6.25]; % define your spacing choices in pixels
spaceProb = [.5, .5]; % decide the proportion of each choice 

% initialize the block of trials module
Block2 = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spaceProb, spaceCh, isiTime, cueTime, soaTime, stimTime);

%-------------------------
% Build full experiments
%-------------------------
% You can define as many blocks as you want with all different
% parameters above and append them to the full experiment. This will
% hopefully allow the design to be flexible if we want to change the
% ordering of the blocks, the number of trials, the proportions, etc.
Exp = Experiment();
% Build a waitscreen    
iMessage = 'Informative Block  \n \n press space bar to start';
nMessage = 'Non-Informative Block \n \n press space bar to start'; 
iWait = WaitScreen(window, iMessage, 70); 
nWait = WaitScreen(window, nMessage, 70);   
% Append blocks and corresponding number of trials 
Exp.append_block('1_wait', iWait, 0) 
Exp.append_block('2_block', Block1, 5) % Block 1: Informative/Long SOA for 5 trials
Exp.append_block('3_wait', nWait, 0) 
Exp.append_block('4_block', Block2, 5)  % Block 2: Non-informative/Short SOA for 5 trials
Exp.run() % run all blocks  
% dump the important results to a table for all trials in the experiment
results = Exp.save_run('results/test_save.mat');  
analyze_results(results)
sca; 



