function testAnalysis

resultsTable = load('test_spacing.mat');
resultsTable = resultsTable.resultsTable;

mat = resultsTable.Variables;

 
mat_t = mat';
mat_t(:, 9) = mat_t(:,1) == mat_t(:,4);

% column 9 has accuracy

spacings = [1.75 2.5 3.25 4 4.75 5.5 6.25 0];

numTrials = 160;

row = 1;

for i = 1:size(spacings, 2)
    idx = mat_t(mat_t(:,5) == spacings(i));
    sp_accuracy = mat_t(logical(idx), 9);
    sp_rt = mat_t(logical(idx), 2);
    finalmat(row, 1) = spacings(i);
    finalmat(row, 2) = mean(sp_accuracy);
    finalmat(row, 3) = mean(sp_rt);
    row = row+1;
end

save('work.mat', 'finalmat')
