classdef CueTrial < TrialModule & CueTrialParams
    % CueRects: Class for running an attention anti-cueing experiments
    
    properties
        % data randomization info
        cuedLocProb % array - size(1,nLocs) - probablity rectangle will be cued
        cueValidProb % float (0,1) - probability cue will be valid
        spacingProb % array - size(spacingChoice) - probability of element in spacingChoice
        
        % data choices
        spacingChoice % array - size(1, n) - the spacing choices

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
        function self = CueTrial(window, windowRect, cuedLocProb, ...
                cueValidProb, spacingProb, spacingChoice, ...
                isiTime, cueTime, soaTime, stimTime)
            
            %CueRects Construct an instance of this class
            self = self@TrialModule(window, windowRect);
            self = self@CueTrialParams();
            self.set_position_params()
            
            % data randomization information
            self.cuedLocProb = cuedLocProb;
            self.cueValidProb = cueValidProb;
            self.spacingProb = spacingProb;
            
            % data choices 
            self.spacingChoice = spacingChoice;
            
            % timing information
            self.isiTime = isiTime;
            self.cueTime = cueTime;
            self.soaTime = soaTime;
            self.stimTime = stimTime;
            
            self.ifi = Screen('GetFlipInterval', window);
            self.isiFrames = round(isiTime / self.ifi);
            self.cueFrames = round(cueTime / self.ifi);
            self.soaFrames = round((soaTime - cueTime) / self.ifi);
            self.stimFrames = round(stimTime / self.ifi);
            
        end
        
        function set_exp_design(self, nTrials) 
            % Sets and randomizes cue and stimulus presentation info for
            % each trial
            % cue locations for the each trial
            self.expDesign('cue_loc') = random_sample(nTrials, ...
                self.cuedLocProb, 1:self.nLocs, false);
            
            % orientations
            % target orientation
            self.expDesign('T') = random_sample(nTrials,...
                    self.targetOrientProb, self.targetOrientChoice, false);
            % flanker orientations for each trial
            for key = self.flankerKeys  
               %self.expDesign(char(key)) = random_sample(nTrials,...
               %    self.flankerOrientProb, self.flankerOrientChoice);
               flankerChoices = randi([1, length(self.flankerOrientChoice)], 1, nTrials);
               self.expDesign(char(key)) = self.flankerOrientChoice(flankerChoices);
            end
            
            % choose validity dpendent on spacing
            % target-flanker spacing for each trial
            spacingOrdered = random_sample(nTrials,...
                self.spacingProb, self.spacingChoice, true);
            % cue validity for each spacing
            nTrialsPerSpacing = round(nTrials/length(self.spacingChoice));
            validOrdered = [];
            for i = 1:length(self.spacingChoice)
                validPerSpacing = random_sample(nTrialsPerSpacing,...
                    [self.cueValidProb, 1-self.cueValidProb], [1 0], true);
                validOrdered = [validOrdered validPerSpacing];
            end
            permIndices = randperm(length(spacingOrdered));
            self.expDesign('spacing') = spacingOrdered(permIndices);
            self.expDesign('valid') = validOrdered(permIndices);

        end
        
        function set_results_matrix(self, nTrials)
            nMetrics = 3; % response key, fixation, and reaction time
            self.results = nan(nMetrics, nTrials);
        end
        
        function [cuedLoc, postLoc] = get_cue(self, idx)
            % gets the cued rect index and the stimulus rect index for each
            % trial depending on if it is a valid or non-valid trial
            
            % get the cued rectangle index
            cuedLocs = self.expDesign('cue_loc');
            cuedLoc = cuedLocs(idx);
            % pick post cue rect given validity information
            oppLoc = self.postCuedLoc(cuedLoc);
            validity = self.expDesign('valid');
            if validity(idx)
                postLoc = oppLoc; % if valid, display in opposite rect
            else
                postLoc = cuedLoc; % otherwise, display in same rect
            end
        end
        
        function [] = cue_vlines(self, cuedLoc)
            % highlights the cued rectangle with a different width and
            % get the rectangle luminance and width info
            lums = repmat(self.nonCueLum, 3, self.nLocs*4);
            lineWidths = repmat(self.nonCueWidth, 1, self.nLocs*2);
            % change the luminance and width if a cue is present
            if cuedLoc ~= 0
                lineLoc = cuedLoc*2;
                lums(:, lineLoc*2-3:lineLoc*2) = repmat(self.cueLum, 3, 4);
                lineWidths(lineLoc-1:lineLoc) = repmat(self.cueWidth, 1, 2);
            end
            % Display the rects
            Screen('DrawLines', self.window, self.vLines, lineWidths,...
                lums, [self.xCenter self.yCenter]);
        end
        
        function [] = cue_dot(self, cuedLoc)
            radius = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter/2);
            
            dotLoc = [self.xPos(cuedLoc), self.yPos(cuedLoc)];
            Screen('DrawDots', self.window, ...
                dotLoc, radius, self.cueLum, [], 2);
        end
        
        
        function [dest] = get_destination(self, rectIdx, offset)
            % gets the destination of the stimuli with respect to the cue
            % location
            
            radius = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter/2);
            
            x1 = (self.xPos(rectIdx) - offset(1)) - radius;
            y1 = (self.yPos(rectIdx) - offset(2)) - radius;
            x2 = (self.xPos(rectIdx) - offset(1)) + radius;
            y2 = (self.yPos(rectIdx) - offset(2)) + radius;
            dest = [x1 y1 x2 y2];
        end
        
        function [dests, flankerIdx] = get_flanker_dests(self, dests, ...
                rectIdx, flankerIdx, offset)
            % gets the flanker destinations
            diameterPix = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter);
            
            loc = abs(offset) > 0;
            for i =  1:self.nFlankers
                flankerOffset = offset;
                if flankerOffset(loc) > 0
                    flankerOffset(loc) = flankerOffset(loc) + (i-1)*diameterPix;
                else
                    flankerOffset(loc) = flankerOffset(loc) - (i-1)*diameterPix;
                end
                dests(flankerIdx,:) = self.get_destination(rectIdx, flankerOffset); 
                flankerIdx = flankerIdx + 1;
            end    
        end
        
        function [stimuli, dests] = make_stimuli(self, idx, rectIdx)
            % make the gratings textures
            trialOrientations = zeros(1, self.totalNumFlankers+1);
            
            % get target orientation for the trial;
            tOrientations = self.expDesign('T');
            trialOrientations(1) = tOrientations(idx);
            
            % get the flanker orientations for the trial
            for i = 1:self.totalNumFlankers
                fOrientations = self.expDesign(char(self.flankerKeys(i)));
                trialOrientations(i+1) = fOrientations(idx);
            end
            stimuli = make_grating(self.window, trialOrientations,...
                self.diameter, self.spatialFrequency, self.contrast, ...
                self.subjectDistance, self.physicalWidthScreen, self.xRes);
            
            % get the spacing for the trial
            s = self.expDesign('spacing'); % spacing in DVA
            sTrial = angle2pix(self.subjectDistance, self.physicalWidthScreen, ...
                self.xRes, s(idx)); % get the spaincing in pixels
            
            % get the destinations for the trial
            dests = zeros(self.totalNumFlankers+1, 4);
            
            % set target destination
            dests(1,:) = self.get_destination(rectIdx, [0,0]); 
            
            % set flanker destination
            flankerIdx = 2;
            if self.flankerStyle == 't'
                % lower flanker(s)
                [dests, flankerIdx] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [0, sTrial]);
                % upper flankers(s)
                [dests, ~] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [0, -sTrial]);
            elseif self.flankerStyle == 'r'
                % right flanker(s)
                [dests, flankerIdx] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [sTrial, 0]);
                % left flankers(s)
                [dests, ~] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [-sTrial, 0]);
            elseif self.flankerStyle == 'b'
                % lower flanker(s)
                [dests, flankerIdx] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [0, sTrial]);
                % upper flankers(s)
                [dests, flankerIdx] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [0, -sTrial]);
                % right flanker(s)
                [dests, flankerIdx] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [sTrial, 0]);
                % left flankers(s)
                [dests, ~] = self.get_flanker_dests(...
                    dests, rectIdx, flankerIdx, [-sTrial, 0]);
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
                [~, secs, keyCode] = KbCheck;
                if keyCode(self.leftKey)
                    responseKey = 0;
                    respToBeMade = false;
                elseif keyCode(self.rightKey)
                    responseKey = 1;
                    respToBeMade = false;
                elseif keyCode(self.escapeKey)
                    Eyelink('StopRecording')
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
            fixationChecks = zeros(1, self.stimFrames);
            % Eyelink stuff
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            for i = 1:self.isiFrames
                self.draw_fixation();
                self.cue_vlines(0)
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Cue Interval
            for i = 1:self.cueFrames
                self.draw_fixation();
                self.cue_vlines(cueIndex);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Onset Asynchrony Interval
            for i = 1:self.soaFrames
                self.draw_fixation();
                self.cue_vlines(0)
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation()
                self.cue_vlines(0)
                self.place_stimuli(stimuli, dests);
                fixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Response interval
            self.draw_fixation()
            self.cue_vlines(0)
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
            keys = {'rsp_key'; 'RT'; 'fix_check'; 'target_key'; 'spacing'; ...
                    'valid'; 'valid_prob'; 'soa_time'};
            nTrials = size(self.results);
            nTrials = nTrials(2);
            
            newResults = self.results;
            newResults(4,:) = self.expDesign('T') == 45;
            newResults(5,:) = self.expDesign('spacing');
            newResults(6,:) = self.expDesign('valid');
            newResults(7,:) = ones(1, nTrials) .* self.cueValidProb;
            newResults(8,:) = ones(1, nTrials) .* (self.soaTime);
            
            updatedResults = [currentResults newResults];
        end     
        
    end
end

