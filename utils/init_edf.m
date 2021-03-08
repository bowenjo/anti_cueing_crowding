function init_edf(expName, xRes, yRes)
    % sets edf file parameters
    Eyelink('Command', 'add_file_preamble_text', expName);
    
    % set recording resolution
    Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, xRes-1, yRes-1);
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, xRes-1, yRes-1);
    
    % set calibration type.
    Eyelink('Command', 'calibration_type = HV9');
    
    % set saccade thresholds
    Eyelink('Command', 'saccade_velocity_threshold = 35');
    Eyelink('Command', 'saccade_acceleration_threshold = 9500');
    
    % set measurements to record to edf file
    Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');

    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT');
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,PUPIL,STATUS,INPUT');

end

