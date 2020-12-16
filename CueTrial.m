classdef CueTrial < TrialModule & CueTrialParams
    % CueRects: Class for running attention anti-cueing experiments
    
    properties
        % grating information
        diameter % float - size of grating in degrees visual angle
        spatialFrequency
        
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
        function self = CueTrial(window, windowRect, diameter, ...
                cuedLocProb, cueValidProb, spacingProb, spacingChoice, ...
                isiTime, cueTime, soaTime, stimTime)
            % ----------------------------------------------------
            % Construct an instance of this class
            % ----------------------------------------------------
            self = self@TrialModule(window, windowRect);
            self = self@CueTrialParams();
            
            % grating size
            self.diameter = diameter;
            self.spatialFrequency = self.cyclesPerGrating/self.diameter;
            self.set_position_params(self.diameter);
            
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
            % ----------------------------------------------------------
            % Sets and randomizes cue and stimulus presentation info for
            % each trial
            % ----------------------------------------------------------
            
            % cue locations for each trial
            self.expDesign.cue_loc = random_sample(nTrials, ...
                self.cuedLocProb, 1:self.nLocs, false);
            
            % cue size for each trial
            self.expDesign.cue_size = repmat(self.diameter, 1, nTrials);
            
            % orientations
            % target orientation
            self.expDesign.T = random_sample(nTrials,...
                    self.targetOrientProb, self.targetOrientChoice, false);
            % flanker orientations for each trial
            flankerChoices = randi(length(self.flankerOrientChoice), ...
                self.nFlankers*self.nFlankerRepeats, nTrials);
            self.expDesign.F = self.flankerOrientChoice(flankerChoices);
            
            % choose validity dependent on spacing
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
            self.expDesign.spacing = spacingOrdered(permIndices);
            self.expDesign.valid = validOrdered(permIndices);
            
            % initialize result fields
            for key = {'response', 'RT', 'pre_fix_check', 'post_fix_check'}
                self.expDesign.(string(key)) = nan(1,nTrials);
            end
        end
        
        function [cuedLoc, postLoc] = get_cue(self, idx)
            % -------------------------------------------------------------
            % gets the cued rect index and the stimulus rect index for each
            % trial depending on if it is a valid or non-valid trial
            % -------------------------------------------------------------
            
            % get the cued rectangle index
            cuedLoc = self.expDesign.cue_loc(idx);
            % pick post cue rect given validity information
            oppLoc = self.postCuedLoc(cuedLoc);
            
            if self.expDesign.valid(idx)
                postLoc = oppLoc; % if valid, display in opposite rect
            else
                postLoc = cuedLoc; % otherwise, display in same rect
            end
        end
        
        function [] = cue(self, cuedLoc, cueDiameter)
            % ---------------------------------------------------------
            % cues a region of the screen
            % ---------------------------------------------------------
            % reset the position params for trial diameter
            self.set_position_params(cueDiameter);
            
            % nuetral cue (cue fixation)
            if isinf(cueDiameter) && cuedLoc ~=0
                self.draw_fixation(self.cueLum);
            % cue an area
            else
                % cue custom texture
                if self.cueType == "texture"
                    if cuedLoc ~= 0
                        diameterPx = angle2pix(self.subjectDistance, ...
                        self.physicalWidthScreen, self.xRes, cueDiameter);

                        texturePointer = self.cueFunction(self.window, diameterPx);
                        Screen('DrawTexture', self.window, texturePointer, [], ...
                            self.cueRects(:,cuedLoc)')   
                    end

                % cue vertical lines   
                elseif self.cueType == "vline"
                    % change the luminance and width if a cue is present
                    lums = repmat(self.nonCueLum, 3, self.nLocs*4);
                    lineWidths = repmat(self.nonCueWidth, 1, self.nLocs*2);
                    if cuedLoc ~= 0
                        lineLoc = cuedLoc*2;
                        lums(:, lineLoc*2-3:lineLoc*2) = repmat(self.cueLum, 3, 4);
                        lineWidths(lineLoc-1:lineLoc) = repmat(self.cueWidth, 1, 2);
                    end
                    % Display the rects
                    Screen('DrawLines', self.window, self.cueRects, lineWidths,...
                        lums, [self.xCenter self.yCenter]);

                % cue a circle or a square
                else
                   lums = repmat(self.nonCueLum, 3, self.nLocs);
                   lineWidths = repmat(self.nonCueWidth, 1, self.nLocs);
                   if cuedLoc ~=0
                       lums(:, cuedLoc) = repmat(self.cueLum, 3, 1);
                       lineWidths(cuedLoc) = self.cueWidth;
                   end

                   if self.cueType == "circle"
                        Screen('FrameOval', self.window, lums, self.cueRects, lineWidths)
                   elseif self.cueType == "square"
                        Screen('FrameRect', self.window, lums, self.cueRects, lineWidths)
                   end
                end
            end
        end
        
        function [dest] = get_destination(self, rectIdx, offset)
            % ----------------------------------------------------------
            % gets the destination of the stimuli with respect to the cue
            % location
            % -----------------------------------------------------------
            
            radius = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter/2);
            
            x1 = (self.xPos(rectIdx) - offset(1)) - radius;
            y1 = (self.yPos(rectIdx) - offset(2)) - radius;
            x2 = (self.xPos(rectIdx) - offset(1)) + radius;
            y2 = (self.yPos(rectIdx) - offset(2)) + radius;
            dest = [x1 y1 x2 y2];
        end
        
        function [offsets] = get_offsets(self, spacing)
            % ----------------------------------------------------------
            % Gets the flanker offsets for the given spacing
            % ----------------------------------------------------------
            diameterPix = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter);
            % initialize offset array (x and y-coord)X(all flankers)
            offsets = zeros(2,(self.nFlankers*self.nFlankerRepeats));
            % get the angle to rotate 
            rotationAngle = 2*pi/(self.nFlankers);
            % loop over the flankers to get offsets
            index = 1;
            for nF=1:self.nFlankers
                for nR=1:self.nFlankerRepeats
                    xOffset = (spacing + (nR-1)*self.flankerRepeatOffset*diameterPix) ...
                        * cos(self.flankerAxis+(nF-1)*rotationAngle);
                    yOffset = (spacing + (nR-1)*self.flankerRepeatOffset*diameterPix) ...
                        * sin(self.flankerAxis+(nF-1)*rotationAngle);
                    offsets(:,index) = [xOffset; yOffset]; 
                    index = index+1;
                end
            end 
            
        end
        
        function [stimuli, dests] = make_stimuli(self, idx, rectIdx)
            % ------------------------------------------------------
            % calls a function to make the stimuli and gathers all
            % destinations
            % ------------------------------------------------------
            % make the gratings textures
            totalNumFlankers = self.nFlankers*self.nFlankerRepeats;
            
            % get the flanker orientations for the trial
            trialOrientations = [self.expDesign.T(idx), self.expDesign.F(:,idx)'];
           
            % make the stimuli images
            if self.stimType == "grating"
                stimuli = make_grating(self.window, trialOrientations,...
                    self.diameter, self.spatialFrequency, self.contrast, self.isHash, ...
                    self.subjectDistance, self.physicalWidthScreen, self.xRes);
            elseif self.stimType == "rotated_t"
                letterTypes = ['T' repmat('H',1,totalNumFlankers)];
                stimuli = make_rotated_letter(self.window, letterTypes, ...
                    trialOrientations, self.diameter, self.diameter/10,  self.subjectDistance, ...
                    self.physicalWidthScreen, self.xRes);
            end
            
            % get the spacing for the trial
            sTrial = angle2pix(self.subjectDistance, self.physicalWidthScreen, ...
                self.xRes, self.expDesign.spacing(idx)); % get the spaincing in pixels
            
            % get the destinations for the trial
            dests = zeros(totalNumFlankers+1, 4);
            
            % set target destination
            dests(1,:) = self.get_destination(rectIdx, [0,0]); 
            
            % set flanker destinations
            flankerOffsets = self.get_offsets(sTrial);
            flankerIdx = 2;
            for offset=flankerOffsets
                dests(flankerIdx,:) =  self.get_destination(rectIdx, offset);
                flankerIdx = flankerIdx+1;
            end
        end
            
        function [] = place_stimuli(self, stimuli, dests)
            % ---------------------------------------------------------
            % points the pre-made stimuli to the screen
            % ---------------------------------------------------------
            for i = 1:length(stimuli)
                Screen('DrawTexture', self.window, stimuli(i),[], dests(i,:));
            end
        end
        
        function rsp = forward(self, idx, nTrials)
            % ----------------------------------------------------------
            % runs one complete trial and records the response variables
            % ----------------------------------------------------------
            % Initialize the trial
            [cueIndex, postCueIndex] = self.get_cue(idx);
            [stimuli, dests] = self.make_stimuli(idx, postCueIndex);
            cueSize = self.expDesign.cue_size(idx);
            preCueFixationChecks = zeros(1,self.isiFrames);
            postCueFixationChecks = zeros(1, self.stimFrames);
            % Eyelink stuff
            self.check_eyelink(idx, nTrials)
            % Fixation Interval
            vbl = Screen('Flip', self.window);
            for i = 1:self.isiFrames
                self.draw_fixation(.25);
                self.cue(0, cueSize)
                preCueFixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Cue Interval
            for i = 1:self.cueFrames
                self.draw_fixation(.25);
                self.cue(cueIndex, cueSize);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Onset Asynchrony Interval
            for i = 1:self.soaFrames
                self.draw_fixation(.25);
                self.cue(0, cueSize)
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Stimulus Display Interval
            for i = 1:self.stimFrames
                self.draw_fixation(.25)
                self.cue(0, cueSize)
                self.place_stimuli(stimuli, dests);
                postCueFixationChecks(i) = check_fix(self.el, self.fixLoc);
                vbl = Screen('Flip', self.window, vbl + self.ifi/2);
            end
            % Response interval
            self.draw_fixation(.25)
            self.cue(0, cueSize)
            Screen('Flip', self.window, vbl+self.ifi/2);
            [rsp, rt] = self.get_key_response();
            
            self.draw_fixation(0)
            self.cue(0, cueSize)
            Screen('Flip', self.window);

            % append the response data
            preCueFix = mean(preCueFixationChecks == 1);
            postCueFix = mean(postCueFixationChecks == 1);
            self.expDesign.response(idx) = rsp;
            self.expDesign.RT(idx) = rt;
            self.expDesign.pre_fix_check(idx) = preCueFix;
            self.expDesign.post_fix_check(idx) = postCueFix;  
            Screen('Close', stimuli)
        end 
        
        function [keys] = dump_results_info(self) 
            % -------------------------------------------------------------
            % dumps the block specific results into the results of the full
            % experiment
            % -------------------------------------------------------------
            nTrials = length(self.expDesign.response);
            self.expDesign.soa_time = repmat(self.soaTime, 1, nTrials);
            self.expDesign.correct = self.expDesign.response == self.expDesign.T;
            
            % dump results for block into the rest of the blocks
            keys = {'response', 'RT', 'pre_fix_check', 'post_fix_check', ...
                    'T', 'spacing', 'valid', 'soa_time', 'correct'};

        end     
        
    end
end

