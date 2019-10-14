classdef TrialModule < handle
    % Base class for running a single experiment block
    
    properties
        window % the ptb screen object
        xCenter % the x-coordinate of the center point
        yCenter % the y-coordinate of the center point
        xRes % screen resolution in the x-dimension 
        yRes % screen resolution in the y-dimension
        el % the eyelink structure
        expDesign % the experiment design structure
        results % the results matrix
    end
    
    methods
        function self = TrialModule(window, windowRect)
            % ---------------------------------------------------
            % Construct an instance of this class
            % ---------------------------------------------------
            self.window = window;
            [self.xCenter, self.yCenter] = RectCenter(windowRect);
            [self.xRes, self.yRes] = Screen('WindowSize', window);
            self.expDesign = struct;
        end
        
        function draw_fixation(self, color)
            % ---------------------------------------------------
            % Draws a fixation cross in the center of the screen
            % ---------------------------------------------------
            fcv = CenterRectOnPoint([0 0 1 10].*2, self.xCenter, self.yCenter);
            fch = CenterRectOnPoint([0 0 10 1].*2, self.xCenter, self.yCenter);
            Screen('FillRect', self.window, color, [fcv' fch'])
        end
        
        function start_screen(self, goKey)
            % --------------------------------------------------
            % Places a sceen until a go key is pressed to start
            % the experiment block.
            % --------------------------------------------------
            self.draw_fixation(.25)
            Screen('TextSize', self.window, 26);
            DrawFormattedText(self.window, 'press the space bar to start', ... 
                    'center', .60*self.yRes, 1);
            
            Screen('Flip', self.window);
            responseToBeMade = 1;
            while responseToBeMade
                [~, ~, keyCode] = KbCheck;
                if keyCode(goKey)
                    responseToBeMade = 0;
                else
                    responseToBeMade = 1;
                end
            end
        end
        
        function start_countdown(self, nSecs)
            % -------------------------------------------------
            % Sets a countdown to start the block
            % -------------------------------------------------
            Screen('TextSize', self.window, 50);
            % countdown
            for t = nSecs:-1:1
                DrawFormattedText(self.window, num2str(t), ... 
                    'center', 'center', 1);
                Screen('Flip', self.window)
                WaitSecs(1);
            end
        end
        
        function steps = staircase_step(self, steps, results)
            % --------------------------------------------------
            % Finds the next step in a nUp-nDown staircase
            % --------------------------------------------------
            nSteps = length(steps);
            if nSteps < self.nDown || nSteps < self.nUp
                steps = [steps steps(nSteps)]; 
            else
                % nUp-last trial correct responses 
                up = results((nSteps+1)-self.nUp:nSteps);
                stepsUp = steps((nSteps+1)-self.nUp:nSteps);
                %nDown-last trial correct responses
                down = results((nSteps+1)-self.nDown:nSteps);
                stepsDown = steps((nSteps+1)-self.nDown:nSteps);
                % Check if next step is move up or down
                if sum(up) == 0 && all(diff(stepsUp)==0)
                    steps = [steps (steps(nSteps) + self.stepSize)];
                elseif sum(down) == self.nDown && all(diff(stepsDown)==0)
                    steps = [steps (steps(nSteps) - self.stepSize)];
                else
                    steps = [steps steps(nSteps)];
                end
            end   
        end
        
        function init_eyelink(self, expName, edfFile)
            % -----------------------------------------------
            % Initializes the eyelink edf file
            % -----------------------------------------------
            % initialize for given window
            self.el=EyelinkInitDefaults(self.window);
            self.el.backgroundcolor = .5;
            % initialize the .edf File 
            % init_edf(expName, edfFile, self.xRes, self.yRes);
            EyelinkDoTrackerSetup(self.el);
        end
        
        function check_eyelink(self, idx, nTrials)
            % -------------------------------------------------------
            % Checks eyelink and fixation routine before a trial
            % -------------------------------------------------------
            Eyelink('Message', 'TRIALID %d', idx);
            Eyelink('Command','clear_screen 0'); % clear operator screen
            % cancel if eyeLink is not connected
            if Eyelink('isconnected') == self.el.notconnected	
                return
            end
            % set the 
            Eyelink('Command', 'record_status_message '' TRIAL %d / %d ''', ...
                idx, nTrials); 
            Eyelink('Command', 'set_idle_mode'); % must be offline to draw to EyeLink screen
            Eyelink('Command','clear_screen 0'); % clear operator screen
            Eyelink('Command','draw_box %d %d %d %d 15', ...
                self.fixLoc(1), self.fixLoc(2), self.fixLoc(3), self.fixLoc(4));
            Eyelink('Command', 'set_idle_mode');
          
            % start recording
            Eyelink('startrecording');
            % allow some synch time
            Eyelink('Message', 'SYNCTIME');	
            % check recording
            err=Eyelink('checkrecording'); 
            if(err~=0)
                Eyelink('message', 'TRIAL ERROR');
                trialok = 0;
            else
                trialok = 1;
                Eyelink('message', 'TRIAL_START %d', idx);
            end
            
            if trialok
                if Eyelink('isconnected') == self.el.dummyconnected % if in dummy mode
                    ShowCursor;
                else
                    HideCursor;
                end
                Eyelink('Message', 'FIXATION_CROSS');

                % trail recalibration
                MAX_CHECK = 3; % check 3 times for fixation
                ncheck = 0; 
                fix = 1;
                while fix~=1 % if there is no fixation, check for fixation
                    ncheck = ncheck + 1; 
                    self.draw_fixation(0)
                    Screen('Flip', self.window);
                    Eyelink('message', 'FIXATION_CROSS');
                    fix = check_fix(self.el, self.fixLoc);	
                    
                    if fix == 0 && ncheck < MAX_CHECK
                        Screen('Flip', self.window);
                        WaitSecs(1.2);
                        self.draw_fixation(0)
                        Screen('Flip', self.window);
                        WaitSecs(0.6);
                    elseif fix == 0 && ncheck == MAX_CHECK 
                        Eyelink('Message', 'FORCED_CALIBRATION'); % calibrate again
                        EyelinkDoTrackerSetup(self.el);
                        Eyelink('startrecording');	% start recording
                        WaitSecs(.1);

                        err = Eyelink('checkrecording'); % check recording status
                        if err~=0
                            Eyelink('Message', 'TRIAL ERRORWITHIN');
                        end
                        Screen('Flip', self.window);
                        ncheck = 0; 
                    end
                end	
            end
        end


        function [] = run(self, nTrials, name)
            % --------------------------------------------------
            % Runs the experiment block
            % --------------------------------------------------
            % set the experimental design
            self.set_exp_design(nTrials);
            % initialize eyelink
            self.init_eyelink(name, [name '.edf'])
            % run the design for each trial
            vbl = Screen('Flip', self.window);
            for i = 1:nTrials
                vbl = self.forward(i, vbl, nTrials);
            end
        end
    end
end

