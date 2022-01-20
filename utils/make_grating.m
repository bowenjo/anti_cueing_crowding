function [gratings] = make_grating(window, orientations, diameter, ...
                                   spatialFrequency, michelsonContrast, isHash,...
                                   subjectDistance, physicalWidth, resolution)
                               
    %Makes oriented grating for crowding experiments

    % Display Parameters
    pixelsPerDegree = angle2pix(subjectDistance, physicalWidth, resolution, 1);
    diameterPixels = pixelsPerDegree * diameter;
    pixelsPerCycle = pixelsPerDegree / spatialFrequency;
    cyclesPerPixel = 1/pixelsPerCycle; 
    radiansPerPixel = cyclesPerPixel * (2 * pi); 

    % ---------- Color Setup ----------
    % Retrieves color codes for black and white and gray.
    black = 0;
    white = 1;
    gray = (black + white) / 2;  

    widthOfGrid = diameterPixels;  
    widthOfGrid = round (widthOfGrid);
    if mod (widthOfGrid, 2) ~= 0
       widthOfGrid = widthOfGrid - 1 ;
    end
    halfWidthOfGrid =  (widthOfGrid / 2);
    widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

    [x, y] = meshgrid(widthArray, widthArray);
    
    % Create a circle mask
    circularMaskMatrix = (x.^2 + y.^2) < (diameterPixels/2)^2;
    absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
    
    G_mask = fspecial('gaussian', widthOfGrid+1, diameterPixels/6);
    G_mask_rescaled = 1 - (max(max(G_mask)) - G_mask) / (max(max(G_mask)) - min(min(G_mask)));
    
    % Generate display gratings from orientation
    if ~isnan(window)
        gratings = zeros(1, length(orientations));
    else
        gratings = zeros([size(x), length(orientations)]);
    end
    
    for i = 1:length(orientations)
        if ~isHash || i == 1
            imageMatrix = make_grating_texture(orientations(i));
        else
            imageMatrix1 = make_grating_texture(orientations(i));
            imageMatrix2 = make_grating_texture(orientations(i)+90);
            imageMatrix = (imageMatrix1 + imageMatrix2)/2;
        end
        
        if ~isnan(window)
            gratings(i) = Screen('MakeTexture', window, imageMatrix);
        else
            gratings(:,:,i) = imageMatrix;
        end 
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


