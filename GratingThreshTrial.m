classdef GratingThreshTrial < CueTrial
    % Class for determining a threshold for a grating stimulus presented 
    % at some eccentricity. Implements a nUp-nDown staircase
    
    properties
        threshType
        initSize
        stepSize
        nUp
        nDown
        cyclesPerGrating
    end
    
    methods
        function self = GratingThreshTrial(window, windowRect, ...
                threshType, initSize, stepSize, nUp, nDown, ...
                cyclesPerGrating, stimTime)
            % Construct an instance of this class
            self = self@CueTrial(window, windowRect, [0 1], ...
                1, [1], [Inf], 1, 0, 0, stimTime);
            
            self.threshType = threshType;
            self.initSize = initSize;
            self.stepSize = stepSize;
            self.nUp = nUp;
            self.nDown = nDown;
            self.cyclesPerGrating = cyclesPerGrating;
        end
        
        function init_grating(self)
            self.expDesign.(string(self.threshType)) = [self.initSize];
        end
        
        function [stimuli, dests] = make_grating_stimuli(self, idx, rectIdx)
            self.diameter = self.expDesign.grating_size(idx);
            self.spatialFrequency = self.cyclesPerGrating/self.diameter;
            [stimuli, dests] = self.make_stimuli(idx, rectIdx);
        end
            
        
        function vbl = forward(self, idx, vbl, nTrials)
            % set the grating sizes before the first trial
            if idx == 1
                self.init_grating()
            else
                correctTrial = self.expDesign.T == self.expDesign.response;
                % set the next step in the staircase
                self.expDesign.(string(self.threshType)) = self.staircase_step(...
                    self.expDesign.(string(self.threshType)), correctTrial);
                
                if self.threshType == "spacing"
                    % ensure targets don't overlap with flankers
                    self.expDesign.spacing(idx) = max(self.diameter, ...
                        self.expDesign.spacing(idx));
                end
            end
            
            [~, placeIdx] = self.get_cue(idx);
            if self.threshType == "grating_size"
                [stimuli, dests] = self.make_grating_stimuli(idx, placeIdx);
                self.set_position_params() % resets the vline params to fit new size
            elseif self.threshType == "spacing"
                [stimuli, dests] = self.make_stimuli(idx, placeIdx);
            end

            fixationChecks = zeros(1, self.stimFrames);
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            for i = 1:self.isiFrames
                self.draw_fixation(.25);
                self.cue_vlines(0)
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation(.25)
                self.cue_vlines(0)
                self.place_stimuli(stimuli, dests);
                fixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            
            % Response interval
            self.draw_fixation(.25)
            self.cue_vlines(0)
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();
            
            self.draw_fixation(0)
            self.cue_vlines(0)
            Screen('Flip', self.window, vbl+self.ifi/2);

            % append the response data
            fix = mean(fixationChecks == 1);
            self.expDesign.response(idx) = rsp;
            self.expDesign.RT(idx) = rt;
            self.expDesign.fix_check(idx) = fix;
            Screen('Close', stimuli)     
        end
        
        function [keys] = dump_results_info(self)
            self.expDesign.correct = self.expDesign.response == self.expDesign.T;
            keys = {'response', 'RT', 'fix_check', 'T', self.threshType, 'correct'};            

        end  
        
        function pFit = get_size_thresh(self, pInit, resultsStruct)
            % get accuracy results from the trials
            accuracy = analyze_results(resultsStruct, self.threshType, ...
                {'correct'}, {}, [], @mean);
            count = analyze_results(resultsStruct, self.threshType, ...
                {'correct'}, {}, [], @length);
            % make the results structure
            results.x = accuracy.(string(self.threshType)); % the x-values
            results.w = count.correct ./ sum(count.correct); % weighted by number of trials
            results.y = accuracy.correct; % the y-values
            
            % fit psychometric function to find theshold
            variables = {'t', 'b'};
            pFit = minimize_objective(variables, @log_likelihood,...
                pInit, results, @weibull);
            
%             scatter(results.x, results.y)
%             hold
%             plot(results.x, weibull(pFit, results.x))   
        end
    end
end

