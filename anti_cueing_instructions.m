function [instructions] = anti_cueing_instructions()
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
    % =========
    % 1. Intro
    % =========
    % make the frame
    message = ['Part III'];
    Screen('TextSize', window, 70);
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
               'will be up for the full experiment. \n\n\n Press the space bar to continue'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    % append the frame
    instructions = add_frame(instructions);
    sca;
          
    % ===========
    % 4. Cue
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    CB.draw_fixation(.25);
    CB.cue_vlines(cueIndex);
    message = ['For any given trial, one of the two sets of vertical lines ' ...
               'will briefly become thicker and brighter. \n\n\n Press the space bar to continue'];
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', .75*yRes, 1);
    % append the frame
    instructions = add_frame(instructions); 
    sca;
    
    % ===========
    % 5. Stimulus
    % ===========
    [window, ~] = PsychImaging('OpenWindow', screenNumber, backgroundGrey);
    [stimuli, dests] = CB.make_stimuli(1, postCueIndex);
    CB.draw_fixation(.25);
    CB.cue_vlines(0);
    CB.place_stimuli(stimuli, dests);
    message = ['After the bars flash, a set of gratings will appear briefly ' ...
               'within the vertical bars on one side of the screen. \n \n The '...
               'gratings are MORE LIKELY to appear in the location OPPOSITE ' ...
               'to the bars that just flashed. \n\n\n Press the space bar to continue.'];
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
    message = ['After the gratings are briefy presented: \n \n' ... 
               'Press the RIGHT ARROW for a CENTRAL grating tilted 45 degrees to the RIGHT of the vertical. \n \n' ...
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
    message = ['Following these instructions, there will be a few practice trials. \n \n'...
               'After the practice trials, the main experiment will consist of 8 sets of 120 trials' ...
               '(~1hr total). \n \n After each set of 120 trials, there will be an ' ...
               'opportunity for a break. \n \n Thank you again for taking part in this ' ...
               'experiment. \n\n\n Press the space bar to begin some practice trials!'];
           
    Screen('TextSize', window, textSize);
    DrawFormattedText(window, message, 'center', 'center', 1);
    instructions = add_frame(instructions); 
    sca;
    
    save('instructions/anti_cueing_instruction_frames.mat', 'instructions')
    

    function instructions = add_frame(instructions)
        Screen('Flip', window);
        frame = reshape(Screen('GetImage', window), 1, yRes, xRes, 3);
        frame = double(frame)/255;
        instructions = cat(1, instructions, frame);
    end  
    
end


    

