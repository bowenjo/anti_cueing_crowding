function [instructions] = size_thresh_instructions()
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
    CB = CueTrial(window, windowRect, 1.25, [1 0], 1, [1], [Inf], 0, 0, 0, 0);
    CB.set_exp_design(1);
    [cueIndex, postCueIndex] = CB.get_cue(1);
    
    instructions = [];
    % =========
    % 1. Intro
    % =========
    % make the frame
    message = ['This experiment will be broken up into three parts. \n\n' ...
               'Part I: Setting a Baseline (Size). \n' ...
               'Part II: Setting a Baseline (Spacing). \n' ...
               'Part III: Visual Crowding with Attentional Cueing \n\n\n' ...
               'Press the space bar to continue'];
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
               'in the center of the screen. \n\n\n Press the space bar to continue'];  
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
               'will appear for the full experiment. \n\n\n Press the space bar to continue'];
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
    message = ['Part I: Setting a Baseline (Size): \n\n'...
               'For this part, a single gratings will appear ' ...
               'within the vertical bars on the LEFT side of the screen.'...
               '\n\n\n Press the space bar to continue.'];
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
    message = ['After the gratings are briefly presented: \n\n' ...
               'Press the RIGHT ARROW for a CENTRAL grating facing 45 degrees to the RIGHT of the vertical. \n\n' ...
               'Press the LEFT ARROW for a CENTRAL grating facing 45 degrees to the LEFT of the vertical. \n\n\n'...
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
    message = ['The trials will become progressively more difficult. \n \n ' ...
               'This is normal, and it is OK to guess if you can not make out the orientation of the center grating. \n\n\n' ...
               'Press the space bar to begin the experiment!'];
           
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions); 
    sca;
    
    save('instructions/size_thresh_instruction_frames.mat', 'instructions')
    

    function instructions = add_frame(instructions)
        Screen('Flip', window);
        frame = reshape(Screen('GetImage', window), 1, yRes, xRes, 3);
        frame = double(frame)/255;
        instructions = cat(1, instructions, frame);
    end  
    
end


    

