function [permuted_sample] = random_sample(nTrials, prop, choices, order)
% creates a random-order data sample of length nTrials composed 
% of elements from choices at different proportions
    %nTrials - int - number of trials 
    %prop - proportion to present corresponding elements in choices
    %choices - possible choices to be returned in the sample

sample = []; 
index_tracker = 1;
for i = 1:length(choices)
    if i == length(choices)
        nTrialsChoice = nTrials - length(sample);
    else
        nTrialsChoice = round(prop(i) * nTrials);
    end
    sample(index_tracker:index_tracker+nTrialsChoice-1) = ...
        repmat(choices(i), 1, nTrialsChoice);
    index_tracker = index_tracker + nTrialsChoice;
end
if ~order
    permuted_sample = sample(randperm(length(sample)));
else
    permuted_sample = sample;
end
