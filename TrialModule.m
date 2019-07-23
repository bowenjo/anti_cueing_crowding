classdef TrialModule < handle
    %TrialModule: Base class for running a single experiment block
    %   Methods: 
    %   1) draw_fixation
    %       draws a fixation cross at the center of the scree
    %   2) run
    %       runs the experiment block for a designated amount of trials 
    
    properties
        window % the ptb screen object
        xCenter % the x-coordinate of the center point
        yCenter % the y-coordinate of the center point
        xRes % screen resolution in the x-dimension 
        yRes % screen resolution in the y-dimension
        el % the eyelink structure
        expDesign % the experiment design container
        results % the results matrix
    end
    
    methods
        function self = TrialModule(window, windowRect)
            %MODULE Construct an instance of this class
            self.window = window;
            [self.xCenter, self.yCenter] = RectCenter(windowRect);
            [self.xRes, self.yRes] = Screen('WindowSize', window);
            self.expDesign = containers.Map();
        end
        
        function draw_fixation(self)
            % draws a fixation cross in the center of the screen
            fcv = CenterRectOnPoint([0 0 2 20].*2, self.xCenter, self.yCenter);
            fch = CenterRectOnPoint([0 0 20 2].*2, self.xCenter, self.yCenter);
            Screen('FillRect', self.window, 0, [fcv' fch'])
        end
        
        function init_eyelink(self, expName, edfFile)
            % initialize for given window
            self.el=EyelinkInitDefaults(self.window);
            self.el.backgroundcolor = .5;
            % initialize the .edf File 
% T commented out:             init_edf(expName, edfFile, self.xRes, self.yRes);
            EyelinkDoTrackerSetup(self.el);
        end
        
        function check_eyelink(self, idx, nTrials)
            % checks eyelink and fixation routine before a trial
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
            WaitSecs(0.1);
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
                end
                Screen('Flip', self.window); 
                self.draw_fixation()
                Eyelink('Message', 'FIXATION_CROSS');
                WaitSecs(0.6); % allow 600 ms to direct attention to the cross

                % trail recalibration
                MAX_CHECK = 3; % check 3 times for fixation
                ncheck = 0; 
                fix = 1;
                while fix~=1 % if there is no fixation, check for fixation
                    ncheck = ncheck + 1; 
                    self.draw_fixation()
                    Screen('Flip', self.window);
                    Eyelink('message', 'FIXATION_CROSS');
                    fix = check_fix(self.el, self.fixLoc);	
                    
                    if fix == 0 && ncheck < MAX_CHECK
                        Screen('Flip', self.window);
                        WaitSecs(1.2);
                        self.draw_fixation()
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
            % set the experimental design
            self.set_exp_design(nTrials);
            % set the results matrix
            self.set_results_matrix(nTrials);
            % initialize eyelink
            self.init_eyelink(name, [name '.edf'])
            % run the design for each trial
            vbl = Screen('Flip', self.window);
            for i = 1:nTrials
                self.forward(i, vbl, nTrials);
            end
        end
    end
end

