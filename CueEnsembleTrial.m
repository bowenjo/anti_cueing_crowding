classdef CueEnsembleTrial < CueTrial
    % Class for cueing crowded stimuli with ensemble statistics
    properties
        cueSizeProb % array - cue size proportions
        cueSizeChoice % array - cue size choices
        ensembleMeanProb % ensemble mean offset proportions
        ensembleMeanChoice % ensemble mean offsets
        ensembleSigma % std dev of the gaussian for choosing flankers 
        taskType % string - target or ensemble discrimination task
    end
    
    methods
        function self = CueEnsembleTrial(window, windowRect, diameter, ...
                spacing, cuedLocProb, cueValidProb, cueSizeProb, cueSizeChoice, ...
                ensembleMeanProb, ensembleMeanChoice, ensembleSigma, taskType, ...
                isiTime, cueTime, soaTime, stimTime)
            % -------------------------------------------
            % construct an instance of the classs
            % -------------------------------------------
            self = self@CueTrial(window, windowRect, diameter, cuedLocProb, ...
                cueValidProb, [1], [spacing], isiTime, cueTime, soaTime, stimTime);
            
            self.cueSizeProb = cueSizeProb;
            self.ensembleMeanProb = ensembleMeanProb;
            self.cueSizeChoice = cueSizeChoice;
            self.ensembleMeanChoice = ensembleMeanChoice;
            self.ensembleSigma = ensembleSigma;
            self.taskType = taskType;
        end
        
        function set_exp_design(self, nTrials)
            % ----------------------------------------------------------
            % sets and randomizes cue and stimulus presentation info for
            % each trial
            % ----------------------------------------------------------
            % cue location each trial
            self.expDesign.cue_loc = random_sample(nTrials, ...
                self.cuedLocProb, 1:self.nLocs, false);
            
            % target-flanker spacing each trial 
            self.expDesign.spacing = repmat(self.spacingChoice, 1, nTrials);
            
            % target orientations each trial
            self.expDesign.T = random_sample(nTrials, ...
                    self.targetOrientProb, self.targetOrientChoice, false);  
            % ensemble mean
            ensembleMeanOrdered = random_sample(nTrials, ...
                self.ensembleMeanProb, self.ensembleMeanChoice, true);
            
            % get cue sizes and validity dependent on ensemble mean
            nTrialsPerEnsemble = round(nTrials/length(self.ensembleMeanChoice));            
            cueSizeOrdered = []; 
            for i = 1:length(self.ensembleMeanChoice)
                cueSizePerEnsembleMean = random_sample(nTrialsPerEnsemble, ...
                    self.cueSizeProb, self.cueSizeChoice, true);
                cueSizeOrdered = [cueSizeOrdered cueSizePerEnsembleMean];
            end
            nTrialsPerCueSize = round(nTrialsPerEnsemble/length(self.cueSizeChoice));
            validOrdered = [];
            for i = 1:(length(self.ensembleMeanChoice) * length(self.cueSizeChoice))
                validPerCueSize = random_sample(nTrialsPerCueSize, ...
                    [self.cueValidProb, 1-self.cueValidProb], [1, 0], true);  
                validOrdered = [validOrdered validPerCueSize];
            end
            
            permIndices = randperm(length(ensembleMeanOrdered));
            self.expDesign.ensemble_mean = ensembleMeanOrdered(permIndices);
            self.expDesign.cue_size = cueSizeOrdered(permIndices);
            self.expDesign.valid = validOrdered(permIndices); 
            
            % get the flanker orientations from the mean and target
            totalNumFlankers = self.nFlankers*self.nFlankerRepeats;
            self.expDesign.F = nan(totalNumFlankers, nTrials);
            newTargets = nan(1, length(self.expDesign.T));
            for i = 1:nTrials
                target = self.expDesign.T(i);
                meanOffset = self.expDesign.ensemble_mean(i);
                if target == 45
                    meanTrial = target + meanOffset;
                elseif target == 135
                    meanTrial = target - meanOffset;
                end
                
                if self.taskType == "target"
                    self.expDesign.F(:,i) = pick_ensemble_flankers(totalNumFlankers, ...
                        target, meanTrial, self.ensembleSigma, 0, 180);
                elseif self.taskType == "ensemble"
                    self.expDesign.F(:,i) = pick_ensemble_flankers(totalNumFlankers, ...
                        meanTrial, target, self.ensembleSigma, 0 ,180);
                    newTargets(i) = meanTrial;
                end
            end
            
            if self.taskType == "ensemble"
                self.expDesign.ensemble_mean = self.expDesign.T;
                self.expDesign.T = newTargets;
                self.expDesign.target_relation = ensembleMeanOrdered(permIndices);
            end
            
            % initialize result fields
            for key = {'response', 'RT', 'pre_fix_check', 'post_fix_check'}
                self.expDesign.(string(key)) = nan(1,nTrials);
            end
        end
        
        function [keys] = dump_results_info(self)
            % -------------------------------------------------------------
            % dumps the block specific results into the results of the full
            % experiment
            % -------------------------------------------------------------
            self.expDesign.correct = self.expDesign.response == self.expDesign.T;
            % dump results for block into the rest of the blocks
            keys = {'response', 'RT', 'pre_fix_check', 'post_fix_check', ...
                    'T', 'valid', 'ensemble_mean', 'cue_size', ...
                    'correct'};
        end
    end
end

