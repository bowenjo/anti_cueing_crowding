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

% ===========================================
% Grating Spacing Threshold Experiment
% ===========================================
if sessionNumber == '1'
    GratingExp = Experiment();
    
    % grating experiment instructions
    gratingInstruct = load('instructions/grating_thresh_instruction_frames.mat');
    gratingInstruct = gratingInstruct.instructions;
    gInstructBlock = WaitScreen(window, windowRect, '', 70, gratingInstruct);
    GratingExp.append_block('exp_instructions', gInstructBlock, 0);

    % grating threshold parameters
    nGratingTrials = 200;
    nPracticeGratingTrials = 1;
    initSize = 4; % initial size of grating in degrees
    stepSize = .2; % grating step size in degrees
    nUp = 1; % number of wrong trials in a row to move up 
    nDown = 3; % number of correct trials in a row to move down
    cyclesPerGrating = 4;
    practicePerformanceThreshold = 0.8;

    % grating experiment blocks
    WaitGrating = Wait;
    
    % append practice blocks
    WaitGrating.displayText = ['Grating Threshold Experiment: Practice' Wait.displayText]; 
    GratingExp.append_block("grating_wait_practice", WaitGrating, 0);
    GratingExp.append_block("grating_block_practice", ...
                            GratingThreshTrial(window, windowRect, 'spacing', initSize, ...
                            stepSize, nUp, nDown, cyclesPerGrating, stimTime), ...
                            nPracticeGratingTrials);

    % append blocks
    WaitGrating.displayText = ['Grating Threshold Experiment' Wait.displayText];
    GratingExp.append_block("grating_wait", WaitGrating, 0);
    GratingExp.append_block("grating_block", ...
                            GratingThreshTrial(window, windowRect, 'spacing', initSize, ...
                            stepSize, nUp, nDown, cyclesPerGrating, stimTime), ...
                            nGratingTrials);
                        
    WaitEnd = Wait;
    WaitEnd.displayText = 'You Are Done with Part I!';
    GratingExp.append_block("end_screen", WaitEnd, 0)

    % run and save the full experiment
    gratingBlockIndices = fields(GratingExp.blocks)';
    GratingExp.run(gratingBlockIndices(1))
    
    gratingPracticeNotComplete = true;
    while gratingPracticeNotComplete
        GratingExp.run(gratingBlockIndices(2:3));
        gratingPracticeData = GratingExp.save_run('',gratingBlockIndices(2:3));
        gratingPracticeResults = analyze_results(gratingPracticeData, ...
            'spacing', {'correct'}, {}, [], @mean);
        if mean(gratingPracticeResults.correct) > practicePerformanceThreshold
            gratingPracticeNotComplete = false;
        end
    end
    
    GratingExp.run(gratingBlockIndices(4:length(gratingBlockIndices)));
        
    save([sessionDir '/GratingThresholdExperiment.mat'], 'GratingExp')
    gratingResults = GratingExp.save_run([sessionDir '/grating_threshold_results.mat'], ...
        gratingBlockIndices(4:length(gratingBlockIndices)));
else
    % or load in the old files from a previous session
    GratingExp = load([subjectDir '/1/GratingThresholdExperiment.mat']);
    GratingExp = GratingExp.GratingExp;
    gratingResults = load([subjectDir '/1/grating_threshold_results.mat']);
    gratingResults = gratingResults.results;
end

% find (or load in) the spacing range for full experiment
GratingBlock = GratingExp.blocks.grating_block;
% psychometric fit initialization
pInit.t = 1.5; % estimated threshold spacing
pInit.b = 1; % estimated slope
pInit.g = 0.50; % chance percent correct
% lower bound 
pInit.a = .55;
pFitLower = GratingBlock.get_size_thresh(pInit, gratingResults);
lowerSpacing = max(GratingBlock.diameter, pFitLower.t); % physical min or ~55% performance
% upper bound
pInit.a = .80;
pFitUpper = GratingBlock.get_size_thresh(pInit, gratingResults);
upperSpacing = pFitUpper.t + pFitUpper.t/2;

% verify the range of spacings
sca;
fprintf('Lower Limit: %4.2f; Upper Limit; %4.2f', [lowerSpacing, upperSpacing]);
if ~input('Continue: 1-yes, 0-no? ', 's')
    return
else
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
end

% =====================================
% Full Experiment 
% =====================================
Exp = Experiment();

% instructions
expInstruct = load('instructions/anti_cueing_instruction_frames.mat');
expInstruct = expInstruct.instructions;
InstructBlock = WaitScreen(window, windowRect, '', 70, expInstruct);
Exp.append_block('exp_instructions', InstructBlock, 0);

%block trial information
nTotalTrials = 960;
nTrialsPerBlock = 120;
nBlocks = nTotalTrials/nTrialsPerBlock;
nPracticeTrials = 16;
practicePerformanceThreshold = 0.75;

% timing information
isiTime = 1200/1000; % pre-cue time
cueTime = 40/1000; % cue presentation time
longSOA = 600/1000; % long SOA time
shortSOA = 40/1000; %short SOA time

% cue information
cuedLocProb = [.5 .5]; % probability of cue location
cueValidProb = .8;
 
% spacing choice
spacingChoices = [Inf linspace(lowerSpacing, upperSpacing, 7)];
spacingProb = ones(1, length(spacingChoices)) / length(spacingChoices);

% append practice blocks
pWait1 = Wait;
pWait1.displayText = ['Practice Trial: Examples' Wait.displayText];
pBlock1 =  CueTrial(window, windowRect, cuedLocProb, ...
                    cueValidProb, spacingProb, spacingChoices, ...
                    isiTime, 1, 1, 1);

pWait2 = Wait;
pWait2.displayText = ['Practice Trial 1' Wait.displayText];
pBlock2 = CueTrial(window, windowRect, cuedLocProb, ...
                    cueValidProb, spacingProb, spacingChoices, ...
                    isiTime, cueTime, longSOA, stimTime);

pWait3 = Wait;
pWait3.displayText = ['Practice Trial 2' Wait.displayText];
pBlock3 =  CueTrial(window, windowRect, cuedLocProb, ...
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
                         CueTrial(window, windowRect, cuedLocProb, ...
                         cueValidProb, spacingProb, spacingChoices, ...
                         isiTime, cueTime, longSOA, stimTime),...
                         nTrialsPerBlock);
    else
        % short block
        Exp.append_block(blockLabel, ...
                         CueTrial(window, windowRect, cuedLocProb, ...
                         cueValidProb, spacingProb, spacingChoices, ...
                         isiTime, cueTime, shortSOA, stimTime),...
                         nTrialsPerBlock);
    end
end
WaitEnd = Wait;
WaitEnd.displayText = 'You Are Done!';
Exp.append_block("end_screen", WaitEnd, 0);

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




    