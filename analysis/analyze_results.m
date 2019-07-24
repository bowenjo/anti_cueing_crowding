function outputTable = analyze_results(resultsTable, filterIdx, filterValues)
    % load in the results table and calculate accuracy and reaction time
    % resultsTable row keys (i.e. filter indices):
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
        % check if trial was correct
        % filter by spacing and extra
        idxCorrect = [5 filterIdx];
        valueCorrect = [sp filterValues];
        spCorrect = resultsMat(9, filter_by_index(idxCorrect, valueCorrect, resultsMat));
        
        % check trail reaction times
        % filter by spacing, correct and extra
        idxRT = [5 9 filterIdx];
        valueRT = [sp 1 filterValues];
        spRT = resultsMat(2, filter_by_index(idxRT, valueRT, resultsMat));
         
        % collect and compute accuracy
        accuracy(col) = mean(spCorrect);
        reaction_time(col) = mean(spRT);
        col = col+1;
    end
    
    outputTable = table(spacing', accuracy', reaction_time', ...
        'VariableNames', {'Spacing', 'Accuracy', 'Reaction_Time'});
%     save('results/work_spacing_2flank_tang', 'outputTable')
end

function filter_indices = filter_by_index(resIndices, values, resultsMat)
    filter_indices = ones(1, length(resultsMat));
    for i = 1:length(resIndices)
        idx = resIndices(i);
        value = values(i);
        value_filter_indices = resultsMat(idx,:) == value;
        filter_indices = filter_indices .* value_filter_indices;
    end
    filter_indices = logical(filter_indices);
end
