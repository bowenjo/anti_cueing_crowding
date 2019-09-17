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
nTotalTrials = 960;
nTrialsPerBlock = 120;
nBlocks = nTotalTrials/nTrialsPerBlock;
isiTime = 1.2; % pre-cue time
cueTime = 40/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
cuedLocProb = [.5 .5]; % probability of cue location
cueValidProb = .8;

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
GratingExp.append_block("grating_0_wait", WaitGrating, 0);
GratingExp.append_block("grating_1_block", GratingBlock, nGratingTrials);
% GratingExp.run();
% % save the full block
% save(['results/' sessionNumber '/GratingThesholdExperiment.mat'], 'GratingExp')
% % save the results table
% gratingResults = GratingExp.save_run(['results/' sessionNumber '/grating_threshold_results.mat'], []);
% threshDiameter = GratingBlock.get_size_thresh(pFitInit, gratingResults);
% sca;
% return
threshDiameter=1;
% all spacings 
spacingChoices = [Inf linspace(threshDiameter, 2.2, 7)];
spacingProb = ones(1, length(spacingChoices)) / length(spacingChoices);
% -----------------
% Build Modules
% -----------------
% Informative/Long SOA
soaTime = 600/1000;
LongBlock = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spacingProb, spacingChoices, isiTime, cueTime, soaTime, stimTime);
LongBlock.diameter = threshDiameter;
LongBlock.spatialFrequency = cyclesPerGrating/threshDiameter;

% Non-informative/Short SOA
soaTime = 40/1000;
ShortBlock = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spacingProb, spacingChoices, isiTime, cueTime, soaTime, stimTime);
ShortBlock.diameter = threshDiameter;
ShortBlock.spatialFrequency = cyclesPerGrating/threshDiameter;

% return
% -----------------
% Practice Trials
% -----------------
% PracExp = Experiment();
% PracExp.append_block("practice", LongBlock, 30);
% PracExp.run()
% pracResTable = PracExp.save_run("practive_results");

% ----------------
% Main Experiment
% ----------------
Exp = Experiment();
blockLabels = string(1:nBlocks);
soaChoices = random_sample(nBlocks, [0.5 0.5], [0 1], false);
for i = 1:nBlocks
    label = blockLabels(i);
    waitLabel = "wait_" + label;
    blockLabel = "block_" + label;
    % add wait message screen
    WaitBlock = Wait;
    WaitBlock.displayText = [char(string(i)) '/' char(string(nBlocks)) WaitBlock.displayText];
    Exp.append_block(waitLabel, WaitBlock, 0);
    % add block 
    if soaChoices(i)
        Exp.append_block(blockLabel, LongBlock, nTrialsPerBlock);
    else
        Exp.append_block(blockLabel, ShortBlock, nTrialsPerBlock);
    end
end
% run the experiment
Exp.run()
sca;
% save the full experiment 
save(['results/' sessionNumber '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run(['results/' sessionNumber '/experiment_results.mat'], []);




    