classdef GratingThreshTrial < CueTrial
    % Class for determining a threshold for a grating stimulus presented 
    % at some eccentricity. Implements a nUp-nDown staircase
    
    properties
        initSize
        stepSize
        nUp
        nDown
        cyclesPerGrating
    end
    
    methods
        function self = GratingThreshTrial(window, windowRect, initSize, ... 
                stepSize, nUp, nDown, cyclesPerGrating, stimTime)
            % Construct an instance of this class
            self = self@CueTrial(window, windowRect, [0 1], ...
                1, [1], [Inf], 1, 0, 0, stimTime);
            
            self.initSize = initSize;
            self.stepSize = stepSize;
            self.nUp = nUp;
            self.nDown = nDown;
            self.cyclesPerGrating = cyclesPerGrating;
        end
        
        function set_grating_sizes(self)
            self.expDesign('grating_size') = [self.initSize];
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
                self.set_grating_sizes()
            else
                targetKey = self.expDesign('T') == 45;
                correctTrial = self.results(1,:) == targetKey;
                % set the next step in the staircase
                self.expDesign('grating_size') = self.staircase_step(...
                    self.expDesign('grating_size'), correctTrial);
            end
            
            [~, placeIdx] = self.get_cue(idx);
            [dests, stimuli] = self.make_grating_stimuli(idx, placeIdx);
            self.set_position_params() % resets the vline params to fit new size
            fixationChecks = zeros(1, self.stimFrames);
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            for i = 1:self.isiFrames
                self.draw_fixation(0);
                self.cue_vlines(0)
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation(0)
                self.cue_vlines(0)
                self.place_stimuli(stimuli, dests);
                fixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            
            % Response interval
            self.draw_fixation([0 .40 0])
            self.cue_vlines(0)
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();

            % append the response data
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
        
        function threshSize = get_size_thresh(self, pInit, resultsTable)
            accuracyTable = analyze_results(resultsTable, [], []);
            accuracy = accuracyTable.Variables;
            
            % make the results structure
            results.x = accuracy(:,1);
            results.y = accuracy(:,2);
            
            % fit psychometric function to find theshold
            variables = {'t', 'b'};
            pFit = minimize_objective(variables, @log_likelihood,...
                pInit, results, @weibull);
            threshSize = pFit.t;
            
            scatter(results.x, results.y)
            hold
            plot(results.x, weibull(pFit, results.x))   
        end

    end
end

