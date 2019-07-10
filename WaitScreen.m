classdef WaitScreen
    % WaitScreen: Class to schedule wait/break screens between 
    % experiment blocks
    %   Methods:
    %   1) run
    %       displays the waiting screen until designated key is pressed
    
    properties
        window % the ptb screen object
        displayText % The text string to be displayed
        textSize % the size of the text
    end
    
    methods
        function self = WaitScreen(window, displayText, textSize)
            %WaitScreen Construct an instance of this class
            self.window = window;
            self.displayText = displayText;
            self.textSize = textSize;
        end
        
        function run(self, nTrials, name)
            wait = true;
            exitKey = KbName('space');
            while wait
                Screen('TextSize', self.window, self.textSize);
                DrawFormattedText(self.window, [self.displayText], ... 
                    'center', 'center', 1);
                Screen('Flip', self.window);
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(exitKey)
                    wait = false;
                end 
            end
        end
        
        function [updatedResults, keys] = dump_results_info(self, currentResults)
            updatedResults = currentResults;
            keys = nan;
        end
    end
end

