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
    message = ['Thank you for taking part in this experiment! \n\n' ...
               'The experiment will be broken up into three parts. \n\n\n' ...
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
    message = ['At ALL times during a trial, please fixate your eyes on the cross ' ...
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
    % 5. Part I Intro
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    message = ['Part I'];
    Screen('TextSize', window, 70);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions);
    sca;
    
    % ===========
    % 6. Stimulus
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    [stimuli, dests] = CB.make_stimuli(1, postCueIndex);
    CB.draw_fixation([.35 0 0]);
    CB.cue_vlines(0);
    CB.place_stimuli(stimuli, dests);
    message = ['For this part, a single grating will appear ' ...
               'within the vertical bars on the RIGHT side of the screen.'...
               '\n\n\n Press the space bar to continue.'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    instructions = add_frame(instructions);
    sca;
    
    % ===========
    % 7. Response
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    CB.draw_fixation([0 .35 0]);
    CB.cue_vlines(0);
    message = ['After the gratings are briefly presented: \n\n' ...
               'Press the RIGHT ARROW for a grating tilted 45 degrees to the RIGHT of the vertical. \n\n' ...
               'Press the LEFT ARROW for a grating tilted 45 degrees to the LEFT of the vertical. \n\n'...
               'The fixation cross will turn GREEN when you need to make a response. \n\n\n'...
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
               'This is normal, and it is OK to guess if you cannot make out the orientation of the grating. \n\n\n' ...
               'Press the space bar to begin some practice trials!'];
           
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions); 
    sca;
    
    save('instructions/size_thresh_instruction_frames_right.mat', 'instructions')
    

    function instructions = add_frame(instructions)
        Screen('Flip', window);
        frame = reshape(Screen('GetImage', window), 1, yRes, xRes, 3);
        frame = double(frame)/255;
        instructions = cat(1, instructions, frame);
    end  
    
end


    

