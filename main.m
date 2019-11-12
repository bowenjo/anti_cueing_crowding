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

% if the baselines already exist for session 1
szComplete = 'n'; spComplete = 'n';
if sessionNumber == '1'
    if exist([sessionDir '/sz_threshold_results.mat'], 'file')
        szComplete = input('SIZE baseline already exists. Use it? y/n: ', 's');
    end
    if exist([sessionDir '/sp_threshold_results.mat'], 'file') && szComplete == 'y'
        spComplete = input('SPACING baseline already exits. Use it? y/n: ', 's'); 
    end
else
    szComplete = 'y'; spComplete = 'y';
end

% Ask for the side of the screen to present the baseline stimuli
if sessionNumber == '1' && szComplete == 'n'
    baselineDisplaySide = input('Baseline Display Side? r/l: ', 's');
    if baselineDisplaySide == 'r'
        baselineDisplay = [0 1];
        szInstruct = load('instructions/size_thresh_instruction_frames_right.mat');
    elseif baselineDisplaySide == 'l'
        baselineDisplay = [1 0];
        szInstruct = load('instructions/size_thresh_instruction_frames_left.mat');
    end
end

% if an experiment already exists
continueFromCheckpoint = 'n'; skipPractice = 'n';
if exist([sessionDir '/Experiment.mat'], 'file') && spComplete == 'y'
    pauseBeforeExp = true;
    while pauseBeforeExp
        continueFromCheckpoint = input(['An experiment file already exists for this session. ' ...
                                    'Continue from checkpoint? y/n: '], 's');
        if continueFromCheckpoint == 'n' 
            pauseBeforeExp = false;
        elseif continueFromCheckpoint == 'y' 
            pauseBeforeExp = false; 
            restartBlock = input('Restart block? y/n: ', 's');
            skipPractice = input('Skip the practice trials? y/n: ', 's');
        end
    end 
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
pInit.t = 1.2; % init threshold grating size
pInit.b = 1; % estimated slope
pInit.g = 0.50; % chance percent correct

if sessionNumber == '1' && spComplete == 'n'
    nUp = 1; % number of wrong trials in a row to move up 
    nDown = 3; % number of correct trials in a row to move down
    nPracticeStop = 10; % number of correct trials in a row to pass the practice 
    
    if szComplete == 'n'
        % ==================================
        % Grating Size Threshold Experiment
        % ==================================
        SzExp = Experiment();

        % size grating threshold paramters
        nSzTrials = 100; % number of trials for the size staircase
        initSize = 1.8; % initial grating diameter (DVA)
        stepSize = .1; % staicase step size (DVA)
        szFixColors = [.35 0  0; .35 0 0; 0 .35 0; .35 0 0]; % fixation cross RGB colors

        % size grating experiment instructions
        szInstruct = szInstruct.instructions;
        szInstructBlock = WaitScreen(window, windowRect, '', 70, szInstruct);

        % size grating experiment blocks
        SzPractice = GratingThreshTrial(window, windowRect, 'grating_size', initSize, ...
                            stepSize, nUp, nPracticeStop, szFixColors, stimTime, ...
                            baselineDisplay, true);
        PracticeWait = Wait;
        PracticeWait.displayText = 'Practice Complete!';

        SzBlock = GratingThreshTrial(window, windowRect, 'grating_size', initSize, ...
                            stepSize, nUp, nDown, szFixColors, stimTime, ...
                            baselineDisplay, false);                    
        EndWait = Wait;
        EndWait.displayText = 'You Are Done With Part I!';

        % append blocks
        SzExp.append_block('exp_instructions', szInstructBlock, 0);
        SzExp.append_block("practice_block", SzPractice, nSzTrials);
        SzExp.append_block("practice_complete_screen", PracticeWait, 0);
        SzExp.append_block("main_block", SzBlock, nSzTrials);
        SzExp.append_block("end_screen", EndWait, 0);

        % run and save the full experiment
        szBlockIndices = fields(SzExp.blocks)';
        SzExp.run([], '');
        save([sessionDir '/SzThresholdExperiment.mat'], 'SzExp')
        szResults = SzExp.save_run([sessionDir '/sz_threshold_results.mat'], ...
            szBlockIndices(3:length(szBlockIndices)));
    else
        SzExp = load([sessionDir '/SzThresholdExperiment.mat']);
        SzExp = SzExp.SzExp;
        szResults = load([sessionDir '/sz_threshold_results.mat']);
        szResults = szResults.results;
        SzBlock = SzExp.blocks.main_block;
        baselineDisplay = SzBlock.cuedLocProb;
    end
    
    pauseBeforeExp = true;
    while pauseBeforeExp
        % fit a psychometric function to the size experiment and get the threshold diameter
        nSzTrials = SzExp.nTrialTracker.main_block;
        pInit.a = .75;
        pFitSize = SzBlock.get_size_thresh(pInit, szResults);
        diameter = max(1.5 * pFitSize.t, 1.5*mean(...
            szResults.grating_size(nSzTrials-nSzTrials/5:nSzTrials)));
        % check to make sure the psychometric function fits the data 
        if szComplete == 'n'
            sca;
            fprintf('Size: %4.2f', diameter);
            continueToExp = input('\n Continue to Part II (c) or repeat Part I (r). c/r?', 's');
            % Repeat Part I 
            if continueToExp== 'r'
                PsychImaging('OpenWindow', screenNumber, backgroundGrey);
                SzExp.checkpoint.block = {'main_block'};
                SzExp.run([],'');
                save([sessionDir '/SzThresholdExperiment.mat'], 'SzExp')
                szResults = SzExp.save_run([sessionDir '/sz_threshold_results.mat'], ...
                    szBlockIndices(3:length(szBlockIndices)));
            % continue to Part II    
            elseif continueToExp == 'c' 
                pauseBeforeExp = false;
                [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
            end
        else
            pauseBeforeExp = false;
        end  
        close all
    end
    
    % =======================================
    % Grating Spacing Threshold Experiment
    % =======================================
    SpExp = Experiment();
    
    % spacing grating threshold parameters
    nSpTrials = 150; % number of trials in the staircase
    initSpacing = 5; % initial target-flanker spacing of grating in degrees
    stepSpacing = .2; % spacing step size in degrees
    spFixColors = [.25; .25; .25; 0]; % grey-scale values for the fixation cross
    
    % spacing grating experiment instructions
    if baselineDisplay(1) == 0
        spInstruct = load('instructions/spacing_thresh_instruction_frames_right.mat');
    else
        spInstruct = load('instructions/spacing_thresh_instruction_frames_left.mat');
    end 
    spInstruct = spInstruct.instructions;
    spInstructBlock = WaitScreen(window, windowRect, '', 70, spInstruct);
    % grating spacing experiment blocks
    SpPractice= GratingThreshTrial(window, windowRect, 'spacing', initSpacing, ...
                        stepSpacing, nUp, nPracticeStop, spFixColors, stimTime, ...
                        baselineDisplay, true);
    SpPractice.diameter = diameter; % add the threshold diameter
    SpPractice.spatialFrequency = SpPractice.cyclesPerGrating / diameter;
    SpPractice.set_position_params();
    
    PracticeWait = Wait;
    PracticeWait.displayText = 'Practice Complete!';
    
    SpBlock = GratingThreshTrial(window, windowRect, 'spacing', initSpacing, ...
                        stepSpacing, nUp, nDown, spFixColors, stimTime, ...
                        baselineDisplay, false);
    SpBlock.diameter = diameter; % add the threshold diameter
    SpBlock.spatialFrequency = SpBlock.cyclesPerGrating / diameter;
    SpBlock.set_position_params();
    
    EndWait = Wait;
    EndWait.displayText = 'You Are Done With Part II!';
                    
    % append blocks
    SpExp.append_block('exp_instructions', spInstructBlock, 0);
    SpExp.append_block("practice_block", SpPractice, nSpTrials);
    SpExp.append_block("practice_complete_screen", PracticeWait, 0);
    SpExp.append_block("main_block", SpBlock, nSpTrials);                
    SpExp.append_block("end_screen", EndWait, 0)
    
    % run the spacing baseline experiment
    spBlockIndices = fields(SzExp.blocks)';
    SpExp.run([], '');
    save([sessionDir '/SpThresholdExperiment.mat'], 'SpExp')
    spResults = SpExp.save_run([sessionDir '/sp_threshold_results.mat'], ...
        spBlockIndices(3:length(spBlockIndices)));
    
else    
    % or load in spacing threshold from previous session 
    SpExp = load([subjectDir '/1/SpThresholdExperiment.mat']);
    SpExp = SpExp.SpExp;
    spResults = load([subjectDir '/1/sp_threshold_results.mat']);
    spResults = spResults.results;
end

pauseBeforeExp = true;
while pauseBeforeExp
    % fit a psychometric function to spacing range  experiment 
    SpBlock = SpExp.blocks.main_block;
    % diameter
    diameter = SpBlock.diameter;
    % lower bound 
    pInit.a = .55;
    pInit.t = 1.5; % init lower thresh 
    pFitLower = SpBlock.get_size_thresh(pInit, spResults);
    lowerSpacing = max(diameter, pFitLower.t); % physical min or ~55% performance
    % upper bound
    pInit.a = .80;
    pInit.t = 4; % init upper thresh
    pFitUpper = SpBlock.get_size_thresh(pInit, spResults);
    upperSpacing = 1.5 * pFitUpper.t;
    
    % verify the range of spacings
    if sessionNumber == '1' && spComplete == 'n'
        sca;
        fprintf('Size: %4.2f; Lower Spacing: %4.2f; Upper Spacing: %4.2f ', ...
        [diameter, lowerSpacing, upperSpacing]);
        continueToExp = input('\n Continue to Part III (c) or repeat Part II (r): c/r?', 's');
        % repeat Part II
        if continueToExp== 'r'
            PsychImaging('OpenWindow', screenNumber, backgroundGrey);
            SpExp.checkpoint.block = {'main_block'};
            SpExp.run([],'');
            save([sessionDir '/SpThresholdExperiment.mat'], 'SpExp')
            spResults = SpExp.save_run([sessionDir '/sp_threshold_results.mat'], ...
                spBlockIndices(3:length(spBlockIndices)));
        % continue to Part III
        elseif continueToExp == 'c' 
            pauseBeforeExp = false;
            [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
        end
    else
        pauseBeforeExp = false;
    end
    close all
end


% =====================================
% Main Experiment 
% =====================================
spacingChoices = [Inf linspace(lowerSpacing, upperSpacing, 7)];

if continueFromCheckpoint == 'n'
    % start a new experiment
    Exp = Experiment();

    %block trial information
    nTotalTrials = 960;
    nTrialsPerBlock = 120;
    nBlocks = nTotalTrials/nTrialsPerBlock;
    nPracticeTrials = 32;

    % timing information
    isiTime = 1200/1000; % pre-cue time
    cueTime = 40/1000; % cue presentation time
    longSOA = 600/1000; % long SOA time
    shortSOA = 40/1000; % short SOA time

    % cue information
    cuedLocProb = [.5 .5]; % probability of cue location
    cueValidProb = .8;

    % spacing probabilities
    spacingProb = ones(1, length(spacingChoices)) / length(spacingChoices);

    % instructions
    expInstruct = load('instructions/anti_cueing_instruction_frames.mat');
    expInstruct = expInstruct.instructions;
    InstructBlock = WaitScreen(window, windowRect, '', 70, expInstruct);
    Exp.append_block('exp_instructions', InstructBlock, 0);

    % append practice blocks
    pBlock1 =  CueTrial(window, windowRect, diameter, cuedLocProb, ...
                        cueValidProb, spacingProb, spacingChoices, ...
                        isiTime, 1, 1, 1);

    pWait2 = Wait;
    pWait2.displayText = ['Practice Trials' Wait.displayText];
    pBlock2 = CueTrial(window, windowRect, diameter, cuedLocProb, ...
                        cueValidProb, spacingProb, spacingChoices, ...
                        isiTime, cueTime, longSOA, stimTime);

    pWait3 = Wait;
    pWait3.displayText = ['Practice Trials' Wait.displayText];
    pBlock3 =  CueTrial(window, windowRect, diameter, cuedLocProb, ...
                        cueValidProb, spacingProb, spacingChoices, ...
                        isiTime, cueTime, shortSOA, stimTime);

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
    
else
    % load in from checkpoint 
    Exp = load([sessionDir '/Experiment.mat']);
    Exp = Exp.self;
    if restartBlock == 'y'
        Exp.checkpoint.trial = 1;
    end
    checkpointBlock = Exp.checkpoint.block;
    checkpointTrial = Exp.checkpoint.trial;
end

% run the experiment
blockIndices = fields(Exp.blocks)';
practicePerformanceThreshold = 0.75;

if skipPractice == 'n'
    Exp.run(blockIndices(1:2), '')% run instructions/slowed-down example
    % run a couple practice blocks and check performance
    practice_check(Exp, blockIndices(3:6), practicePerformanceThreshold, ...
        length(spacingChoices), 'spacing');
    % load back in the checkpoint
    if continueFromCheckpoint == 'y'
        Exp.checkpoint.block = checkpointBlock;
        Exp.checkpoint.trial = checkpointTrial;
    end
end
% run full experiment
Exp.run(blockIndices(7:length(blockIndices)), [sessionDir '/Experiment.mat']);     

sca;
% save the full experiment 
save([sessionDir '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run([sessionDir '/experiment_results.mat'], blockIndices(7:length(blockIndices)));




    