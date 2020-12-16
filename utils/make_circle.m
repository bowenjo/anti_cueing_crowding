function [circleTexture] = make_circle(window, diameterPixel)
% makes a circle texture with a given fall off 
    color = [1.0000 0.7137 0.7569];
    radius = diameterPixel/2;
    fallOffRadius = radius/2;
    black = 0;
    white = 1;
    gray = (white+black)/2;
    
    % get the mesh grid
    widthOfGrid = round (diameterPixel);
    if mod (widthOfGrid, 2) ~= 0
       widthOfGrid = widthOfGrid - 1 ;
    end
    halfWidthOfGrid =  (widthOfGrid / 2);
    widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  
    [x, y] = meshgrid(widthArray, widthArray);
    
    % get the circle mask
    circularMaskMatrix = (x.^2 + y.^2) < (radius)^2;
    annulusMaskMatrix = (x.^2 + y.^2) < (fallOffRadius)^2;
    annulusMaskMatrix = (1 - annulusMaskMatrix) .* circularMaskMatrix;
    
    cosWeight = cos( (pi/(2*(radius-fallOffRadius))) * (sqrt(x.^2 + y.^2) - fallOffRadius) );
    cosWeight = annulusMaskMatrix .* cosWeight + (1-annulusMaskMatrix);
    
    circle = nan(widthOfGrid+1, widthOfGrid+1, 3);
    for i = 1:3
        circle(:, :, i) = gray + (color(i) - gray).*circularMaskMatrix.*cosWeight;   
    end
    
    circleTexture = Screen('MakeTexture', window, circle);
end

