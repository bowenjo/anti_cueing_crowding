classdef CueTrialParams < handle
    % Class for calling fixed parameters for the CueRects module
    
    properties
        % Screen info
        screens 
        screenNumber
        
        % cue rectangle info
        baseRect % array - base cue rectangle 
        xPos % int - x-coordinate positions of the boxes in pixels
        yPos % int - y-coordinate positions of the boxes in pixels
        nLocs % int - number of rectangles
        vLines % the rectangle bounding box coordinates
       
        % cue information
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
        skipKey % skips the block
        pauseKey % pauses a block
        
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
        nFlankers % int - the number of flankers per side
        flankerStyle % char - the flanker style - options - 't', 'r', 'b'  
        flankerKeys % cell array - keys for the flankers
        totalNumFlankers % int - the total number of flankers
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
            self.subjectDistance = 49; 
            self.physicalWidthScreen = 43; 

            % cue information
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
            
            self.flankerStyle = 't';   
            self.nFlankers = 2;
            self.isHash = false; 
            
            % response info
            self.killKey = KbName('Q');
            self.pauseKey = KbName('P');
            self.leftKey = KbName('LeftArrow');
            self.rightKey = KbName('RightArrow');

            % fixation info
            fixRadius = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, 3);
            self.fixLoc =  [self.xCenter-fixRadius, self.yCenter-fixRadius, ...
                            self.xCenter+fixRadius, self.yCenter+fixRadius]; 
        end
        
        function set_position_params(self)
            % -------------------------------------------------------
            % (re)sets the position parameters for the cue locations
            % for the current grating diameter
            % -------------------------------------------------------
            % Get the vertical cue lines
            xOffset = 14; % target location in degrees
            xOffsetPix = angle2pix(self.subjectDistance, self.physicalWidthScreen, ...
                self.xRes, xOffset);
            
            self.xPos = [self.xCenter - xOffsetPix, self.xCenter + xOffsetPix];
            self.yPos = [.5 .5] * self.yRes;
            
            self.nLocs = length(self.xPos);
            vls = angle2pix(self.subjectDistance, ...
                self.physicalWidthScreen, self.xRes, self.diameter); % vline space
            
            self.vLines = [];
            for os = [-xOffsetPix, xOffsetPix]
                xCoor = [os+vls, os+vls, os-vls, os-vls];
                yCoor = [-vls/2, vls/2, -vls/2, vls/2];
                lines = [xCoor; yCoor];
                self.vLines = [self.vLines lines];
            end
        end
        
        function set_flanker_params(self)
            % -------------------------------------------------------
            % (re)sets the flanker parameters for the currect style
            % -------------------------------------------------------
            if self.flankerStyle == 't' || self.flankerStyle == 'r'
                self.totalNumFlankers = self.nFlankers*2;
            elseif self.flankerStyle == 'b'
                self.totalNumFlankers = self.nFlankers*4;
            end
            self.flankerKeys = {};
            for i = 1:self.totalNumFlankers
                self.flankerKeys(i) = {['F_' char(string(i))]};
            end
        end
        
    end
end

