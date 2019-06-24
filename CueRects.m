classdef CueRects < TrialModule
    % CueRects - Class for running an attention anti-cueing experiments
    
    properties
        % design information
        baseRect % array - size(1,4) - the base rectangles
        xPos % int - x-coordinate positions of the boxes in pixels
        yPos % int - y-coordinate positions of the boxes in pixels
        nRects % int - number of rectangles
        rects % the rectangle bounding box coordinates
       
        % cue information
        cueLum % float - cued rectangle luminance value
        nonCueLum % float - non-cued rectangle luminance value
        cueWidth % int - cued rectangle outline width in pixels
        nonCueWidth % int - non-cued rectangle outline width in pixels
        postCuedRect % array - size(1,nRects) - rectangle indices to present the stimuli following a cue 
        
        % data randomization info
        cuedRectProb % array - size(1,nRects) - probablity rectangle will be cued
        cueValidProb % float (0,1) - probability cue will be valid
        spacingProb % array - size(spacingChoice) - probability of element in spacingChoice
        orientProb % array - size(orientChoice) - probability of element in orientChoice
        
        % data choices
        spacingChoice % array - size(1, n) - the spacing choices
        orientChoice % array - size(1, k) - the target and flanker orientation choices
        
        % grating parameters
        spatialFrequency % float - spatial frequency of disparity grating
        diameter % float - diameter of disparity grating 
        contrast % float - contrast of disparity grating

        % timing information
        ifi % inter-frame interval time
        isiFrames % int - number frames of fixation before cue 
        cueFrames % int - number frames during cue
        soaFrames % int - number frames after the cue 
        stimFrames % int - number frames during stimulus
        
        % response information
        leftKey
        rightKey
        escapeKey
    end
    
    methods
        function self = CueRects(window, windowRect, baseRect, xPos, yPos, ...
                cueLum, nonCueLum, cueWidth, nonCueWidth, ...
                postCuedRect, cuedRectProb, cueValidProb, ...
                spacingProb, orientProb, spacingChoice, orientChoice,...
                spatialFrequency, diameter, contrast,...
                isiTime, cueTime, soaTime, stimTime)
            
            %CueRects Construct an instance of this class
            %   Detailed explanation goes here
            self = self@TrialModule(window, windowRect);
            self.baseRect = baseRect;
            self.xPos = xPos;
            self.yPos = yPos;
            self.nRects = length(xPos);
            
            % cue information
            self.cueLum = cueLum;
            self.nonCueLum = nonCueLum;
            self.cueWidth = cueWidth;
            self.nonCueWidth = nonCueWidth;
            self.postCuedRect = postCuedRect;
            
            % data randomization information
            self.cuedRectProb = cuedRectProb;
            self.cueValidProb = cueValidProb;
            self.spacingProb = spacingProb;
            self.orientProb = orientProb;
            
            % data choices 
            self.spacingChoice = spacingChoice;
            self.orientChoice = orientChoice;
            
            % Get the rects
            self.rects = nan(4,self.nRects);
            for i = 1:self.nRects
                self.rects(:, i) = CenterRectOnPointd(self.baseRect,...
                    self.xPos(i), self.yPos(i));
            end  
            
            % grating information
            self.spatialFrequency = spatialFrequency;
            self.diameter = diameter;
            self.contrast = contrast;
            
            % timing information
            self.ifi = Screen('GetFlipInterval', window);
            self.isiFrames = round(isiTime / self.ifi);
            self.cueFrames = round(cueTime / self.ifi);
            self.soaFrames = round(soaTime / self.ifi);
            self.stimFrames = round(stimTime / self.ifi);
            
            % response info
            self.escapeKey = KbName('ESCAPE');
            self.leftKey = KbName('LeftArrow');
            self.rightKey = KbName('RightArrow');
            
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
            for key =  ['T_orient', 'L_orient', 'R_orient'] 
                self.expDesign(key) = random_sample(nTrials,...
                    self.orientProb, self.orientChoice);
            end
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
            % luminance value
            
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
            radius = self.diameter / 2;
            x1 = (self.xPos(rectIdx) - offset(1)) - radius;
            y1 = (self.yPos(rectIdx) - offset(2)) - radius;
            x2 = (self.xPos(rectIdx) - offset(1)) + radius;
            y2 = (self.yPos(rectIdx) - offset(2)) + radius;
            dest = [x1 y1 x2 y2];
        end
        
        function [stimuli, dests] = make_stimuli(self, idx, rectIdx)
            % make the gratings textures
            keys =  ['T_orient', 'L_orient', 'R_orient'];
            trialOrientations = zeros(1, 3);
            for i = 1:3 
                orientations = self.expDesign(keys(i));
                trialOrientations(i) = orientations(idx);
            end
            stimuli = make_grating(self.window, trialOrientations,...
                1, self.diameter, self.spatialFrequency, self.contrast);
            
            % get the destinations
            dests = zeros(3, 4);
            s = self.expDesign('spacing');
            dests(1,:) = self.get_destination(rectIdx, [0,0]); %target
            dests(2,:) = self.get_destination(rectIdx, [s(idx),0]); %left flanker
            dests(3,:) = self.get_destination(rectIdx, [-s(idx),0]); %right flanker
        end
            
        function [] = place_stimuli(self, stimuli, dests)
            for i = 1:length(stimuli)
                Screen('DrawTexture', self.window, stimuli(i),[], dests(i,:), 0);
            end
        end
        
        function [response] = get_key_response(self)
            rspToBeMade = true;
            while rspToBeMade
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(self.leftKey)
                    response = 0;
                    rspToBeMade = false;
                elseif keyCode(self.rightKey)
                    response = 1;
                    rspToBeMade = false;
                elseif keyCode(self.escapeKey)
                    ShowCursor;
                    sca;
                    return
                end
            end
        end
   
    
        
        function [] = forward(self, idx, vbl)
            % Initialize the trial
            [cueIndex, postCueIndex] = self.get_cue(idx);
            [stimuli, dests] = self.make_stimuli(idx, postCueIndex);
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
            rsp = self.get_key_response()
        end  
    end
end

