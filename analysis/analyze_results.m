function analyzedResults = analyze_results(results, xKey, yKeys, filterKeys, filterValues)
    % load in the results structure and calculate mean yKey values per xKey
    % Paramaters
    %   results - struct - results structure with fields 
    %   xKey - string - independent variable field name
    %   yKeys - cell array - dependent variables field names
    %   filterKeys - cell array - results structure field name to filter
    %   filterValues - array - corresponding field values to filter by
    
    nFilters = length(filterKeys);
    xValues = unique(results.(string(xKey)));
    
    % initialize the anlyzed results structure
    analyzedResults = struct;
    analyzedResults.(string(xKey)) = xValues;
    for yKey = yKeys
        analyzedResults.(string(yKey)) = [];
    end
    
    % loop over the independent vairable values
    for i = 1:length(xValues)
        for yKey = yKeys
            % get the dependent variable values
            yValues = results.(string(yKey));
            % set the filter keys and values
            fKeys = filterKeys;
            fValues = filterValues;
            fKeys(nFilters+1) = {xKey};
            fValues(nFilters+1) = xValues(i);
            % filter by keys and values
            filterIndices = filter_by_index(results, fKeys, fValues);
            analyzedResults.(string(yKey)) = ...
                [analyzedResults.(string(yKey)) mean(yValues(filterIndices))]; 
        end
    end

end

function filterIndices = filter_by_index(results, filterKeys, filterValues)
    filterIndices = ones(1, length(results.(string(filterKeys(1)))));
    for i = 1:length(filterKeys)
        valueFilterIndices =  results.(string(filterKeys(i)))== filterValues(i);
        filterIndices = filterIndices .* valueFilterIndices;
    end
    filterIndices = logical(filterIndices);
end
