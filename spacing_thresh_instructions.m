function [instructions] = spacing_thresh_instructions()
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
    CB = CueTrial(window, windowRect, 1.25, [1 0], 1, [1], [3], 0, 0, 0, 0);
    CB.set_exp_design(1);
    [cueIndex, postCueIndex] = CB.get_cue(1);
    
    instructions = [];
    
    % ===========
    % 1. Part II intro
    % ===========
    message = ['Part II'];
    Screen('TextSize', window, 70);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions);
    sca;
    
    % ===========
    % 2. Stimulus
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    [stimuli, dests] = CB.make_stimuli(1, postCueIndex);
    CB.draw_fixation(.25);
    CB.cue_vlines(0);
    CB.place_stimuli(stimuli, dests);
    message = ['Next, you will do the exact same thing except there will be two ' ...
               'additional gratings above and below the center grating'...
               '\n\n\n Press the space bar to continue.'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    instructions = add_frame(instructions);
    sca;
    
    % ===========
    % 3. Response
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    CB.draw_fixation(.25);
    CB.cue_vlines(0);
    message = ['After the gratings are briefy presented: \n \n' ... 
               'Press the RIGHT ARROW for a CENTRAL grating tilted 45 degrees to the RIGHT of the vertical. \n \n' ...
               'Press the LEFT ARROW for a CENTRAL grating tilted 45 degrees to the LEFT of the vertical. \n\n\n'...
               'Press the space bar to continue.'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    instructions = add_frame(instructions);
    sca;
    
    %TODO: add close-up images of the possible target orientations
    
    % ========
    % 4. End
    % ========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    message = ['The trials will become progressively more difficult. \n \n ' ...
               'This is normal, and it is OK to guess if you cannot make out the orientation of the centeral grating. \n\n\n' ...
               'Press the space bar to begin the experiment!'];
           
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions); 
    sca;
    
    save('instructions/spacing_thresh_instruction_frames_right.mat', 'instructions')
    

    function instructions = add_frame(instructions)
        Screen('Flip', window);
        frame = reshape(Screen('GetImage', window), 1, yRes, xRes, 3);
        frame = double(frame)/255;
        instructions = cat(1, instructions, frame);
    end  
    
end


    

