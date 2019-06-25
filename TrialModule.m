classdef TrialModule < handle
    %TiralModule: Base class for running a single experiment block
    %   Methods: 
    %   1) draw_fixation
    %       draws a fixation cross at the center of the scree
    %   2) run
    %       runs the experiment block for a designated amount of trials 
    
    properties
        window % the ptb screen object
        xCenter % the x-coordinate of the center point
        yCenter % the y-coordinate of the center point
        expDesign % the experiment design container
        results % the results matrix
    end
    
    methods
        function self = TrialModule(window, windowRect)
            %MODULE Construct an instance of this class
            %   Detailed explanation goes here
            self.window = window;
            [self.xCenter, self.yCenter] = RectCenter(windowRect);
            self.expDesign = containers.Map();
        end
        
        function [] = draw_fixation(self)
            Screen('DrawDots', self.window, [self.xCenter; self.yCenter],...
                10, 0, [], 2);
        end
        
        function [] = run(self, nTrials)
            % set the experimental design
            self.set_exp_design(nTrials);
            % set the results matrix
            self.set_results_matrix(nTrials);
            % run the design for each trial
            vbl = Screen('Flip', self.window);
            for i = 1:nTrials
                self.forward(i, vbl);
            end
        end
    end
end

