classdef GratingThreshTrial < CueTrial
    % Class for determining a threshold for a grating stimulus presented 
    % at some eccentricity
    
    properties
        sizeChoice % grating size choices
        sizeProb % grating size probabilities corresponding to choices
        cyclesPerGrating
    end
    
    methods
        function self = GratingThreshTrial(window, windowRect, sizeChoice, ... 
                sizeProb, cyclesPerGrating, stimTime)
            % Construct an instance of this class
            self = self@CueTrial(window, windowRect, [0 1], ...
                1, [1], [Inf], 1, 0, 0, stimTime);
            
            self.sizeChoice = sizeChoice;
            self.sizeProb = sizeProb;
            self.cyclesPerGrating = cyclesPerGrating;
        end
        
        function set_grating_sizes(self, nTrials)
            self.expDesign('grating_size') = random_sample(nTrials, ...
                self.sizeProb, self.sizeChoice, false);
        end
        
        function [stimuli, dests] = make_grating_stimuli(self, idx, rectIdx)
            sizes = self.expDesign('grating_size');
            self.diameter = sizes(idx);
            self.spatialFrequency = self.cyclesPerGrating/self.diameter;
            [dests, stimuli] = self.make_stimuli(idx, rectIdx);
        end
            
        
        function forward(self, idx, vbl, nTrials)
            % set the grating sizes before the first trial
            if idx == 1
                self.set_grating_sizes(nTrials)
            end
            
            [~, placeIdx] = self.get_cue(idx);
            [dests, stimuli] = self.make_grating_stimuli(idx, placeIdx);
            fixationChecks = zeros(1, self.stimFrames);
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            for i = 1:self.isiFrames
                self.draw_fixation();
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation()
                self.place_stimuli(stimuli, dests);
                fixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            
            % Response interval
            self.draw_fixation()
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();

            % append the resonse data
            fix = mean(fixationChecks == 1);
            self.results(1, idx) = rsp;
            self.results(2, idx) = rt;
            self.results(3, idx) = fix;  
            Screen('Close', stimuli)     
        end
        
        function [updatedResults, keys] = dump_results_info(self, currentResults)
            keys = {'rsp_key'; 'RT'; 'fix_check'; 'target_key'; 'grating_size'};            
            newResults = self.results;
            newResults(4,:) = self.expDesign('T') == 45;
            newResults(5,:) = self.expDesign('grating_size');
            
            updatedResults = [currentResults newResults];
        end  
        
        function threshSize = get_size_thresh(self, propCorrect, resultsTable)
            accuracyTable = analyze_results(resultsTable, [], []);
            accuracy = accuracyTable.Variables;
            sizes = accuracy(:,1);
            [~, thresh] = min(abs(accuracy(:,2) - propCorrect));
            threshSize = sizes(thresh);
        end

    end
end

