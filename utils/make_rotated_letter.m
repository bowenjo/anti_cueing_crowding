function [rotatedLetters] = make_rotated_letter(window, letterTypes, ...
    orientations, fontSize, fontLineWidth, subjectDistance, ...
    physicalWidth, resolution)

    %MAKE_ROTATED_LETTER
    black = 0;
    white = 1;
    grey = (black+ white) / 2;
    letterColor = [grey black];

    sizePx = angle2pix(subjectDistance, physicalWidth, resolution, fontSize);
    lwPx = angle2pix(subjectDistance, physicalWidth, resolution, fontLineWidth);

    rotatedLetters = zeros(1, length(orientations));
    for i = 1:length(orientations)
        letterType = letterTypes(i);
        angle = orientations(i);
        if letterType == 'T'
            imageMatrix = make_T(sizePx, sizePx, lwPx, angle, letterColor);
        elseif letterType == 'H'
            imageMatrix = make_H(sizePx, sizePx, lwPx, angle, letterColor);
        else
            break
        end
        rotatedLetters(i) = Screen('MakeTexture', window, imageMatrix); 
    end
end

function T = make_T(h, w, lw, angle, color)
    T = repmat(color(1), h, w);
    c = w/2;
    % Top of T
    T(1:lw+1, :) = color(2);
    % stem of T
    T(:, (c-lw/2):(c+lw/2)) = color(2);
    % rotate by angle
    T = imrotate(T, angle); 
end
    
function H = make_H(h, w, lw, angle, color)
    H = repmat(color(1), h, w);
    c = w/2;
    % Top of H
    H(1:lw+1, :) = color(2);
    % Bottom of H
    H(h-lw:h, :) = color(2);
    % stem of T
    H(:, (c-lw/2):(c+lw/2)) = color(2);
    % rotate by angle
    H = imrotate(H, angle);
end

