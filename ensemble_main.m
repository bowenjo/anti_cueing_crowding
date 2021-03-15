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

% if the baselines already exist 
szComplete = 'n'; spComplete = 'n';
if sessionNumber == "1"
    if exist([sessionDir '/sz_threshold_results.mat'], 'file')
        szComplete = input('SIZE baseline already exists. Use it? y/n: ', 's');
    end
    if exist([sessionDir '/sp_threshold_results.mat'], 'file') && szComplete == 'y'
        spComplete = input('SPACING baseline already exits. Use it? y/n: ', 's'); 
    end

    % Ask for the side of the screen to present the baseline stimuli
    if szComplete == 'n'
        baselineDisplaySide = input('Baseline Display Side? r/l: ', 's');
        if baselineDisplaySide == 'r'
            baselineDisplay = [0 1];
            szInstruct = load('instructions/size_thresh_instruction_frames_right.mat');
        elseif baselineDisplaySide == 'l'
            baselineDisplay = [1 0];
            szInstruct = load('instructions/size_thresh_instruction_frames_left.mat');
        end
    end
else
    szComplete = 'y'; spComplete = 'y'; 
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
nReversals = 6; % number of reversals to average over

% ========================================
% Baseline: Grating Size and Spacing Range
% ========================================
if spComplete == 'n'
    nUp = 1; % number of wrong trials in a row to move up 
    nDownSz = 3; % number of correct trials in a row to move down for size
    nDownSp = 2; % number of correct trials in a row to move down for spacing
    nPracticeStop = 10; % number of correct trials in a row to pass the practice 
    
    if szComplete == 'n'
        % ==================================
        % Grating Size Threshold Experiment
        % ==================================
        SzExp = Experiment();

        % size grating threshold paramters
        nSzTrials = 100; % number of trials for the size staircase
        initSize = 1.5; % initial grating diameter (DVA)
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
                            stepSize, nUp, nDownSz, szFixColors, stimTime, ...
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
        % get the threshold from the staircase
        nSzTrials = SzExp.nTrialTracker.main_block;
        threshSize = get_reversal_thresh(szResults.grating_size, nReversals);
        diameter = 1.5 * threshSize;
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
    initSpacing = 7; % initial target-flanker spacing of grating in degrees
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
    SpPractice.set_position_params(diameter);
    
    PracticeWait = Wait;
    PracticeWait.displayText = 'Practice Complete!';
    
    SpBlock = GratingThreshTrial(window, windowRect, 'spacing', initSpacing, ...
                        stepSpacing, nUp, nDownSp, spFixColors, stimTime, ...
                        baselineDisplay, false);
    SpBlock.diameter = diameter; % add the threshold diameter
    SpBlock.spatialFrequency = SpBlock.cyclesPerGrating / diameter;
    SpBlock.set_position_params(diameter);
    
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
    % find threshold value from staircase 
    SpBlock = SpExp.blocks.main_block;
    diameter = SpBlock.diameter;
    spacing = get_reversal_thresh(spResults.spacing, nReversals);
    
    % verify the range of spacings
    if spComplete == 'n'
        sca;
        fprintf('Size: %4.2f; Spacing: %4.2f ', ...
        [diameter, spacing]);
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

if continueFromCheckpoint == 'n'
    % start a new experiment
    Exp = Experiment();

    %block trial information
    nTotalTrials = 960;
    nTrialsPerBlock = 120;
    nBlocks = nTotalTrials/nTrialsPerBlock;
    nPracticeTrials = 8;

    % timing information
    isiTime = 1200/1000; % pre-cue time
    cueTime = 40/1000; % cue presentation time
    soaTime = 40/1000; % start of cue to stimulus time

    % cue information
    cuedLocProb = [.5 .5]; % probability of cue location
    cueValidProb = .5;

    % spacing probability
    spacingProb = 1;
    
    % cue info
    cueSizeCh = [diameter, 2*spacing + diameter]; % cue size choices target/target+flankers
    cueSizeProb = [.5 .5];
    
    % ensemble info
    ensembleMeanCh = [0 45 90]; %parallel/neutral/orthogonal conditions
    ensembleMeanProb = ones(1,3)/3;
    sigma = 45;
    
    % session info
    if sessionNumber == "1"
        taskType = "target";
        expInstruct = load('instructions/ensemble_cueing_instruction_frames_session1.mat');
        expInstruct = expInstruct.instructions;
        
    elseif sessionNumber == "2"
        % reverses the target/ ensemble mean relationships
        taskType = "ensemble";
        expInstruct = load('instructions/ensemble_cueing_instruction_frames_session2.mat');
        expInstruct = expInstruct.instructions;
    end


    InstructBlock = WaitScreen(window, windowRect, '', 70, expInstruct);
    
    % practice blocks
    pBlock1 = CueEnsembleTrial(window, windowRect, diameter, spacing, ...
                         cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ...
                         ensembleMeanProb, ensembleMeanCh, sigma, taskType, ...
                         isiTime, 1, 1, 1);
    pWait2 = Wait;
    pWait2.displayText = ['Practice Trials' Wait.displayText];
    
    pBlock2 = CueEnsembleTrial(window, windowRect, diameter, spacing, ...
                         cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ...
                         ensembleMeanProb, ensembleMeanCh, sigma, taskType, ...
                         isiTime, cueTime, soaTime, stimTime); 
    
    EndPractice = Wait;

    % append the practice to the experiment                  
    Exp.append_block('exp_instructions', InstructBlock, 0);    
    Exp.append_block("block_p1", pBlock1, 8);
    Exp.append_block("wait_p2", pWait2, 0);
    Exp.append_block("block_p2", pBlock2, nPracticeTrials);
    Exp.append_block("end_practice", EndPractice, 0);

    % append full experiment blocks
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
                         CueEnsembleTrial(window, windowRect, diameter, spacing, ...
                         cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ...
                         ensembleMeanProb, ensembleMeanCh, sigma, taskType, ...
                         isiTime, cueTime, soaTime, stimTime), nTrialsPerBlock)
    end

    EndWait = Wait;
    EndWait.displayText = 'You Are Done!';
    Exp.append_block("end_screen", EndWait, 0);
    
else
    % load in from checkpoint 
    Exp = load([sessionDir '/Experiment.mat']);
    Exp = Exp.Exp;
    if restartBlock == 'y'
        Exp.checkpoint.trial = 1;
    end
    checkpointBlock = Exp.checkpoint.block;
    checkpointTrial = Exp.checkpoint.trial;
end

% run the experiment
blockIndices = fields(Exp.blocks)';

if skipPractice == 'n'
    % run practice
    Exp.run(blockIndices(1:4), [sessionDir '/Experiment.mat'])
    % print the practice trial accuracy
    practice_results = Exp.save_run('', blockIndices(4));
    Exp.blocks.end_practice.displayText = sprintf('Practice Complete \n Accuracy = %4.2f', ...
        mean(practice_results.correct));
    Exp.run(blockIndices(5), [sessionDir '/Experiment.mat']);
    % load back in the checkpoint
    if continueFromCheckpoint == 'y'
        Exp.checkpoint.block = checkpointBlock;
        Exp.checkpoint.trial = checkpointTrial;
    end
end
% run full experiment
Exp.run(blockIndices(6:length(blockIndices)), [sessionDir '/Experiment.mat']);     

sca;
% save the full experiment 
save([sessionDir '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run([sessionDir '/experiment_results.mat'], ...
    blockIndices(3:length(blockIndices)));

    