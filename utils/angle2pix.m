function pix = angle2pix(subjectDistance, physicalWidth, resolution, ang)
%converts visual angles in degrees to pixels.
%Inputs:
%   subjectDistance - num - subject distance to screen in cm
%   physicalWidth - num - physical width of screen in cm
%   resolution - num - number of pixels of display in horizontal direction
%   ang - num - the angle in degrees to convert to pixels

%Calculate pixel size
pixSize = physicalWidth/resolution;  
sz = 2*subjectDistance*tan(pi*ang/(2*180));  
pix = round(sz/pixSize);  

return


