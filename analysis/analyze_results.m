function outputTable = analyze_results(resultsTable, filter_idx, filter_value)
    % load in the results table and calculate accuracy and reaction time
    % resultsTable row keys:
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
        % indices for given spacing
        spIdx = resultsMat(5,:) == sp;
        % get accuracy for given spacing
        spCorrect = resultsMat(9, spIdx); 
        % only get RT for correct trials
        spRT = resultsMat(2, filter_by_index(9, 1, spIdx, resultsMat));
%         
%         if filter_idx ~= 0
%             
%         end
%         
        % collect and compute accuracy
        accuracy(col) = mean(spCorrect);
        reaction_time(col) = mean(spRT);
        col = col+1;
    end
    
    outputTable = table(spacing', accuracy', reaction_time', ...
        'VariableNames', {'Spacing', 'Accuracy', 'Reaction_Time'});
%     save('results/work_spacing_2flank_tang', 'outputTable')
end

function filter_indices = filter_by_index(idx, value, spIdx, resultsMat)
    value_filter_indices = resultsMat(idx,:) == value;
    filter_indices = logical(spIdx .* value_filter_indices);
end
