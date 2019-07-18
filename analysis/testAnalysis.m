function outputTable = testAnalysis(resultsTable)
    % load in the results table and calculate accuracy and reaction time
    % Table row indices:
    %   1. resp key
    %   2. RT
    %   3. fix_check
    %   4. target_key
    %   5. spacing
    %   6. valid
    %   7. valid_prob
    %   8. soa_time
    %   9. correct
    resultsMat = resultsTable.Variables;
    
    % find the accuracy values
    resultsMat(9, :) = resultsMat(1,:) == resultsMat(4,:);
    % get the unique spacings
    spacing = unique(resultsMat(5, :));

    col = 1;
    for sp = spacing
        spIdx = resultsMat(5,:) == sp;
        spAccuracy = resultsMat(9, spIdx);
        spRT = resultsMat(2, logical(spIdx .* resultsMat(9,:)));

        accuracy(col) = mean(spAccuracy);
        reaction_time(col) = mean(spRT);
        col = col+1;
    end
    
    outputTable = table(spacing', accuracy', reaction_time', ...
        'VariableNames', {'Spacing', 'Accuracy', 'Reaction_Time'});
%     save('results/work_spacing_2flank_tang', 'outputTable')
end
