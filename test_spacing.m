% --------
% Set-up
% --------
sca; 
close all;
clearvars;
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
backgroundGrey = WhiteIndex(screenNumber)/2;
EyelinkInit();

utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

% -----------------
% Fixed Params
% -----------------
% fixed timing info
nTrialsPerBlock = 120;
isiTime = 1.5; % pre-cue time
cueTime = 40/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
soaTime = 600/1000;
cuedLocProb = [.5 .5]; % probability of cue location
cueValidProb = 1;

% Ask for session number 
sessionNumber = input('Please enter session number ', 's');
mkdir(['results/' sessionNumber]);

% open ptb window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% base wait screen
waitMessage = '\n Press space bar to start';
Wait = WaitScreen(window, waitMessage, 70);

% -----------------
% Grating Threshold
% -----------------
% grating initializations
nGratingTrials = 100;
initSize = 1.5; % initial size of grating in degrees
stepSize = 0.1; % grating step size in degrees
nUp = 1; % number of wrong trials in a row to move up 
nDown = 3; % number of correct trials in a row to move down
cyclesPerGrating=4;

% psychometric fit initialization
pFitInit.t = 0.90;
pFitInit.b = 1;
pFitInit.a = 0.95;
pFitInit.g = 0.50;

% grating experiment
GratingExp = Experiment();
GratingBlock = GratingThreshTrial(window, windowRect, initSize, ... 
                stepSize, nUp, nDown, cyclesPerGrating, stimTime);        
WaitGrating = Wait;
WaitGrating.displayText = ['Grating Threshold Experiment' WaitGrating.displayText]; 
GratingExp.append_block("grating_wait_1", WaitGrating, 0);
GratingExp.append_block("grating_block_1", GratingBlock, nGratingTrials);
% GratingExp.run();
% % save the full block
% save(['results/' sessionNumber '/GratingThesholdExperiment.mat'], 'GratingExp')
% % save the results table
% gratingResults = GratingExp.save_run(['results/' sessionNumber '/grating_threshold_results.mat'], []);
threshDiameter = 1; %GratingBlock.get_size_thresh(pFitInit, gratingResults);

% all spacings 
spacingChoices = [Inf linspace(threshDiameter, 2.8, 11)];
spacingProb = ones(1, length(spacingChoices)) / length(spacingChoices);

% -----------------
% Build Modules
% -----------------
% Block with 1 flankers
Block1 = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spacingProb, spacingChoices, isiTime, cueTime, soaTime, stimTime);
Block1.diameter = threshDiameter;
Block1.spatialFrequency = cyclesPerGrating/threshDiameter;
Block1.nFlankers = 1;
Block1.set_flanker_params();
% Block with 2 flankers
Block2 = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spacingProb, spacingChoices, isiTime, cueTime, soaTime, stimTime);
Block2.diameter = threshDiameter;
Block2.spatialFrequency = cyclesPerGrating/threshDiameter;
Block2.nFlankers = 2;
Block2.set_flanker_params();

% ----------------
% Test Spacing Experiment
% ----------------
Exp = Experiment();
Exp.append_block("wait_1", Wait, 0)
Exp.append_block("block_1", Block1, nTrialsPerBlock)
Exp.append_block("wait_2", Wait, 0)
Exp.append_block("block_2", Block2, nTrialsPerBlock)
% run the experiment
Exp.run()
sca;
% save the full experiment 
save(['results/' sessionNumber '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run(['results/' sessionNumber '/experiment_results.mat'], []);
