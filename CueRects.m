classdef CueRects < TrialModule & CueRectsParams
    % CueRects: Class for running an attention anti-cueing experiments
    
    properties
        % data randomization info
        cuedRectProb % array - size(1,nRects) - probablity rectangle will be cued
        cueValidProb % float (0,1) - probability cue will be valid
        spacingProb % array - size(spacingChoice) - probability of element in spacingChoice
        orientProb % array - size(orientChoice) - probability of element in orientChoice
        
        % data choices
        spacingChoice % array - size(1, n) - the spacing choices
        orientChoice % array - size(1, k) - the target and flanker orientation choices

        % timing information
        ifi % inter-frame interval time
        isiFrames % int - number frames of fixation before cue 
        cueFrames % int - number frames during cue
        soaFrames % int - number frames after the cue 
        stimFrames % int - number frames during stimulus
        
        isiTime % int - number secs of fixation before cue
        cueTime % int - nimber secs during cue
        soaTime % int - number secs after the cue
        stimTime % int - number secs during stimulus
        
      
    end
    
    methods
        function self = CueRects(window, windowRect, cuedRectProb, ...
                cueValidProb, spacingProb, orientProb, spacingChoice, ...
                orientChoice, isiTime, cueTime, soaTime, stimTime)
            
            %CueRects Construct an instance of this class
            self = self@TrialModule(window, windowRect);
            self = self@CueRectsParams();
            
            % data randomization information
            self.cuedRectProb = cuedRectProb;
            self.cueValidProb = cueValidProb;
            self.spacingProb = spacingProb;
            self.orientProb = orientProb;
            
            % data choices 
            self.spacingChoice = spacingChoice;
            self.orientChoice = orientChoice;
            
            % timing information
            self.isiTime = isiTime;
            self.cueTime = cueTime;
            self.soaTime = soaTime;
            self.stimTime = stimTime;
            
            self.ifi = Screen('GetFlipInterval', window);
            self.isiFrames = round(isiTime / self.ifi);
            self.cueFrames = round(cueTime / self.ifi);
            self.soaFrames = round(soaTime / self.ifi);
            self.stimFrames = round(stimTime / self.ifi);
            
        end
        
        function set_exp_design(self, nTrials) 
            % Sets and randomizes cue and stimulus presentation info for
            % each trial
            % cue locations for the each trial
            self.expDesign('cue_loc') = random_sample(nTrials, ...
                self.cuedRectProb, 1:self.nRects);
            % cue validity for each trial
            self.expDesign('valid') = random_sample(nTrials,...
                [self.cueValidProb, 1-self.cueValidProb], [1 0]);
            % target-flanker spacing for each trial
            self.expDesign('spacing') = random_sample(nTrials,...
                self.spacingProb, self.spacingChoice); 
            % target and flanker orientations for each trial
            for key =  {'T_orient', 'L_orient', 'R_orient'} 
                self.expDesign(char(key)) = random_sample(nTrials,...
                    self.orientProb, self.orientChoice);
            end
        end
        
        function set_results_matrix(self, nTrials)
            nMetrics = 3; % response key and reaction time
            self.results = zeros(nMetrics, nTrials);
        end
        
        function [cuedRect, postRect] = get_cue(self, idx)
            % gets the cued rect index and the stimulus rect index for each
            % trial depending on if it is a valid or non-valid trial
            
            % get the cued rectangle index
            cuedLocs = self.expDesign('cue_loc');
            cuedRect = cuedLocs(idx);
            % pick post cue rect given validity information
            oppRect = self.postCuedRect(cuedRect);
            validity = self.expDesign('valid');
            if validity(idx)
                postRect = oppRect; % if valid, display in opposite rect
            else
                postRect = cuedRect; % otherwise, display in same rect
            end
        end
        
        function [] = cue_rect(self, cuedRect)
            % highlights the cued rectangle with a different width and
            % get the rectangle luminance and width info
            lums = repmat(self.nonCueLum, 3, self.nRects);
            lineWidths = repmat(self.nonCueWidth, 1, self.nRects);
            % change the luminance and width if a cue is present
            if cuedRect ~= 0 
                lums(:, cuedRect) = repmat(self.cueLum, 3, 1);
                lineWidths(cuedRect) = self.cueWidth;
            end
            % Display the rects
            Screen('FrameRect', self.window, lums, self.rects,...
                lineWidths);
        end
        
        function [dest] = get_destination(self, rectIdx, offset)
            radius = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter/2);
            
            x1 = (self.xPos(rectIdx) - offset(1)) - radius;
            y1 = (self.yPos(rectIdx) - offset(2)) - radius;
            x2 = (self.xPos(rectIdx) - offset(1)) + radius;
            y2 = (self.yPos(rectIdx) - offset(2)) + radius;
            dest = [x1 y1 x2 y2];
        end
        
        function [stimuli, dests] = make_stimuli(self, idx, rectIdx)
            % make the gratings textures
            keys =  {'T_orient', 'L_orient', 'R_orient'};
            trialOrientations = zeros(1, 3);
            for i = 1:3 
                orientations = self.expDesign(char(keys(i)));
                trialOrientations(i) = orientations(idx);
            end
            stimuli = make_grating(self.window, trialOrientations,...
                self.diameter, self.spatialFrequency, self.contrast, ...
                self.subjectDistance, self.physicalWidthScreen, self.xRes);
            
            % get the destinations
            dests = zeros(3, 4);
            s = self.expDesign('spacing');
            dests(1,:) = self.get_destination(rectIdx, [0,0]); %target
            sTrial = angle2pix(self.subjectDistance, self.physicalWidthScreen, ...
                self.xRes, s(idx));
            if sTrial == 0
                stimuli = stimuli(1); % just get the target for 0 spacing 
            else
                dests(2,:) = self.get_destination(rectIdx, [sTrial,0]); %left flanker
                dests(3,:) = self.get_destination(rectIdx, [-sTrial,0]); %right flanker
            end
        end
            
        function [] = place_stimuli(self, stimuli, dests)
            for i = 1:length(stimuli)
                Screen('DrawTexture', self.window, stimuli(i),[], dests(i,:));
            end
        end
        
        function [responseKey, responseTime] = get_key_response(self)
            respToBeMade = true;
            timeStart = GetSecs;
            % wait for subject response
            while respToBeMade
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(self.leftKey)
                    responseKey = 0;
                    respToBeMade = false;
                elseif keyCode(self.rightKey)
                    responseKey = 1;
                    respToBeMade = false;
                elseif keyCode(self.escapeKey)
                    ShowCursor;
                    sca;
                    return
                end
            end
            responseTime = secs - timeStart;
        end
        
        function forward(self, idx, vbl, nTrials)
            % Initialize the trial
            [cueIndex, postCueIndex] = self.get_cue(idx);
            [stimuli, dests] = self.make_stimuli(idx, postCueIndex);
            % Eyelink stuff
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            for i = 1:self.isiFrames
                self.draw_fixation();
                self.cue_rect(0);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Cue Interval
            for i = 1:self.cueFrames
                self.draw_fixation();
                self.cue_rect(cueIndex);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Onset Asynchrony Interval
            for i = 1:self.soaFrames
                self.draw_fixation();
                self.cue_rect(0);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            fix = checkFix(self.el, self.fixLoc);
            for i = 1:self.stimFrames
                self.draw_fixation()
                self.cue_rect(0)
                self.place_stimuli(stimuli, dests);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Response interval
            self.draw_fixation()
            self.cue_rect(0)
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();
            % append the resonse data
            self.results(1, idx) = rsp;
            self.results(2, idx) = rt;
            self.results(3, idx) = fix;
        end 
        
        function [updatedResults, keys] = dump_results_info(self, currentResults)
            keys = {'rsp_key'; 'RT'; 'fix_check'; 'target_key'; 'spacing'; ...
                    'valid'; 'valid_prob'; 'soa_time'};
            nTrials = size(self.results);
            nTrials = nTrials(2);
            
            newResults = self.results;
            newResults(4,:) = self.expDesign('T_orient') == 45;
            newResults(5,:) = self.expDesign('spacing');
            newResults(6,:) = self.expDesign('valid');
            newResults(7,:) = ones(1, nTrials) .* self.cueValidProb;
            newResults(8,:) = ones(1, nTrials) .* (self.soaTime);
            
            updatedResults = [currentResults newResults];
        end     
        
    end
end

