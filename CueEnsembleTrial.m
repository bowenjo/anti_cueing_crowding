classdef CueEnsembleTrial < CueTrial
    % Class for cueing crowded stimuli with ensemble statistics
    properties
        cueSizeProb % array - cue size proportions
        cueSizeChoice % array - cue size choices
        targetEnsembleRelationProb % ensemble mean offset proportions
        targetEnsembleRelationChoice % ensemble mean offsets
        ensembleSigma % std dev of the gaussian for choosing flankers 
        taskType % string - target or ensemble discrimination task
    end
    
    methods
        function self = CueEnsembleTrial(window, windowRect, diameter, ...
                spacing, cuedLocProb, cueValidProb, cueSizeProb, cueSizeChoice, ...
                targetEnsembleRelationProb, targetEnsembleRelationChoice, ensembleSigma, taskType, ...
                isiTime, cueTime, soaTime, stimTime)
            % -------------------------------------------
            % construct an instance of the classs
            % -------------------------------------------
            self = self@CueTrial(window, windowRect, diameter, cuedLocProb, ...
                cueValidProb, [1], [spacing], isiTime, cueTime, soaTime, stimTime);
            
            self.cueSizeProb = cueSizeProb;
            self.targetEnsembleRelationProb = targetEnsembleRelationProb;
            self.cueSizeChoice = cueSizeChoice;
            self.targetEnsembleRelationChoice = targetEnsembleRelationChoice;
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
            % target-ensemble relationship
            targetEnsembleRelationOrdered = random_sample(nTrials, ...
                self.targetEnsembleRelationProb, self.targetEnsembleRelationChoice, true);
            
            % get cue sizes and validity dependent on ensemble mean
            nTrialsPerTargetEnsembleRelation = round(nTrials/length(self.targetEnsembleRelationChoice));            
            cueSizeOrdered = []; 
            for i = 1:length(self.targetEnsembleRelationChoice)
                cueSizePerTargetEnsembleRelation = random_sample(nTrialsPerTargetEnsembleRelation, ...
                    self.cueSizeProb, self.cueSizeChoice, true);
                cueSizeOrdered = [cueSizeOrdered cueSizePerTargetEnsembleRelation];
            end
            nTrialsPerCueSize = round(nTrialsPerTargetEnsembleRelation/length(self.cueSizeChoice));
            validOrdered = [];
            for i = 1:(length(self.targetEnsembleRelationChoice) * length(self.cueSizeChoice))
                validPerCueSize = random_sample(nTrialsPerCueSize, ...
                    [self.cueValidProb, 1-self.cueValidProb], [1, 0], true);  
                validOrdered = [validOrdered validPerCueSize];
            end
            
            permIndices = randperm(length(targetEnsembleRelationOrdered));
            self.expDesign.target_ensemble_relation = targetEnsembleRelationOrdered(permIndices);
            self.expDesign.cue_size = cueSizeOrdered(permIndices);
            self.expDesign.valid = validOrdered(permIndices); 
            
            % get the flanker orientations from the mean and target
            totalNumFlankers = self.nFlankers*self.nFlankerRepeats;
            self.expDesign.F = nan(totalNumFlankers, nTrials);
            ensembleMean = nan(1, length(self.expDesign.T));
            for i = 1:nTrials
                target = self.expDesign.T(i);
                meanOffset = self.expDesign.target_ensemble_relation(i);
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
                end
                ensembleMean(i) = meanTrial;
            end
            
            if self.taskType == "target"
                self.expDesign.ensemble_mean = ensembleMean;
            elseif self.taskType == "ensemble"
                self.expDesign.ensemble_mean = self.expDesign.T;
                self.expDesign.T = ensembleMean;
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
            if self.taskType == "target"
                self.expDesign.correct = self.expDesign.response == self.expDesign.T;
            elseif self.taskType == "ensemble"
                self.expDesign.correct = self.expDesign.response == self.expDesign.ensemble_mean;
            end
            % dump results for block into the rest of the blocks
            keys = {'response', 'RT', 'pre_fix_check', 'post_fix_check', ...
                    'T', 'valid', 'ensemble_mean', 'cue_size', ...
                    'target_ensemble_relation', 'correct'};
        end
    end
end

