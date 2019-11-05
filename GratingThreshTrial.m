classdef GratingThreshTrial < CueTrial
    % Class for determining a threshold for a grating stimulus presented 
    % at some eccentricity. Implements a nUp-nDown staircase
    
    properties
        threshType % str - the parameter being staircased
        initSize % float - initial point of the staircase
        stepSize % float -staicase step size 
        nUp % int - number of consecutive correct trials to move up
        nDown % int - number of consecutive correct triaks to move down
        fixationColors
        practice
    end
    
    methods
        function self = GratingThreshTrial(window, windowRect, ...
                threshType, initSize, stepSize, nUp, nDown, ...
                fixationColors, stimTime, practice)
            % -------------------------------------------------------
            % Construct an instance of this class
            % -------------------------------------------------------
            self = self@CueTrial(window, windowRect, 1, [0 1], ...
                1, [1], [Inf], 1, 0, 0, stimTime);
            
            self.threshType = threshType;
            self.initSize = initSize;
            self.stepSize = stepSize;
            self.nUp = nUp;
            self.nDown = nDown;
            self.fixationColors = fixationColors;
            self.practice = practice;
        end
        
        function init_grating(self)
            % ---------------------------------------------------------
            % initializes the parameter to be staircased
            % ---------------------------------------------------------
            self.expDesign.(string(self.threshType)) = [self.initSize];
        end
        
        function [stimuli, dests] = make_grating_stimuli(self, idx, rectIdx)
            % ----------------------------------------------------------
            % updates the size of and makes a single grating
            % ----------------------------------------------------------
            self.diameter = self.expDesign.grating_size(idx);
            self.spatialFrequency = self.cyclesPerGrating/self.diameter;
            [stimuli, dests] = self.make_stimuli(idx, rectIdx);
        end
            
        
        function [vbl,rsp] = forward(self, idx, vbl, nTrials)
            % ----------------------------------------------------------
            % runs one complete trial and records the response variables
            % ---------------------------------------------------------- 
            
            % set the grating sizes before the first trial
            if idx == 1
                self.start_countdown(5);
                %self.start_screen(KbName('Space'));
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
            
            % end the experiment if its a practice trial and the number of 
            % correct trials in a row are met
            if idx > 1
                if self.practice && self.expDesign.(string(self.threshType))(idx) < ...
                        self.expDesign.(string(self.threshType))(idx-1)
                    rsp = "skip";
                    return
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
                self.draw_fixation(self.fixationColors(1, :));
                self.cue_vlines(0)
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation(self.fixationColors(2, :))
                self.cue_vlines(0)
                self.place_stimuli(stimuli, dests);
                fixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            
            % Response interval
            self.draw_fixation(self.fixationColors(3, :))
            self.cue_vlines(0)
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();
            
            self.draw_fixation(self.fixationColors(4, :))
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
            % ------------------------------------------------------
            % dumps the results of the block to the full experiment
            % ------------------------------------------------------
            self.expDesign.correct = self.expDesign.response == self.expDesign.T;
            keys = {'response', 'RT', 'fix_check', 'T', self.threshType, 'correct'};            

        end  
        
        function pFit = get_size_thresh(self, pInit, resultsStruct)
            % -----------------------------------------------------
            % Fits and draws a psychometric function to find a threshold
            % -----------------------------------------------------
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
            
            figure
            hold on
            x = linspace(0, max(results.x));
            scatter(results.x, results.y)
            scatter(pFit.t, pFit.a)
            plot(x, weibull(pFit, x)) 
            title(string(self.threshType))
            hold off
        end
    end
end

