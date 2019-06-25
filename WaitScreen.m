classdef WaitScreen
    %WaitScreen Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        window
        displayText
        textSize
    end
    
    methods
        function self = WaitScreen(window, displayText, textSize)
            %WaitScreen Construct an instance of this class
            %   Detailed explanation goes here
            self.window = window;
            self.displayText = displayText;
            self.textSize = textSize;
        end
        
        function run(self, nTrials)
            wait = true;
            exitKey = KbName('space');
            while wait
                Screen('TextSize', self.window, self.textSize)
                DrawFormattedText(self.window, [self.displayText], ... 
                    'center', 'center', 1);
                Screen('Flip', self.window)
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(exitKey)
                    wait = false;
                end 
            end
        end
    end
end

