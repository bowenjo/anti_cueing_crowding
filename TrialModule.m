classdef TrialModule
    %MODULE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        window  
        xCenter
        yCenter
        expDesign
        results
    end
    
    methods
        function self = TrialModule(window, windowRect)
            %MODULE Construct an instance of this class
            %   Detailed explanation goes here
            self.window = window;
            [self.xCenter, self.yCenter] = RectCenter(windowRect);
            self.expDesign = containers.Map();
            self.results = containers.Map();
        end
        
        function [] = draw_fixation(self)
            Screen('DrawDots', self.window, [self.xCenter; self.yCenter],...
                10, 0, [], 2);
        end
        
        function [] = run(self, nTrials)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            % set the experimental design
            self.set_exp_design(nTrials);
            % run the design for each trial
            vbl = Screen('Flip', self.window);
            for i = 1:nTrials
                self.forward(i, vbl)
            end
        end
    end
end

