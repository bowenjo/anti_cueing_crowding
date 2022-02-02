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
isiTime = 1.2; % pre-cue time
cueTime = 40/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
cuedLocProb = [.5 .5]; % probability of cue location (i.e. 50% each side of screen)
diameter = 1.25; % size of the gratings in degrees

% open ptb window
% PsychImaging('PrepareConfiguration')
% PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma')
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
% PsychColorCorrection('SetEncodingGamma', window, [1.3694, 1.1958, 1.0250])

%-----------------------------------------
% Example Grating Size Staircase Block
%-----------------------------------------
initSize = 3; % initial grating size for staircase
stepSize = .20; % step size in dva
nUp = 1; % number of trials in a row wrong to move up
nDown = 2; % number of trials in a row correct to move down
fixColors = [.25; .25; .25; .25];
displaySide = [0 1]; 

% initialize the block of trials module
GratingBlock = GratingThreshTrial(window, windowRect, "grating_size", initSize, ... 
                stepSize, nUp, nDown, fixColors, stimTime, displaySide, false);
            
GratingBlock.nFlankers = 2;
GratingBlock.nFlankerRepeats = 2;
GratingBlock.cueType = 'vline';
GratingBlock.nonCueLum =.25;

%-----------------------------------------
% Example Block 1: Long SOA
%-----------------------------------------
% Independent variables
soaTime = 600/1000; % 600 ms
cueValidProb = .8; % probability the cue is valid
spaceCh = [Inf, 6.25]; % define your spacing choices in dva
spaceProb = [.5, .5]; % decide the proportion of each choice  

% initialize the block of trials module with the parameters
Block1 = CueTrial(window, windowRect, diameter, cuedLocProb, cueValidProb, ...
    spaceProb, spaceCh, isiTime, cueTime, soaTime, stimTime);

Block1.nFlankers = 2;
Block1.nFlankerRepeats = 2;
Block1.cueType = 'vline';
Block1.nonCueLum =.25;

%---------------------------------------------
% Example Block 2: Short SOA
%---------------------------------------------
% Independent variables
soaTime = 40/1000; % 40ms
cueValidProb = .8; % probability the cue is valid 
spaceCh = [Inf, 6.25]; % define your spacing choices in dva
spaceProb = [.5, .5]; % decide the proportion of each choice 

% initialize the block of trials module
Block2 = CueTrial(window, windowRect, diameter, cuedLocProb, cueValidProb, ...
    spaceProb, spaceCh, isiTime, cueTime, soaTime, stimTime);

Block2.nFlankers = 2;
Block2.nFlankerRepeats = 2;
Block2.cueType = 'vline';
Block2.nonCueLum =.25;

% ---------------------------------------------
% Example Ensemble Mean Block
% ---------------------------------------------
soaTime = 40/1000;
cueValidProb = .5;
spacing = 5; % fixed spacing
cueSizeCh = [diameter, 2*spacing + diameter]; % cue size choices target/target+flankers
cueSizeProb = [.5 .5];
ensembleMeanCh = [0 45 90]; %parallel/neutral/orthogonal conditions
ensembleMeanProb = ones(1,3)/3; %[0 0 1];
sigma = 45; 
taskType = "target"; 

% initialize the block of trials
EnsembleBlock = CueEnsembleTrial(window, windowRect, diameter, spacing, ...
    cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ensembleMeanProb, ...
    ensembleMeanCh, sigma, taskType, isiTime, cueTime, soaTime, stimTime);
EnsembleBlock.nFlankers = 9;
EnsembleBlock.nFlankerRepeats = 1;
EnsembleBlock.cueType = 'texture';
EnsembleBlock.nonCueLum = 0.5;


% ---------------------------------------------
% Example Uniform Ensemble Mean Block
% ---------------------------------------------
soaTime = 40/1000 ;
cueValidProb = .5;
spacing = 5; % fixed spacing
cueSizeCh = [diameter, 4*spacing + diameter]; % cue size choices target/target+flankers
cueSizeProb = [.5 .5];
ensembleMeanCh = [0 45 90]; %parallel/neutral/orthogonal conditions
ensembleMeanProb = ones(1,3)/3 ; 
targetLocCh = [6, 7, 10, 11];
targetLocProb = [.25, .25, .25, .25];
sigma = 45; 


% initialize the block of trials
UniformBlock = CueEnsembleUniformTrial(window, windowRect, diameter, spacing, ...
    cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ensembleMeanProb, ...
    ensembleMeanCh, targetLocProb, targetLocCh, sigma, ...
    isiTime, cueTime, soaTime, stimTime);
UniformBlock.nFlankers = 4; 
UniformBlock.nFlankerRepeats = 1;
UniformBlock.cueType = 'texture';
UniformBlock.nonCueLum = 0.5;


%-------------------------
% Build full experiments
%-------------------------
% You can define as many blocks as you want with all different
% parameters above and append them to the full experiment. This will
% hopefully allow the design to be flexible if you want to change the
% ordering of the blocks, the number of trials, the proportions, etc.
Exp = Experiment();
% Build a waitscreen   
gMessage = 'Grating Size Staircase \n \n press space bar to start';
lMessage = 'Long SOA Block  \n \n press space bar to start';
sMessage = 'Short SOA Block \n \n press space bar to start';
eMessage = 'Ensemble Block \n \n press space bar to start';
uMessage = 'Uniform Ensemble Block \n \n press space bar to start';
gWait = WaitScreen(window, windowRect, gMessage, 70, []);
lWait = WaitScreen(window, windowRect, lMessage, 70, []); 
sWait = WaitScreen(window, windowRect, sMessage, 70, []);   
eWait = WaitScreen(window, windowRect, eMessage, 70, []);
uWait = WaitScreen(window, windowRect, uMessage, 70, []);
% Append blocks and corresponding number of trials 
Exp.append_block('wait_1', gWait, 0)
Exp.append_block('staircase', GratingBlock, 20); % grating staircase for 10 trials
Exp.append_block('wait_2', lWait, 0) 
Exp.append_block('long_soa', Block1, 5) % Block 1: Long SOA for 5 trials
Exp.append_block('wait_3', sWait, 0) 
Exp.append_block('short_soa', Block2, 5)  % Block 2: Short SOA for 5 trials
Exp.append_block('wait_4', eWait, 0)
Exp.append_block('ensemble', EnsembleBlock, 20)
Exp.append_block('wait_5', uWait, 0)
Exp.append_block('uniform', UniformBlock, 20)
Exp.run([], '') % run all blocks 
sca;

% Dump the important results to a struct for relevant trials in the
% experiment. Block results can be combined together if the block modules
% are of the same type. 
staircase_results = Exp.save_run('', {'staircase'}); % save the staircase results
cueing_results = Exp.save_run('', {'long_soa','short_soa'}); % save the cueing experiments
ensemble_results = Exp.save_run('', {'ensemble'}); % save the ensemble experiment
uniform_results = Exp.save_run('', {'uniform'}); % save the uniform experiment

