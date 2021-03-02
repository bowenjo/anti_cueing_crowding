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

