function init_edf(expName, edfFile, xRes, yRes)
    % Initializes eyeLink-connection, creates edf-file
    % and writes experimental parameters to edf-file
    dummymode = 0;
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        % cleanup;  % cleanup function
        return;
    end
    
    % Create the file
    status=Eyelink('openfile', edfFile);
    if status~=0
        error('openfile error, status: %d', status)
    end
    %end

    % require eyelink is offline
    commandString = sprintf('add_file_preamble_text %s', expName);
    Eyelink('Command', commandString);

    % setup tracker config
    % Setting the proper recording resolution, proper calibration type,
    % as well as the data file content;
    Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, xRes-1, yRes-1);
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, xRes-1, yRes-1);
    % set calibration type.
    Eyelink('Command', 'calibration_type = HV9');
    % set parser (conservative saccade thresholds)
    Eyelink('Command', 'saccade_velocity_threshold = 35');
    Eyelink('Command', 'saccade_acceleration_threshold = 9500');
    % set EDF file contents
    Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
    % set link data (used for gaze cursor)
    Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    % check status
    status = Eyelink('Command','link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT');
    if status~=0
        error('link_sample_data error, status: %d',status)
    end

    % experiment description
    Eyelink('Message', 'BEGIN OF DESCRIPTIONS');
    Eyelink('Nessage', 'Subject-ID %s',  edfFile(1:end-length('.edf')));
end

