function flankerOrientations = pick_ensemble_flankers(nFlankers, t, mu, sigma, ...
    minAngle, maxAngle)
    % generates ensemble of randomly chosen orientations w/ mean of a set value
    %   nFlankers - int - number of flankers to assign an orientation
    %   t - float - target orientation
    %   mu - float - mean of the ensemble (target & flankers)
    %   sigma - float - std dev of gaussian to pick orientations
    %   minAngle - float - lower limit of the range of values to be chosen
    %   maxAngle - float - upper limit of the range of values to be chosen
    
    % distribtion range information
    distances = abs([minAngle, maxAngle] - mu);
    minDistance = min(distances);
    
    % get the flanker(s) to keep the mean given the target
    [x,n] = get_flanker(t, mu, minDistance);
    flankerOrientations = repmat(x,n,1);
    
    % initialize the normal distribution
    pd = makedist('Normal', 'mu', mu, 'sigma', sigma); 
    
    % set the remaining flankers
    while numel(flankerOrientations) < nFlankers
        % truncate the distribution
        d = min(distances/minDistance, ...
            nFlankers-(numel(flankerOrientations)+1));
        lowerAngle = mu - d(1)*minDistance;
        upperAngle = mu + d(2)*minDistance;
        % sample an orientation from the distribution
        if lowerAngle ~= upperAngle
            pd = truncate(pd, lowerAngle, upperAngle);
            f = random(pd);
        else
            f = mu;
        end     
        % get the min number of orientation(s) to keep the mean
        [x,n] = get_flanker(f, mu, minDistance);
        flankerOrientations = [flankerOrientations; f; repmat(x,n,1)];
    end
    permIndices = randperm(numel(flankerOrientations));
    flankerOrientations = flankerOrientations(permIndices);
return

function [x,n] = get_flanker(f,mu,minDistance)
    % get n: min number of flankers to keep mu
    n = ceil(abs(mu-f)/minDistance);
    % get x: the orientation value to keep mu
    if n ~= 0
        x = (mu*(1+n)-f)/n;
    else
        x=nan;
    end
        
return

