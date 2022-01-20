classdef CueEnsembleUniformTrial < CueTrial
    
    properties
        cueSizeProb % array - cue size proportions
        cueSizeChoice % array - cue size choices
        targetEnsembleRelationProb % ensemble mean offset proportions
        targetEnsembleRelationChoice % ensemble mean offsets
        targetLocProb % location of the target to be cued proportions
        targetLocChoice % location of the target to be cued choices
        ensembleSigma % std dev of the logarithmic for choosing flankers 
        
    end
    
    methods
        function self = CueEnsembleUniformTrial(window, windowRect, diameter, ...
                spacing, cuedLocProb, cueValidProb, cueSizeProb, cueSizeChoice, ...
                targetEnsembleRelationProb, targetEnsembleRelationChoice, ...
                targetLocProb, targetLocChoice, ensembleSigma, ...
                isiTime, cueTime, soaTime, stimTime)
            % -------------------------------------------
            % construct an instance of the classs
            % -------------------------------------------
            self = self@CueTrial(window, windowRect, diameter, cuedLocProb, ...
                cueValidProb, [1], [spacing], isiTime, cueTime, soaTime, stimTime);
            
            self.cueSizeProb = cueSizeProb;
            self.targetEnsembleRelationProb = targetEnsembleRelationProb;
            self.targetLocProb = targetLocProb;
            self.cueSizeChoice = cueSizeChoice;
            self.targetEnsembleRelationChoice = targetEnsembleRelationChoice;
            self.targetLocChoice = targetLocChoice;
            self.ensembleSigma = ensembleSigma;
            
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
            
            % target locations each trial
            self.expDesign.target_loc = random_sample(nTrials, ...
                self.targetLocProb, self.targetLocChoice, false);
            
            % ensemble orientations each trial
            self.expDesign.ensemble_mean = random_sample(nTrials, ...
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
            
            % cue offsets each trial
            self.expDesign.cue_offset = nan(2, nTrials);
            
            % get the flanker orientations from the mean and target
            totalNumFlankers = (self.nFlankers^2) - 1;
            self.expDesign.F = nan(totalNumFlankers, nTrials);
            targetOrientations = nan(1, nTrials);
            for i = 1:nTrials
                ensembleMean = self.expDesign.ensemble_mean(i);
                meanOffset = self.expDesign.target_ensemble_relation(i);
                if ensembleMean == 45
                    targetTrial = ensembleMean + meanOffset;
                elseif ensembleMean == 135
                    targetTrial = ensembleMean - meanOffset;
                end
                self.expDesign.F(:,i) = pick_ensemble_flankers(totalNumFlankers, ...
                    targetTrial, ensembleMean, self.ensembleSigma, 0 ,180);
                targetOrientations(i) = targetTrial;
                
                % cue offsets
                offsets = self.get_offsets(self.spacingChoice, i);
                self.expDesign.cue_offset(:,i) = offsets(:,1);
            end
            
            self.expDesign.T = targetOrientations;
            
            % initialize result fields
            for key = {'response', 'RT', 'pre_fix_check', 'post_fix_check'}
                self.expDesign.(string(key)) = nan(1,nTrials);
            end
            
        end
        
        function [offsets] = get_offsets(self, spacing, idx)
            % ----------------------------------------------------------
            % Gets the uniform flanker offsets for the given spacing
            % ----------------------------------------------------------
            center = (self.nFlankers + 1) / 2;
            [X,Y] = meshgrid(1:self.nFlankers, 1:self.nFlankers);
            allOffsets = [reshape(spacing .* (X - center), 1, []);
                       reshape(spacing .* (Y - center), 1, [])]; 
            % re-order for correct target locations
            t = self.expDesign.target_loc(idx);
            offsets = [allOffsets(:,t) allOffsets(:,1:t-1) allOffsets(:,t+1:end)];
            
        end

        
        function [keys] = dump_results_info(self)
            % -------------------------------------------------------------
            % dumps the block specific results into the results of the full
            % experiment
            % -------------------------------------------------------------
            self.expDesign.correct = self.expDesign.response == self.expDesign.ensemble_mean;
            % dump results for block into the rest of the blocks
            keys = {'response', 'RT', 'pre_fix_check', 'post_fix_check', ...
                    'T', 'valid', 'ensemble_mean', 'cue_size', ...
                    'target_ensemble_relation', 'correct'};
        end
    end
end

