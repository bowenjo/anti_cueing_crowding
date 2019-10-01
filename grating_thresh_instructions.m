function [instructions] = grating_thresh_instructions()
    % Add relevant paths
    utilsPath = [pwd '/utils'];
    analysisPath = [pwd '/analysis'];
    addpath(utilsPath)
    addpath(analysisPath)
    
    % set up
    sca; 
    close all;
    clearvars;
    PsychDefaultSetup(2);
    screens = Screen('Screens');
    screenNumber = max(screens);
    backgroundGrey = WhiteIndex(screenNumber)/2;
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    [xCenter, yCenter] = RectCenter(windowRect);
    [xRes, yRes] = Screen('WindowSize', window);
    
    textSize = 20;
    CB = CueTrial(window, windowRect, [1 0], 1, [1], [3], 0, 0, 0, 0);
    CB.set_exp_design(1);
    [cueIndex, postCueIndex] = CB.get_cue(1);
    
    instructions = [];
    % =========
    % 1. Intro
    % =========
    % make the frame
    message = ['Thank you for taking part in this experiment! \n \n Please press ' ...
               'the space bar to continue with a few brief instructions.'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', 'center', 1);
    % append the frame
    instructions = add_frame(instructions);
    sca;
    
    % ============
    % 2. Fixation
    % ============
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    % make the frame
    CB.draw_fixation(.25);
    message = ['For the full experiment, please fixate your eyes on the cross ' ...
               'in the center of the screen. \n\n Press the space bar to continue'];  
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    % append the frame
    instructions = add_frame(instructions);
    sca;

    
    % ===========
    % 3. Vlines
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    CB.draw_fixation(.25);
    CB.cue_vlines(0);
    message = ['Two sets of vertical lines on each side of the screen ' ...
               'will be up for the full experiment. \n\n Press the space bar to continue'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    % append the frame
    instructions = add_frame(instructions);
    sca;
          
    
    % ===========
    % 5. Stimulus
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    [stimuli, dests] = CB.make_stimuli(1, cueIndex);
    CB.draw_fixation(.25);
    CB.cue_vlines(0);
    CB.place_stimuli(stimuli, dests);
    message = ['After a brief wait, a set of gratings will appear briefly ' ...
               'within the vertical bars on the LEFT side of the screen.'...
               '\n \n Press the space bar to continue.'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    instructions = add_frame(instructions);
    sca;
    
    % ===========
    % 6. Response
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    CB.draw_fixation(.25);
    CB.cue_vlines(0);
    message = ['After the gratings are briefly presented, you will as quickly and ' ...
               'as accurately as possible report the orientation of the CENTER grating. \n \n' ...
               'Press the RIGHT ARROW for a central grating facing 45 degrees to the RIGHT. \n \n' ...
               'Press the LEFT ARROW for a central grating facing 45 degrees to the LEFT. \n \n'...
               'Press the space bar to continue.'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    instructions = add_frame(instructions);
    sca;
    
    %TODO: add close-up images of the possible target orientations
    
    % ========
    % 7. End
    % ========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    message = ['Following these instructions, there will be 20 practice trials. \n \n'...
               'After the practice trials, there will be 200 real trials. \n \n' ...
               'The trials will become progressively more difficult. \n \n ' ...
               'This is normal, and it is OK to guess if you can not make out the orientation of the center grating. \n\n' ...
               'Please press the space bar to begin some practice trials!'];
           
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions); 
    sca;
    
    save('instructions/grating_thresh_instruction_frames.mat', 'instructions')
    

    function instructions = add_frame(instructions)
        Screen('Flip', window);
        frame = reshape(Screen('GetImage', window), 1, yRes, xRes, 3);
        frame = double(frame)/255;
        instructions = cat(1, instructions, frame);
    end  
    
end


    

