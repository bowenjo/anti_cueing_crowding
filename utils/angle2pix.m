function pix = angle2pix(subjectDistance, physicalWidth, resolution, ang)
    %converts visual angles in degrees to pixels.
    %   subjectDistance - num - subject distance to screen in cm
    %   physicalWidth - num - physical width of screen in cm
    %   resolution - num - number of pixels of display in horizontal direction
    %   ang - num - the angle in degrees to convert to pixels

    pixSize = physicalWidth/resolution;  
    sz = subjectDistance*tan(pi*ang/(180));  
    pix = round(sz/pixSize);

return


