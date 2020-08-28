function analyzedResults = analyze_results(results, xKey, yKeys, filterKeys, ...
    filterValues, filterRelationOperators, fn)
    % load in the results structure and calculate mean yKey values per xKey
    % Paramaters
    %   results - struct - results structure with fields 
    %   xKey - string - independent variable field name
    %   yKeys - cell array - dependent variables field names
    %   filterKeys - cell array - results structure field name to filter
    %   filterValues - array - corresponding field values to filter by
    %   filterRelationOperators - cell array - operations to filter values
    %   fn - matlab function - summary statistic function (i.e. mean, sum)
    
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
            fOperators = filterRelationOperators;
            % add on the filter keys, values, operators, for the independent variable
            fKeys(nFilters+1) = {xKey};
            fValues(nFilters+1) = xValues(i);
            fOperators(nFilters+1) = {'eq'};
            % filter by keys and values
            filterIndices = filter_by_index(results, fKeys, fValues, fOperators);
            analyzedResults.(string(yKey)) = ...
                [analyzedResults.(string(yKey)) fn(yValues(filterIndices))]; 
        end
    end

end

function filterIndices = filter_by_index(results, filterKeys, filterValues, ...
    filterRelationOperators)
    filterIndices = ones(1, length(results.(string(filterKeys(1)))));
    for i = 1:length(filterKeys)
        % only pass non-NaN values
        nanFilterIndices = 1 - isnan(results.(string(filterKeys(i))));
        % filter by keys and values
        valueFilterIndices =  feval(string(filterRelationOperators(i)), ...
            results.(string(filterKeys(i))), filterValues(i));
        filterIndices = nanFilterIndices .* filterIndices .* valueFilterIndices;
    end
    filterIndices = logical(filterIndices);
end
