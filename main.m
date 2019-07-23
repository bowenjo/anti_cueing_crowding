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
isiTime = 1; % pre-cue time
cueTime = 200/1000; % cue presentation time
stimTime = 133/1000; % stimulus presentation time
cuedLocProb = [.5 .5]; % probability of cue location
cueValidProb = .8;

% Ask for session number 
sessionNumber = input('Please enter session number ', 's');
mkdir(['results/' sessionNumber]);

% open ptb window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% all spacings 
spacingChoices = [Inf 1.25:0.50:4.25];
spacingProb = ones(1, 8) / 8;

% -----------------
% Build Modules
% -----------------
% Informative/Long SOA
soaTime = 600/1000;
LongBlock = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spacingProb, spacingChoices, isiTime, cueTime, soaTime, stimTime);

% Non-informative/Short SOA
soaTime = 40/1000;
ShortBlock = CueTrial(window, windowRect, cuedLocProb, cueValidProb, ...
    spacingProb, spacingChoices, isiTime, cueTime, soaTime, stimTime);

waitMessage = 'Press space bar to start';
Wait = WaitScreen(window, waitMessage, 70); 

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
soaChoices = random_sample(nBlocks, [0.5 0.5], [0 1]);
for i = 1:nBlocks
    label = blockLabels(i);
    waitLabel = label + "_0_wait";
    blockLabel = label + "_1_block";
    % add wait message screen
    Exp.append_block(waitLabel, Wait, 0);
    % add block 
    if soaChoices(i)
        Exp.append_block(blockLabel, LongBlock, nTrialsPerBlock);
    else
        Exp.append_block(blockLabel, ShortBlock, nTrialsPerBlock);
    end
end
% run the experiment
Exp.run()
% save the full experiment 
save(['results/' sessionNumber '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run(['results/' sessionNumber '/results_table.mat']);
sca;

% TODO: timing of fixCheck is off - need to include the check time in the 
% SOA time: can't be greater than 40ms total. Right now it's up to 200ms +
% SOA time


    