classdef CueTrialParams < handle
    % Class for calling fixed parameters for the CueRects module
    
    properties
        % Screen info
        screens 
        screenNumber
        
        % cue rectangle info
        xPos % int - x-coordinate positions of the boxes in pixels
        yPos % int - y-coordinate positions of the boxes in pixels
        nLocs % int - number of rectangles
        cueRects % the rectangle bounding box coordinates
       
        % cue information
        cueType % str - cue type (vline, circle, square)
        cueLum % float - cued rectangle luminance value
        nonCueLum % float - non-cued rectangle luminance value
        cueWidth % int - cued rectangle outline width in pixels
        nonCueWidth % int - non-cued rectangle outline width in pixels
        postCuedLoc % array - size(1,nRects) - rectangle indices to present the stimuli following a cue 
        
        % grating parameters
        cyclesPerGrating % integer - number of cycles within a grating, independent of size
        contrast % float - contrast of grating
        
        % key response info
        leftKey % the left arrow keycode
        rightKey % the right arrow keycode 
        killKey % kill key code
        pauseKey % pauses a block
        skipKey % skips a block
        responseTimeOut % number of seconds to wait for a response
        
        % fixation check info
        fixLoc % the location of the fixation box
        subjectDistance % subject distance to screen in cm
        physicalWidthScreen % physical width of screen in cm
        
        % stimuli info
        stimType % str - stimulus type
        targetOrientChoice % array - target orientation choices in degrees
        targetOrientProb % array - proportion to choose choices
        flankerOrientChoice % array - flanker orientation choices in degrees
        flankerOrientProb % array - proportion to choose choices
        nFlankers % int - the number of flanker locations 
        flankerKeys % cell array - keys for the flankers
        nFlankerRepeats % int - the total number of flanker repeats
        flankerRepeatOffset % float - spacing between repeat flankers (in units diameter)
        flankerAxis % float - reference axis to draw flankers
        isHash % bool - true if flankers are hashed style
    end
    
    methods
        function self = CueTrialParams()
            % -----------------------------------
            % Construct an instance of this class
            % -----------------------------------
            self.screens = Screen('Screens');
            self.screenNumber = max(self.screens);
            
            % scree setup info
            self.subjectDistance = 50; 
            self.physicalWidthScreen = 43; 

            % cue information
            self.cueType = "vline";
            self.cueLum = (3/4)* WhiteIndex(self.screenNumber);
            self.nonCueLum = (1/4)*WhiteIndex(self.screenNumber);
            self.cueWidth = 3;
            self.nonCueWidth = 1;
            self.postCuedLoc = [2 1];
            
            % grating information
            self.contrast = 1;
            self.cyclesPerGrating = 4;
            
            % stimuli info
            self.stimType = "grating";
            
            if self.stimType == "grating"
                self.targetOrientChoice = [135 45];
                self.flankerOrientChoice = [10:35 55:80 100:125 145:170];
            elseif self.stimType == "rotated_t"
                self.targetOrientChoice = [0 180];
                self.flankerOrientChoice = [0 90 180 270];
            end
            self.targetOrientProb = [.5 .5];
            self.flankerOrientProb = ones(1, 180)/180;
            
            self.nFlankers = 2;
            self.nFlankerRepeats = 2;
            self.flankerRepeatOffset = 1;
            self.flankerAxis = pi/2;
            self.isHash = false; 
            
            % response info
            self.killKey = KbName('Q');
            self.pauseKey = KbName('P');
            self.skipKey = KbName('S');
            self.leftKey = KbName('LeftArrow');
            self.rightKey = KbName('RightArrow');
            self.responseTimeOut = 3;

            % fixation info
            fixRadius = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, 3);
            self.fixLoc =  [self.xCenter-fixRadius, self.yCenter-fixRadius, ...
                            self.xCenter+fixRadius, self.yCenter+fixRadius]; 
        end
        
        function set_position_params(self, size)
            % -------------------------------------------------------
            % (re)sets the position parameters for the cue locations
            % for the current size
            % -------------------------------------------------------
            % Get the vertical cue lines
            xOffset = 14; % target location in degrees
            xOffsetPix = angle2pix(self.subjectDistance, self.physicalWidthScreen, ...
                self.xRes, xOffset);
            
            lineOffsets = [-xOffsetPix xOffsetPix];
            self.xPos = self.xCenter + lineOffsets;
            self.yPos = [.5 .5] * self.yRes;
            
            self.nLocs = length(self.xPos);
            
            sizePix = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, size);  
            
            self.cueRects = [];
            for i = 1:self.nLocs
                if self.cueType == "vline"
                    os = lineOffsets(i);
                    xCoor = [os+sizePix, os+sizePix, os-sizePix, os-sizePix];
                    yCoor = [-sizePix/2, sizePix/2, -sizePix/2, sizePix/2];
                    rects = [xCoor; yCoor];
                    self.cueRects = [self.cueRects rects];
                else
                    rects = CenterRectOnPoint([0 0 sizePix sizePix], ...
                        self.xPos(i), self.yPos(i));
                    self.cueRects = [self.cueRects rects'];
                end
                
            end   
        end
        
        function set_flanker_params(self)
            % -------------------------------------------------------
            % (re)sets the flanker parameters for the currect style
            % -------------------------------------------------------
            totalNumFlankers = self.nFlankers * self.nFlankerRepeats;
            self.flankerKeys = {};
            for i = 1:totalNumFlankers
                self.flankerKeys(i) = {['F_' char(string(i))]};
            end
        end
        
    end
end

