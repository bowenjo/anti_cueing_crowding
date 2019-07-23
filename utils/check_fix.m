function fixated = check_fix(el, fixLoc)
    fixated=0;
    eye_used = Eyelink('EyeAvailable');  % find which eye

    if Eyelink('IsConnected') == el.dummyconnected
        [x,y,~] = GetMouse(el.window); % get gaze position from mouse
        pupil=1;
    else
        evt = Eyelink('NewestFloatSample'); 
        % for tracked eye, get horizontal gaze position from sample
        x = evt.gx(eye_used+1); 
        % for tracked eye, get vertical gaze position from sample 
        y = evt.gy(eye_used+1);
        % check if the pupil is visible
        pupil=evt.pa(eye_used+1);
    end

    % decide if the subject is fixated
    if pupil>0  % pupil visible
        if x>fixLoc(RectLeft) && x <fixLoc(RectRight) && ...
           y>fixLoc(RectTop) && y<fixLoc(RectBottom) % within the fixation location
            fixated=1;
        end
    end

end

