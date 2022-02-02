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

% Ask for session ID
sessionNumber = input('Session #: ', 's');
sessionDir = [subjectDir '/' sessionNumber];
if ~exist(sessionDir, 'dir')
    mkdir(sessionDir)
end

% if an experiment already exists
continueFromCheckpoint = 'n'; skipPractice = 'n';
if exist([sessionDir '/Experiment.mat'], 'file') 
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
    

% ===================================================
% Main experiment
% ===================================================
if continueFromCheckpoint == 'n'
    % Experiment Parameters
    cueTime = 40/1000;
    soaTime = 40/1000 ;
    stimTime = 133/1000;
    isiTime = 1.2;
    cuedLocProb = [.5 .5];
    cueValidProb = .5;
    diameter = .85;
    spacing = 2; % fixed spacing
    cueSizeCh = [diameter, 4*spacing + diameter]; % cue size choices target/target+flankers
    cueSizeProb = [.5 .5];
    ensembleMeanCh = [0 22.5 45 67.5 90]; %target/ensemble relationship conditions
    ensembleMeanProb = ones(1,5)./5 ; 
    targetLocCh = [6, 7, 10, 11];
    targetLocProb = [.25, .25, .25, .25];
    sigma = 45; 

    % Practice-specific parameters
    ensembleMeanProbPractice = [0 0 1 0 0]; % only the neutral condition
    practicePerfCheck = .70;

    % Trials
    nTrialsTotal = 960;
    nTrialsPerBlock = 120;
    nBlocks = nTrialsTotal/nTrialsPerBlock;
    nPraciticeTrials = 50;

    Exp = Experiment();

    % instructions
    % expInstruct = load('instructions/uniform_cueing_instruction_frames.mat');
    % expInstruct = expInstruct.instructions;
    InstructBlock = Wait; %WaitBlock(window, windowRect, '', 70, expInstruct);

    % practice blocks
    pBlock1 = CueEnsembleUniformTrial(window, windowRect, diameter, spacing, ...
                         cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ensembleMeanProb, ...
                         ensembleMeanCh, targetLocProb, targetLocCh, sigma, ...
                         isiTime, 1, 1, 1);

    pWait2 = Wait;
    pWait2.displayText = ['Practice Trials' Wait.displayText];

    pBlock2 = CueEnsembleUniformTrial(window, windowRect, diameter, spacing, ...
                         cuedLocProb, cueValidProb, cueSizeProb, cueSizeCh, ensembleMeanProbPractice, ...
                         ensembleMeanCh, targetLocProb, targetLocCh, sigma, ...
                         isiTime, cueTime, soaTime, stimTime);

    EndPractice = Wait;

    % append practice
    Exp.append_block('exp_instructions', InstructBlock, 0)
    Exp.append_block('block_p1', pBlock1, 8)
    Exp.append_block('wait_p2', pWait2, 0)
    Exp.append_block('block_p2', pBlock2, nPraciticeTrials)
    Exp.append_block('end_practice', EndPractice, 0)

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
    
else
    Exp = load([sessionDir '/Experiment.mat']);
    Exp = Exp.Exp;
    if restartBlock == 'y'
        Exp.checkpoint.trial = 1;
    end
    checkpointBlock = Exp.checkpoint.block;
    checkpointTrial = Exp.checkpoint.trial;
end

% Run the experiment
blockIndices = fields(Exp.blocks)';

if skipPractice == 'n'
    % Instructions
    Exp.run(blockIndices(1:2), [sessionDir '/Experiment.mat'])

    % Practice blocks for session 1
    if sessionNumber == 1
        practicePerf = 0;
        while practicePerf < practicePerfCheck
            % run practice
            Exp.checkpoint_block = {'pWait2'}; % reset checkpoint
            Exp.run(blockIndices(3:4), [sessionDir '/Experiment.mat'])
            % print the practice trial accuracy
            practice_results = Exp.save_run('', blockIndices(4));
            practicePerf = mean(practice_results.correct);

            Exp.blocks.end_practice.displayText = sprintf('Practice Complete \n Accuracy = %4.2f', ...
                practicePerf);
            Exp.run(blockIndices(5), [sessionDir '/Experiment.mat']);
        end
        
        if continueFromCheckpoint == 'y'
            Exp.checkpoint.block = checkpointBlock;
            Exp.checkpoint.trial = checkpointTrial;
        end
    end
end

Exp.run(blockIndices(6:end), [sessionDir '/Experiment.mat'])
sca;

% save the full experiment 
save([sessionDir '/Experiment.mat'], 'Exp')
% save the results in a readible format
results = Exp.save_run([sessionDir '/experiment_results.mat'], ...
    blockIndices(6:end));

