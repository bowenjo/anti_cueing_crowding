function [gratings] = make_grating(window, orientations, thickness, diameter, ...
                                   spatialFrequency, michelsonContrast)
                               
    %Makes oriented grating for crowding experiments
    %   Detailed explanation goes here

    % Display Parameters
    pixelsPerDegree = 1;
    pixelsPerCycle = pixelsPerDegree / spatialFrequency;
    cyclesPerPixel = 1/pixelsPerCycle; 
    radiansPerPixel = cyclesPerPixel * (2 * pi); 

    % Set diameter of Targets as well as diameter and thickness of Convergence
    convergenceAnnulusDiameterPixels = diameter * pixelsPerDegree;
    convergenceAnnulusThicknessPixels = thickness * pixelsPerDegree;

    % Get the width of the grid
    widthOfGrid = round(convergenceAnnulusDiameterPixels);
    if mod (widthOfGrid, 2) ~= 0
        widthOfGrid = widthOfGrid + 1 ;
    end

    halfWidthOfGrid =  (widthOfGrid / 2);
    widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  
    spacing=1;

    % ---------- Color Setup ----------
    % Retrieves color codes for black and white and gray.
    black = 0;%BlackIndex(window);  % Retrieves the CLUT color code for black.
    white = 1;%WhiteIndex(window);  % Retrieves the CLUT color code for white.
    gray = (black + white) / 2;  % Computes the CLUT color code for gray.

    % Creates a two-dimensional square grid.  For each element i = i(x0, y0) of
    % the grid, x = x(x0, y0) corresponds to the x-coordinate of element "i"
    % and y = y(x0, y0) corresponds to the y-coordinate of element "i"
    [x, y] = meshgrid(widthArray, widthArray);

    % Now we create a circle mask
    circularMaskMatrix = (x.^2 + y.^2) < (diameter/2)^2;

    % Create annulus
    convergenceAnnulus = ...
        ((x.^2 + y.^2) >= (convergenceAnnulusDiameterPixels/2 - convergenceAnnulusThicknessPixels)^2 )  & ...
        ((x.^2 + y.^2) <  (convergenceAnnulusDiameterPixels/2)^2 );
    convergenceAnnulus = ~convergenceAnnulus;

    % Taking the absolute value of the difference between white and gray will
    % help keep the grating consistent regardless of whether the CLUT color
    % code for white is less or greater than the CLUT color code for black.
    absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
    graySpacerMatrix =  ones(widthOfGrid+1,(widthOfGrid)*spacing ) * gray; % this is the grey stuff in the middle
    blankTargetMatrix = ones(widthOfGrid+1, widthOfGrid+1) * gray;
    blankedGratingMatrix = blankTargetMatrix .*convergenceAnnulus;
    blankTexture = [blankedGratingMatrix, graySpacerMatrix, blankedGratingMatrix];
    blanktex = Screen('MakeTexture', window, blankTexture);
    Screen('TextSize', window, 60);
    Screen('FillRect',window, gray);

    % Generate display gratings from orientation
    gratings = zeros(1, length(orientations));
    for i = 1:length(orientations)
        tiltInRadians = orientations(i) * pi / 180;
        shift_x = cos(tiltInRadians) * radiansPerPixel;
        shift_y = sin(tiltInRadians) * radiansPerPixel;
        phase = pi/2;
        imageMatrix = (gray + absoluteDifferenceBetweenWhiteAndGray * ... 
            michelsonContrast * sin(shift_x*x + shift_y*y+phase).* circularMaskMatrix);
        gratings(i) = Screen('MakeTexture', window, imageMatrix); 
    end
end

