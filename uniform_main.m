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

% Ask for subject ID
subjectID = input('Subject ID: ', 's');
subjectDir = ['results/' subjectID];
if ~exist(subjectDir, 'dir')
    mkdir(subjectDir)
end

% open ptb window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% base wait screen
waitMessage = '\n press space bar to start';
Wait = WaitScreen(window, windowRect, waitMessage, 70, []);

% Experiment Parameters
cueTime = 40/1000;
soaTime = 40/1000 ;
stimTime = 133/1000;
isiTime = 1.2;
cuedLocProb = [.5 .5];
cueValidProb = .5;
diameter = 1;
spacing = 3; % fixed spacing
cueSizeCh = [diameter, 2*spacing + diameter]; % cue size choices target/target+flankers
cueSizeProb = [.5 .5];
ensembleMeanCh = [0 45 90]; %parallel/neutral/orthogonal conditions
ensembleMeanProb = ones(1,3)./3 ; 
targetLocCh = [6, 7, 10, 11];
targetLocProb = [.25, .25, .25, .25];
sigma = 45; 

% Trials
nTrialsTotal = 120;
nTrialsPerBlock = 120;
nBlocks = nTrialsTotal/nTrialsPerBlock;

Exp = Experiment();
% Append full experiment blocks
blockLabels = string(1:nBlocks);
for i = 1:nBlocks
    label = blockLabels(i);
    waitLabel = "wait_" + label;
    blockLabel = "block_" + label;

    % add wait message screen
    WaitBlock = Wait;
    WaitBlock.displayText = [char(string(i)) '/' char(string(nBlocks)) WaitBlock.displayText];
    Exp.append_block(waitLabel, WaitBlock, 0);

    % add block 
    Exp.append_block(blockLabel, ...
                     CueEnsembleUniformTrial(window, windowRect, diameter, spacing, ...
                     cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ensembleMeanProb, ...
                     ensembleMeanCh, targetLocProb, targetLocCh, sigma, ...
                     isiTime, cueTime, soaTime, stimTime), nTrialsPerBlock)
end

EndWait = Wait;
EndWait.displayText = 'You Are Done!';
Exp.append_block("end_screen", EndWait, 0);

% Run the experiment
Exp.run([], [subjectDir '/Experiment.mat'])
sca;

results = Exp.save_run([subjectDir '/experiment_results.mat'], []);