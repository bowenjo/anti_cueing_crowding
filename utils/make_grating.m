function [gratings] = make_grating(window, orientations, diameter, ...
                                   spatialFrequency, michelsonContrast, isHash,...
                                   subjectDistance, physicalWidth, resolution)
                               
    %Makes oriented grating for crowding experiments
    %   Detailed explanation goes here

    % Display Parameters
    pixelsPerDegree = angle2pix(subjectDistance, physicalWidth, resolution, 1);
    diameterPixels = pixelsPerDegree * diameter;
    pixelsPerCycle = pixelsPerDegree / spatialFrequency;
    cyclesPerPixel = 1/pixelsPerCycle; 
    radiansPerPixel = cyclesPerPixel * (2 * pi); 

    % ---------- Color Setup ----------
    % Retrieves color codes for black and white and gray.
    black = 0;%BlackIndex(window);  % Retrieves the CLUT color code for black.
    white = 1;%WhiteIndex(window);  % Retrieves the CLUT color code for white.
    gray = (black + white) / 2;  % Computes the CLUT color code for gray.

    widthOfGrid = diameterPixels;  % the next lines make sure that it is a whole, even number so matrix indices don’t choke.
    widthOfGrid = round (widthOfGrid);
    if mod (widthOfGrid, 2) ~= 0
       widthOfGrid = widthOfGrid - 1 ;
    end
    halfWidthOfGrid =  (widthOfGrid / 2);
    widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

    [x, y] = meshgrid(widthArray, widthArray);
    
    % Now we create a circle mask
    circularMaskMatrix = (x.^2 + y.^2) < (diameterPixels/2)^2;
    absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
    
    G_mask = fspecial('gaussian', widthOfGrid+1, diameterPixels/6);
    G_mask_rescaled = 1 - (max(max(G_mask)) - G_mask) / (max(max(G_mask)) - min(min(G_mask)));
    % Generate display gratings from orientation
    gratings = zeros(1, length(orientations));
    for i = 1:length(orientations)
        if ~isHash || i == 1
            imageMatrix = make_grating_texture(orientations(i));
        else
            imageMatrix1 = make_grating_texture(orientations(i));
            imageMatrix2 = make_grating_texture(orientations(i)+90);
            imageMatrix = (imageMatrix1 + imageMatrix2)/2;
        end
        gratings(i) = Screen('MakeTexture', window, imageMatrix); 
    end
    
    
    function imageMatrix = make_grating_texture(orientation)
        orientation = 90-orientation;
        tiltInRadians = orientation * pi / 180;
        shift_x = cos(tiltInRadians) * radiansPerPixel;
        shift_y = sin(tiltInRadians) * radiansPerPixel;
        phase = rand * (2*pi);
        imageMatrix = (gray + absoluteDifferenceBetweenWhiteAndGray * ... 
            michelsonContrast * sin(shift_x*x + shift_y*y+phase).* circularMaskMatrix .* G_mask_rescaled);
    end

end


