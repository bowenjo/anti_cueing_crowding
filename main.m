% =========================================
% Screen and General Set-up
% =========================================
sca; 
close all;
clearvars;
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
backgroundGrey = WhiteIndex(screenNumber)/2;
EyelinkInit();

% Add relevant paths
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
% Ask for session number
sessionNumber = input('Session #: ', 's');
sessionDir = [subjectDir '/' sessionNumber];
if ~exist(sessionDir, 'dir')
    mkdir(sessionDir);
end

% open ptb window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);

% base wait screen
waitMessage = '\n press space bar to start';
Wait = WaitScreen(window, windowRect, waitMessage, 70, []);

% all experiment parameters
stimTime = 133/1000; % stimulus presentation time

% ========================================
% Baseline: Grating Size and Spacing Range
% ========================================
% psychometric fit initialization
pInit.t = 1; % estimated threshold spacing
pInit.b = 1; % estimated slope
pInit.g = 0.50; % chance percent correct

if sessionNumber == '1'
    % 
    nUp = 1; % number of wrong trials in a row to move up 
    nDown = 3; % number of correct trials in a row to move down
    
    % ==================================
    % Grating Size Threshold Experiment
    % ==================================
    SzExp = Experiment();
    
    % size grating threshold paramters
    nSzTrials = 100;
    initSize = 1.25;
    stepSize = .1;
    
    % size grating experiment instructions
    szInstruct = load('instructions/size_thresh_instruction_frames.mat');
    szInstruct = szInstruct.instructions;
    szInstructBlock = WaitScreen(window, windowRect, '', 70, szInstruct);
    SzExp.append_block('exp_instructions', szInstructBlock, 0);
    
    % grating size experiment blocks
    SzWait = Wait;
    SzWait.displayText = ['Part I: Setting a Baseline (Size) \n' Wait.displayText];
    SzBlock = GratingThreshTrial(window, windowRect, 'grating_size', initSize, ...
                        stepSize, nUp, nDown, stimTime);
    
    % append blocks
    SzExp.append_block("grating_wait", SzWait, 0);
    SzExp.append_block("grating_block", SzBlock, nSzTrials);
    
    % run and save the full experiment
    SzExp.run([]);
    save([sessionDir '/SzThresholdExperiment.mat'], 'SzExp')
    szResults = SzExp.save_run([sessionDir '/sz_threshold_results.mat'], []);
    
    % get the threshold diameter
    pInit.a = .75;
    pFitSize = SzBlock.get_size_thresh(pInit, SzResults);
    diameter = pFitSize.t + pFitSize.t/2;
    
    % =======================================
    % Grating Spacing Threshold Experiment
    % =======================================
    SpExp = Experiment();
    
    % spacing grating threshold parameters
    nSpTrials = 200;
    initSpacing = 4; % initial target-flanker spacing of grating in degrees
    stepSpacing = .2; % spacing step size in degrees
    
    % spacing grating experiment instructions
    spInstruct = load('instructions/spacing_thresh_instruction_frames.mat');
    spInstruct = spInstruct.instructions;
    spInstructBlock = WaitScreen(window, windowRect, '', 70, spInstruct);
    SpExp.append_block('exp_instructions', spInstructBlock, 0);

    % grating spacing experiment blocks
    SpWait = Wait;
    SpWait.displayText = ['Part II: Setting a Baseline (Spacing) \n' Wait.displayText];
    SpBlock= GratingThreshTrial(window, windowRect, 'spacing', initSpacing, ...
                        stepSpacing, nUp, nDown, stimTime);
    SpBlock.diameter = diameter; % add the threshold diameter
                    
    % append blocks
    SpExp.append_block("grating_wait", SpWait, 0);
    SpExp.append_block("grating_block", SpBlock, nSpTrials);
                        
    EndWait = Wait;
    EndWait.displayText = 'You Are Done With Part I!';
    SpExp.append_block("end_screen", EndWait, 0)

    % run and save the full experiment
    SpExp.run([]);
    save([sessionDir '/SpThresholdExperiment.mat'], 'SpExp')
    spResults = SpExp.save_run([sessionDir '/sp_threshold_results.mat'], []);
    
else    
    % or load in spacing threshold from previous session 
    SpExp = load([subjectDir '/1/SpThresholdExperiment.mat']);
    SpExp = SpExp.SpExp;
    spResults = load([subjectDir '/1/sp_threshold_results.mat']);
    spResults = spResults.results;
end

% get a range of spacings
SpBlock = SpExp.blocks.grating_block;
% lower bound 
pInit.a = .55;
pInit.t = 1;
pFitLower = SpBlock.get_size_thresh(pInit, spResults);
lowerSpacing = max(SpBlock.diameter, pFitLower.t); % physical min or ~55% performance
% upper bound
pInit.a = .80;
pInit.t = 3;
pFitUpper = SpBlock.get_size_thresh(pInit, spResults);
upperSpacing = pFitUpper.t + pFitUpper.t/2;

% verify the range of spacings
sca;
fprintf('Size: %4.2 \n Lower Spacing: %4.2f \n Upper Spacing: %4.2f \n',...
    [diameter, lowerSpacing, upperSpacing]);
if ~input('Continue: 1-yes, 0-no? ', 's')
    return
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
end

% =====================================
% Full Experiment 
% =====================================
Exp = Experiment();

%block trial information
nTotalTrials = 960;
nTrialsPerBlock = 120;
nBlocks = nTotalTrials/nTrialsPerBlock;
nPracticeTrials = 16;
practicePerformanceThreshold = 0.75;
diameter = SpBlock.diameter;

% timing information
isiTime = 1200/1000; % pre-cue time
cueTime = 40/1000; % cue presentation time
longSOA = 600/1000; % long SOA time
shortSOA = 40/1000; % short SOA time

% cue information
cuedLocProb = [.5 .5]; % probability of cue location
cueValidProb = .8;
 
% spacing choice
spacingChoices = [Inf linspace(lowerSpacing, upperSpacing, 7)];
spacingProb = ones(1, length(spacingChoices)) / length(spacingChoices);

% instructions
expInstruct = load('instructions/anti_cueing_instruction_frames.mat');
expInstruct = expInstruct.instructions;
InstructBlock = WaitScreen(window, windowRect, '', 70, expInstruct);
Exp.append_block('exp_instructions', InstructBlock, 0);

% append practice blocks
pWait1 = Wait;
pWait1.displayText = ['Practice: Slowed-down Examples' Wait.displayText];
pBlock1 =  CueTrial(window, windowRect, diameter, cuedLocProb, ...
                    cueValidProb, spacingProb, spacingChoices, ...
                    isiTime, 1, 1, 1);

pWait2 = Wait;
pWait2.displayText = ['Practice 1' Wait.displayText];
pBlock2 = CueTrial(window, windowRect, diameter, cuedLocProb, ...
                    cueValidProb, spacingProb, spacingChoices, ...
                    isiTime, cueTime, longSOA, stimTime);

pWait3 = Wait;
pWait3.displayText = ['Practice 2' Wait.displayText];
pBlock3 =  CueTrial(window, windowRect, diameter, cuedLocProb, ...
                    cueValidProb, spacingProb, spacingChoices, ...
                    isiTime, cueTime, shortSOA, stimTime);

Exp.append_block('practice_wait_1', pWait1, 0);
Exp.append_block('practice_block_1', pBlock1, 8);
Exp.append_block('practice_wait_2', pWait2, 0);
Exp.append_block('practice_block_2', pBlock2, nPracticeTrials/2);
Exp.append_block('practice_wait_3', pWait3, 0);
Exp.append_block('practice_block_3', pBlock3, nPracticeTrials/2);

% append full experiment blocks
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
        % long block
        Exp.append_block(blockLabel, ...
                         CueTrial(window, windowRect, diameter, cuedLocProb, ...
                         cueValidProb, spacingProb, spacingChoices, ...
                         isiTime, cueTime, longSOA, stimTime),...
                         nTrialsPerBlock);
    else
        % short block
        Exp.append_block(blockLabel, ...
                         CueTrial(window, windowRect, diameter, cuedLocProb, ...
                         cueValidProb, spacingProb, spacingChoices, ...
                         isiTime, cueTime, shortSOA, stimTime),...
                         nTrialsPerBlock);
    end
end
EndWait = Wait;
EndWait.displayText = 'You Are Done!';
Exp.append_block("end_screen", EndWait, 0);

% run the experiment
blockIndices = fields(Exp.blocks)';
Exp.run(blockIndices(1))% run instructions

if sessionNumber == '1'
    Exp.run(blockIndices(2:3)) % run the slowed-down examples
    % run a couple practice blocks and check they're doing it correctly
    practiceNotComplete = 1;
    while practiceNotComplete
        % run practice blocks 
        Exp.run(blockIndices(4:7))
        % check for performance
        practiceData = Exp.save_run('', blockIndices(4:7));
        practiceResults = analyze_results(practiceData, 'spacing', {'correct'}, {}, [], @mean);
        if practiceResults.correct(length(spacingChoices)) > practicePerformanceThreshold
            practiceNotComplete = false;
        else
            practiceNotComplete = true;
        end 
    end
    % run full experimetn
    Exp.run(blockIndices(8:length(blockIndices)));     
else
    % only run the full experiment blocks if not session #1
    Exp.run(blockIndices(8:length(blockIndices)));
end
sca;
% save the full experiment 
save([sessionDir '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run([sessionDir '/experiment_results.mat'], blockIndices(8:length(blockIndices)));




    