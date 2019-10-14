classdef WaitScreen
    % Class to schedule wait/break screens between experiment blocks
    
    properties
        displayText % The text string to be displayed
        textSize % the size of the text
        customFrames % array of screen images to show in order
        nFrames % number of frames to show
        nextKey % key to proceed to next message ('SPACE' bar)
        backKey % key to go back to previous message ('Delete' key)
        exitKey % key to escape ('ESCAPE' key)
        
        % screen information
        window % the ptb screen pointer
        xCenter % x coordinate of center of screen
        yCenter % y coordinate of center of screen
        xRes % x resolution of screen
        yRes % y resolution of screen
    end
    
    methods
        function self = WaitScreen(window, windowRect, ...
                displayText, textSize, customFrames)
            % --------------------------------------------------
            % Construct an instance of this class
            % --------------------------------------------------
            self.window = window;
            self.displayText = displayText;
            self.textSize = textSize;
            self.customFrames = customFrames;
            self.nFrames = size(self.customFrames);
            self.nextKey = KbName('space');
            self.backKey = KbName('DELETE');
            self.exitKey = KbName('ESCAPE');
            
            [self.xCenter, self.yCenter] = RectCenter(windowRect);
            [self.xRes, self.yRes] = Screen('WindowSize', window);
        end
        
        function simple_text(self)
            % ---------------------------------------------------
            % Writes simple text messages to the screen
            % ---------------------------------------------------
            Screen('TextSize', self.window, self.textSize);
            DrawFormattedText(self.window, [self.displayText], ... 
                    'center', 'center', 1);
        end
        
        function custom_frames(self, fr)
            % ---------------------------------------------------
            % Writes custom instruction slides to the screen
            % ---------------------------------------------------
            if length(self.nFrames) == 3
                frame = self.customFrames(fr, :, :);
            elseif length(self.nFrames) == 4
                frame = self.customFrames(fr, :, :, :);
            end
            frame = reshape(frame, self.nFrames(2:length(self.nFrames)));
            framePointer = Screen('MakeTexture', self.window, frame);
            Screen('DrawTexture', self.window, framePointer);
        end
        
        
        function run(self, nTrials, name)
            % ----------------------------------------------------
            % Runs the wait screen/slides until a key is pressed
            % ----------------------------------------------------
            frameChange = 0;
            wait = true;
            fr = 1;
            while wait
                % place the custom frame if present
                if isempty(self.customFrames)
                    fr = 0;
                else
                    self.custom_frames(fr);
                end
                % place text
                self.simple_text();
                % flip the screen
                Screen('Flip', self.window);
                % wait a half second after a frame is changed before you change again
                if frameChange
                    WaitSecs(.25);
                    frameChange = 0;
                end
                
                % get a response
                responseToBeMade = 1;
                while responseToBeMade
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(self.nextKey) && fr == self.nFrames(1)
                        wait = false; 
                        responseToBeMade = 0;
                    elseif keyCode(self.nextKey) && fr < self.nFrames(1)
                        fr = fr+1;
                        frameChange = 1;
                        responseToBeMade = 0;
                    elseif keyCode(self.backKey) && fr > 1
                        fr = fr-1;
                        frameChange = 1;
                        responseToBeMade = 0;
                    elseif keyCode(self.exitKey)
                        Eyelink('StopRecording')
                        ShowCursor;
                        sca;
                        return
                    else
                        responseToBeMade = 1;
                    end
                end
            end    
        end
        
        function [keys] = dump_results_info(self)
            % ----------------------------------------------------
            % Passes through and does not dump results
            % ----------------------------------------------------
           keys = {}; 
        end
    end
end

