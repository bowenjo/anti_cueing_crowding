function thresh = get_reversal_thresh(staircaseValues, nReversals)
    % Inputs:
    %   staircaseValues - array - list of staircase step values
    %   nReversals - int - # of reversals from the end to average over

    % find reversals
    shifts = (diff(staircaseValues) > 0) - (diff(staircaseValues) < 0);
    [~, indices, values] = find(shifts);
    reversalIndices = find(diff(values));
    reversalIndices = indices(reversalIndices+1);

    % get the last n reversals
    n = length(reversalIndices);
    lastReversalIndices = reversalIndices((n - (nReversals-1)):n);

    % get threshold
    thresh = mean(staircaseValues(lastReversalIndices));
end

