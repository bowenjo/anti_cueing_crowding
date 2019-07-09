classdef CueRectsParams < handle
    % Class for calling fixed parameters for the CueRects module
    
    properties
        % Screen info
        screens 
        screenNumber
        
        % cue rectangle info
        baseRect % array - base cue rectangle 
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
        
        % grating parameters
        spatialFrequency % float - spatial frequency of disparity grating
        diameter % float - diameter of disparity grating 
        contrast % float - contrast of disparity grating
        
        % key response info
        leftKey % the left arrow keycode
        rightKey % the right arrow keycode 
        escapeKey % escape key code
        
        % fixation check info
        fixLoc
    end
    
    methods
        function self = CueRectsParams()
            %Construct an instance of this class
            self.screens = Screen('Screens');
            self.screenNumber = max(self.screens);
            
            self.baseRect = [0 0 400 200];
            self.xPos = [.25 .75] * self.xRes;
            self.yPos = [.5 .5] * self.yRes;
            self.nRects = length(self.xPos);
            
            % cue information
            self.cueLum = BlackIndex(self.screenNumber);
            self.nonCueLum = WhiteIndex(self.screenNumber);
            self.cueWidth = 6;
            self.nonCueWidth = 2;
            self.postCuedRect = [2 1];
            
            % Get the rects
            self.rects = nan(4,self.nRects);
            for i = 1:self.nRects
                self.rects(:, i) = CenterRectOnPointd(self.baseRect,...
                    self.xPos(i), self.yPos(i));
            end  
            
            % grating information
            self.spatialFrequency = .03;
            self.diameter = 80;
            self.contrast = 1;
            
            % response info
            self.escapeKey = KbName('ESCAPE');
            self.leftKey = KbName('LeftArrow');
            self.rightKey = KbName('RightArrow');
            
            % fixation info
            self.fixLoc =  [self.xCenter-20, self.yCenter-20, ...
                            self.xCenter+20, self.yCenter+20]; 
        end
    end
end

