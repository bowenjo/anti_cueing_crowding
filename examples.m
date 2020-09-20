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
cueTime = 40/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
cuedLocProb = [.5 .5]; % probability of cue location (i.e. 50% each side)
diameter = 1.5; % size of the grating
% open ptb window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

%-----------------------------------------
% Example Grating Size Staircase Block
%-----------------------------------------
initSize = 3; % initial grating size for staircase
stepSize = .20; % step size in dva
nUp = 1; % number of trials in a row wrong to move up
nDown = 2; % number of trials in a row correct to move down
fixColors = [.25; .25; .25; .25];
displaySide = [0 1];


GratingBlock = GratingThreshTrial(window, windowRect, "grating_size", initSize, ... 
                stepSize, nUp, nDown, fixColors, stimTime, displaySide, false);
            
%-----------------------------------------
% Example Block 1: Long SOA
%-----------------------------------------
% Independent variables
soaTime = 600/1000 - cueTime; %600 ms
cueValidProb = .8; % probability the cue is valid
spaceCh = [6.25, 6.25]; % define your spacing choices in dva
spaceProb = [.5, .5]; % decide the proportion of each choice  

% initialize the block of trials module with the parameters
Block1 = CueTrial(window, windowRect, diameter, cuedLocProb, cueValidProb, ...
    spaceProb, spaceCh, isiTime, cueTime, soaTime, stimTime);

%---------------------------------------------
% Example Block 2: Short SOA
%---------------------------------------------
% Independent variables
soaTime = 40/1000 - cueTime; % 40ms
cueValidProb = .8; % probability the cue is valid 
spaceCh = [Inf, 6.25]; % define your spacing choices in dva
spaceProb = [.5, .5]; % decide the proportion of each choice 

% initialize the block of trials module
Block2 = CueTrial(window, windowRect, diameter, cuedLocProb, cueValidProb, ...
    spaceProb, spaceCh, isiTime, cueTime, soaTime, stimTime);

% ---------------------------------------------
% Example Ensemble Mean Block
% ---------------------------------------------
soaTime = 40/1000 - cueTime;
cueValidProb = .5;
spacing = 3; % fixed spacing
cueSizeCh = [diameter, 2*spacing + diameter]; % cue size choices target/target+flankers
cueSizeProb = [.5 .5];
ensembleMeanCh = [0 45 90]; %parallel/neutral/orthogonal conditions
ensembleMeanProb = [1/3 1/3 1/3];
sigma = 1;

% initialize the block of trials
EnsembleBlock = CueEnsembleTrial(window, windowRect, diameter, spacing, ...
    cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ensembleMeanProb, ...
    ensembleMeanCh, sigma, isiTime, cueTime, soaTime, stimTime);
EnsembleBlock.nFlankers = 9;
EnsembleBlock.nFlankerRepeats = 1;
EnsembleBlock.cueType = 'circle';
EnsembleBlock.nonCueLum = 0.5;

%-------------------------
% Build full experiments
%-------------------------
% You can define as many blocks as you want with all different
% parameters above and append them to the full experiment. This will
% hopefully allow the design to be flexible if we want to change the
% ordering of the blocks, the number of trials, the proportions, etc.
Exp = Experiment();
% Build a waitscreen   
gMessage = 'Grating Size Staircase \n \n press space bar to start';
lMessage = 'Long SOA Block  \n \n press space bar to start';
sMessage = 'Short SOA Block \n \n press space bar to start';
eMessage = 'Ensemble Block \n \n press space bar to start';
gWait = WaitScreen(window, windowRect, gMessage, 70, []);
lWait = WaitScreen(window, windowRect, lMessage, 70, []); 
sWait = WaitScreen(window, windowRect, sMessage, 70, []);   
eWait = WaitScreen(window, windowRect, eMessage, 70, []);
% Append blocks and corresponding number of trials 
Exp.append_block("wait_1", gWait, 0)
Exp.append_block("block_1", GratingBlock, 5); % grating staircase for 10 trials
Exp.append_block('wait_2', lWait, 0) 
Exp.append_block('block_2', Block1, 5) % Block 1: Long SOA for 5 trials
Exp.append_block('wait_3', sWait, 0) 
Exp.append_block('block_3', Block2, 5)  % Block 2: Short SOA for 5 trials
Exp.append_block('wait_4', eWait, 0)
Exp.append_block('block_4', EnsembleBlock, 20)
Exp.run([], '') % run all blocks 
sca;

% dump the important results to a struct for all trials in the experiment
blockIndices = fields(Exp.blocks)';
grating_size_results = Exp.save_run('', blockIndices(1:2)); % save the grating staircase experiments
cueing_results = Exp.save_run('', blockIndices(3:6)); % save the cueing experiments
ensemble_results = Exp.save_run('', blockIndices(7:8)); % save the ensemble experiment







