classdef GratingThreshTrial < CueTrial
    % Class for determining a threshold for a grating stimulus presented 
    % at some eccentricity. Implements a nUp-nDown staircase
    
    % TODO: put a check so the diameter doesn't go < 0
    
    properties
        threshType % str - the parameter being staircased
        initSize % float - initial point of the staircase
        stepSize % float -staicase step size 
        nUp % int - number of consecutive correct trials to move up
        nDown % int - number of consecutive correct triaks to move down
        %TODO: rename "up" to "forward" and "down" to "back"
        fixationColors
        practice 
    end
    
    methods
        function self = GratingThreshTrial(window, windowRect, ...
                threshType, initSize, stepSize, nUp, nDown, ...
                fixationColors, stimTime, displaySide, practice)
            % -------------------------------------------------------
            % Construct an instance of this class
            % -------------------------------------------------------
            self = self@CueTrial(window, windowRect, 1, displaySide, ...
                0, [1], [Inf], 1, 0, 0, stimTime);
            
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
            
            if self.threshType == "ensemble_sigma"
                self.expDesign.F = [];
            end
        end
        
        function [stimuli, dests] = make_grating_stimuli(self, idx, rectIdx)
            % ----------------------------------------------------------
            % updates the size of and makes a single grating
            % ----------------------------------------------------------
            self.diameter = self.expDesign.grating_size(idx);
            self.spatialFrequency = self.cyclesPerGrating/self.diameter;
            [stimuli, dests] = self.make_stimuli(idx, rectIdx);
        end
        
        function [stimuli, dests] = make_ensemble_stimuli(self, idx, rectIdx)
            % ------------------------------------------------------------
            % updates the ensemble mu and sigma
            % ------------------------------------------------------------
            sigma = self.expDesign.ensemble_sigma(idx);
            target = self.expDesign.T(idx);
            totalNumFlankers = self.nFlankers*self.nFlankerRepeats;
            self.expDesign.F(:, idx) = pick_ensemble_flankers(totalNumFlankers, ...
                    target, target, sigma, 0, 180); 
            [stimuli,dests] = self.make_stimuli(idx, rectIdx);
        end
            
        
        function [rsp] = forward(self, idx, nTrials)
            % ----------------------------------------------------------
            % runs one complete trial and records the response variables
            % ---------------------------------------------------------- 
            
            % set the grating sizes before the first trial
            if idx == 1
                self.init_grating()
            else
                correctTrial = self.expDesign.T == self.expDesign.response;
                % get the direction of the step
                if self.threshType == "ensemble_sigma"
                    direction = "up";
                else
                    direction = "down";
                end
                % set the next step in the staircase
                self.expDesign.(string(self.threshType)) = self.staircase_step(...
                    self.expDesign.(string(self.threshType)), correctTrial, direction);

                if self.threshType == "spacing"
                    % ensure targets don't overlap with flankers
                    self.expDesign.spacing(idx) = max(self.diameter, ...
                        self.expDesign.spacing(idx));
                    % ensure targets don't overlap with eachother
                    self.expDesign.spacing(idx) = max( (self.diameter*sqrt(2))/(2*sin(pi/self.nFlankers)), ...
                        self.expDesign.spacing(idx) );
                end
            end
            
            % end the experiment if it's a practice trial and the number of 
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
                self.set_position_params(self.diameter, [0,0]) % resets the vline params to fit new size
            elseif self.threshType == "spacing"
                [stimuli, dests] = self.make_stimuli(idx, placeIdx);
            elseif self.threshType == "ensemble_sigma"
                [stimuli, dests] = self.make_ensemble_stimuli(idx, placeIdx);
            end
            
            preFixationChecks = zeros(1, self.isiFrames);
            postFixationChecks = zeros(1, self.stimFrames);
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            cueOffset = self.expDesign.cue_offset(:,idx);
            vbl = Screen('Flip', self.window);
            for i = 1:self.isiFrames
                self.draw_fixation(self.fixationColors(1, :));
                self.cue(0, self.diameter, cueOffset)
                preFixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation(self.fixationColors(2, :))
                self.cue(0, self.diameter, cueOffset)
                self.place_stimuli(stimuli, dests);
                postFixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            
            % Response interval
            self.draw_fixation(self.fixationColors(3, :))
            self.cue(0, self.diameter, cueOffset)
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();
            
            self.draw_fixation(self.fixationColors(4, :))
            self.cue(0, self.diameter, cueOffset)
            Screen('Flip', self.window);

            % append the response data
            preFix = mean(preFixationChecks == 1);
            postFix = mean(postFixationChecks == 1);
            self.expDesign.response(idx) = rsp;
            self.expDesign.RT(idx) = rt;
            self.expDesign.pre_fix_check(idx) = preFix;
            self.expDesign.post_fix_check(idx) = postFix;
            Screen('Close', stimuli)     
        end
        
        function [keys] = dump_results_info(self)
            % ------------------------------------------------------
            % dumps the results of the block to the full experiment
            % ------------------------------------------------------
            self.expDesign.correct = self.expDesign.response == self.expDesign.T;
            keys = {'response', 'RT', 'pre_fix_check', 'post_fix_check', ...
                    'T', self.threshType, 'correct'};            

        end  
        
        function pFit = get_size_thresh(self, pInit, resultsStruct)
            % -----------------------------------------------------
            % Fits and draws a psychometric function to find a threshold
            % -----------------------------------------------------
            % get accuracy results from the trials
            accuracy = analyze_results(resultsStruct, self.threshType, ...
                {'correct'}, {}, [], {}, @mean);
            count = analyze_results(resultsStruct, self.threshType, ...
                {'correct'}, {}, [], {}, @length);
            % make the results structure
            results.x = accuracy.(string(self.threshType)); % the x-values
            results.w = count.correct ./ sum(count.correct); % weighted by number of trials
            results.y = accuracy.correct; % the y-values
            
            % fit psychometric function to find theshold
            variables = {'t', 'b'};
            pFit = minimize_objective(variables, [], [], @log_likelihood,...
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

