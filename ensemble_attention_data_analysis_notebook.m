%% Set the paths
utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)


%% Parameters
subKeys = {'sub001', 'sub002', 'sub003', 'sub004', 'sub005','sub006', 'sub007', ...
    'sub008', 'sub009', 'sub010', 'sub012', 'sub013', 'sub014', 'sub015', 'sub017', ...
    'sub018', 'sub020', 'sub021', 'sub022'};
% subKeys= {'sub001', 'sub002', 'sub003', 'sub006'};
session = '/1';
blocks = {'block_1','block_2','block_3','block_4', ...
    'block_5','block_6','block_7','block_8'};

choices = {'sp', 'bp', 'sn', 'bn', 'so', 'bo'};

%% Run the analysis 
results = struct;
MEANS = [];
SEMS = [];
SCORES = [];
ENSEMBLE_STDS = [];
SUB_KEY_INDICES = [];

All = struct;
for c = choices
    results.(string(c)) = []; 
    scores = struct; scores.v = []; scores.i = [];
    ensemble_stds = struct; ensemble_stds.v = []; ensemble_stds.i = [];
    sub_key_indices = struct; sub_key_indices.v = []; sub_key_indices.i = [];
    cue_sizes = [];
    subNumber = 1;
    
    for key = subKeys
        subDir = ['ensemble_results/' char(key) session];
        if exist(subDir, 'dir')
            subResults = load([subDir '/experiment_results.mat']);
            subResults = subResults.results;
            upCueSize = max(subResults.cue_size);
            lowCueSize = min(subResults.cue_size);
            cue_sizes = [cue_sizes; lowCueSize upCueSize]; 
            filters = get_filters(c, upCueSize, lowCueSize);
            scoreResults = clip_results(subResults,121,1080); 
            
            % flanker data
            subExp = load([subDir '/Experiment.mat']);
            subExp = subExp.Exp;
            All.(string(key)) = subExp;
            Ensembles = [];
            for b = blocks
                ensemble = [subExp.blocks.(string(b)).expDesign.T; subExp.blocks.(string(b)).expDesign.F];
                Ensembles = [Ensembles ensemble];   
            end
            
            % analysis on flankers
            stdEnsemble = std(Ensembles, 0, 1);
            validity_value = 0;
            for validity = ['v','i']
                filterIndices = filter_by_index(scoreResults, ...
                    {'valid', 'cue_size', 'target_ensemble_relation'}, [validity_value filters], {'eq','eq','eq'});

                scores.(validity) = [scores.(validity) scoreResults.correct(filterIndices)];
                ensemble_stds.(validity) = [ensemble_stds.(validity) stdEnsemble(filterIndices)];
                sub_key_indices.(validity) = [sub_key_indices.(validity) subNumber.*ones(1, sum(filterIndices))];
                validity_value = validity_value + 1;
            end
            subNumber = subNumber + 1; 
            
            % Accuracy/RT data
            score = analyze_results(scoreResults, 'valid', {'correct'},...
                {'cue_size', 'target_ensemble_relation'}, filters, {'eq', 'eq'}, @mean);
            
            results.(string(c)) = [results.(string(c)) ; score.correct];
        end    
    end
    
    r = results.(string(c));
    MEANS = [MEANS; mean(r,1)];
    SEMS = [SEMS;  std(r,0,1)./sqrt(length(r))];
    SCORES = [SCORES; scores];
    ENSEMBLE_STDS = [ENSEMBLE_STDS; ensemble_stds];
    SUB_KEY_INDICES = [SUB_KEY_INDICES; sub_key_indices];

end

if string(session) == "/1"
    session1_results = results;
else
    session2_results = results;
end

%%
close all
figure('Position', [10 10 200 300])
hBar = bar(mean(cue_sizes,1));
set(gca, 'xTickLabel',  ["Small", "Big"]);
hold on
errorbar(mean(cue_sizes,1), std(cue_sizes,0,1), '.', 'Color', 'k')
ylabel("Mean Diameter (deg)")
xlabel("Cue Type")
saveas(gcf, "figures/ensemble/cue_sizes.png")


%% Performance and differences plots
close all
figure('Position', [10 10 900 560]);
colors = [ .25, .65, .55; .35, .45, .95; .95, .45, .4];
alpha = .5;

plot_perf_diff(2, 3, results, 1:6, "Prop. correct", [.2,1], ...
               {'Prop. correct'; 'Valid (V) - Invalid (I)'}, [-.2,.25], colors, alpha)

% anova
get_anova_tables(results, 'lsd')

saveas(gcf, "figures/ensemble/target_task_perf_diff_vi.png")

%% Slope of prop correct binned by ensemble std dev
nBins=5;
results_slope = struct;
data_points = struct;
% bar plots for slopes
for c = 1:6
    [edges_v, prop_correct_v] = bin_by_value(SCORES(c).v, SUB_KEY_INDICES(c).v, ENSEMBLE_STDS(c).v, nBins);
    [edges_i, prop_correct_i] = bin_by_value(SCORES(c).i, SUB_KEY_INDICES(c).i, ENSEMBLE_STDS(c).i, nBins);
    slopes = [];
    for sub = 1:length(subKeys)
        p_v = polyfit(edges_v, prop_correct_v(:,sub)', 1);
        p_i = polyfit(edges_i, prop_correct_i(:,sub)', 1);
        slopes = [slopes ; p_v(1) p_i(1) p_v(2) p_i(2)];
    end
    results_slope.(string(choices(c))) = slopes;  
    data_points.(string(choices(c))) = [edges_v' mean(prop_correct_v,2) edges_i' mean(prop_correct_i,2)];
end


% generate figure
close all
figure('Position', [10 10 1250 450])
colors = [ .25, .65, .55; .35, .45, .95; .95, .45, .4];
alpha = .6;

subplot(2,5, [1,2,6,7])
% totals
i = 1;
slopes = [];
for c = ['p', 'n', 'o']
    total = (data_points.("s"+c) + data_points.("s"+c)) / 2;
    total = [(total(:,1) + total(:,3))/2, (total(:,2) + total(:,4))/2];
    p = polyfit(total(:,1)', total(:,2)', 1);
    slopes = [slopes p(1)];
    % plot
    scatter(total(:,1)', total(:,2)', 30, 'Marker', 's', 'MarkerFaceColor', colors(i,:), ...
           'MarkerEdgeColor', colors(i,:), 'MarkerFaceAlpha', alpha)
    hold on
    plot(total(:,1)', f_line(total(:,1)', p(1), p(2)), 'Color', colors(i,:), 'LineWidth',2)
    hold on
    i = i+1;
end
xlabel("Standard Deviation (degrees)")
ylabel("Prop. Correct")
legend('Congruent', char(compose('slope = %4.2e',slopes(1))), ...
       'Neutral', char(compose('slope = %4.2e',slopes(2))), ...
       'Incongruent', char(compose('slope = %4.2e',slopes(3))), 'Location', 'NorthEast')
ti = title('All Cueing Conditions');
ti.FontWeight = 'normal';
ax = gca;
set(ax, 'LineWidth',1.5)
% ylim([.2,1])


plot_perf_diff(2, 5, results_slope, [3,4,5,8,9,10], {'Mean slope';'(prop. correct/degree)'}, [-.015,.015], ...
               {'Mean slope'; 'Valid (V) - Invalid (I)'}, [-.015,.015], colors, alpha)
           
% anova
get_anova_tables(results_slope, 'tukey-kramer')
saveas(gcf, "figures/ensemble/target_task_std_slope_vi.png")

%% All data bar blot
close all
figure('Position', [10 10 700 500])
y = [];
err = [];
for i = 1:2:length(MEANS)
    y = [y; MEANS(i:i+1, 1)' MEANS(i:i+1, 2)'];
    err = [err; SEMS(i:i+1, 1)' SEMS(i:i+1, 2)'];
end

L1 = ["Small" "Big"];
L2 = ["Valid" "Invalid"];
L3 = ["Congruent", "Neutral", "Incongruent"]; 

hBar = bar(1:length(L3), y);
c = get(hBar,'FaceColor');
for i=1:2:length(hBar)
    hBar(i).FaceColor = c{1};
    hBar(i+1).FaceColor = c{2};
end
hAx=gca;                       
hold on
X=cell2mat(get(hBar,'XData')).'+ [hBar.XOffset];  % compute bar locations

cntL2 = X(:, 1:2:4) + (X(:, 2:2:4) - X(:, 1:2:4))/2;
set(hAx, 'xTick', sort(cntL2(:)), 'xTickLabel', L2);

th = text([1 2 3], .47 + [-.06 -.06 -.06], L3);
set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')

hEB = errorbar(X, y,err,'.');  % add the errorbar
for i=1:length(hEB)            
    hEB(i).Color='k';
end
hleg = legend(L1, 'Location', 'northeast');
title(hleg, "Cue Size")
ylabel("Ensemble Mean Accuracy (Prop. correct)")
ylim([.45,1])
% saveas(gcf, "figures/ensemble/ensemble_task_performance.png")

%% Difference plots (neutral baseline)

figure('Position', [10 10 800 700])
titles = ["Congruent - Neutral", "Incongruent - Neutral"];
colors = [ .25, .65, .55; .35, .45, .95; .95, .45, .4];
alpha = .5;


% congruent - neutral
MEANS = [];
SEMS = [];
for c = ['p', 'o']
    small_validity_diff = results.("s"+ c) - results.("sn");
    big_validity_diff = results.("b"+c) - results.("bn");
    
    MEANS = [MEANS; mean(small_validity_diff,1); mean(big_validity_diff,1)];
    SEMS = [SEMS;  std(small_validity_diff,0,1)./sqrt(length(r)); std(big_validity_diff,0,1)./sqrt(length(r))];
      
end 

close all
figure('Position', [10 10 700 500])
y = [];
err = [];
for i = 1:2:length(MEANS)
    y = [y; MEANS(i:i+1, 1)' MEANS(i:i+1, 2)'];
    err = [err; SEMS(i:i+1, 1)' SEMS(i:i+1, 2)'];
end

L1 = ["Small" "Big"];
L2 = ["Valid" "Invalid"];
L3 = ["Congruent - Neutral", "Incongruent - Neutral"]; 

hBar = bar(1:length(L3), y);
c = get(hBar,'FaceColor');
for i=1:2:length(hBar)
    hBar(i).FaceColor = c{1};
    hBar(i+1).FaceColor = c{2};
end
hAx=gca;                       
hold on
X=cell2mat(get(hBar,'XData')).'+ [hBar.XOffset];  % compute bar locations

cntL2 = X(:, 1:2:4) + (X(:, 2:2:4) - X(:, 1:2:4))/2;
set(hAx, 'xTick', sort(cntL2(:)), 'xTickLabel', L2);

th = text([1 2], 0 + [-.07 -.07], L3);
set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')

hEB = errorbar(X, y,err,'.');  % add the errorbar
for i=1:length(hEB)            
    hEB(i).Color='k';
end
hleg = legend(L1, 'Location', 'northeast');
title(hleg, "Cue Size")
ylabel("Target Accuracy (gain)")
% ylim([.45,1])

saveas(gcf, "figures/ensemble/target_task_neutral_diff.png")



%% correlate sessions
% TODO: Do correlation analysis on the "raw" scores and not the differences
% for the neutral condition for the two sessions

figure('Position', [10 10 2000 500])
colors = ['b', 'r'];
pInit.m = 1;
pInit.b = 0;
titles = ["Congruent", "Neutral", "Incongruent"];

i = 1;
for c = ["p", "n", "o"]
    subplot(1,3,i)
    valid_data.x = -diff([session1_results.("s"+c)(:,1)' ; session1_results.("b"+c)(:,1)']);
    invalid_data.x = -diff([session1_results.("s"+c)(:,2)' ; session1_results.("b"+c)(:,2)']);

    valid_data.y = -diff([session2_results.("s"+c)(:,1)' ; session2_results.("b"+c)(:,1)']);
    invalid_data.y = -diff([session2_results.("s"+c)(:,2)' ; session2_results.("b"+c)(:,2)']);
    
    valid_data.w = ones(1, length(valid_data.x)) ./ length(valid_data.x);
    invalid_data.w = ones(1, length(invalid_data.x)) ./ length(invalid_data.x);
    
    pFit_valid = minimize_objective({'m', 'b'}, [], [], @squared_error, ...
        pInit, valid_data, @poly1);
    [corr_valid, pVal_valid] = corrcoef(valid_data.x', valid_data.y');
    
    pFit_invalid = minimize_objective({'m', 'b'}, [], [], @squared_error, ...
        pInit, invalid_data, @poly1);
    [corr_invalid, pVal_invalid] = corrcoef(invalid_data.x', invalid_data.y');
    
    
    hold on
        % valid
        x = linspace(min(valid_data.x), max(valid_data.x), 1000);
        scatter(valid_data.x, valid_data.y, 30, 'Marker', 's', 'MarkerFaceColor', 'blue', ...
            'MarkerEdgeColor', 'blue')
        plot(x, poly1(pFit_valid, x), 'Color', 'blue', 'LineWidth', 2)

        % invalid
        x = linspace(min(invalid_data.x), max(invalid_data.x), 1000);
        scatter(invalid_data.x, invalid_data.y, 30, 'Marker', 's', 'MarkerFaceColor', 'red', ...
            'MarkerEdgeColor', 'red')
        plot(x, poly1(pFit_invalid, x), 'Color', 'red', 'LineWidth', 2)
        
        xlabel('Target Task Accuracy (Small - Big)')
        ylabel('Ensemble Task Accuracy (Small - Big)')
%         legend('valid trials', 'invalid trials')
        title(titles(i))
        
        legend('Valid Trials:', char(compose('r = %4.3f; (p-val: %4.3f)', [corr_valid(2), pVal_valid(2)])), ...
               'Invalid Trials', char(compose('r = %4.3f; (p-val: %4.3f)', [corr_invalid(2), pVal_invalid(2)])))
    hold off
    i = i+1;
   
    
end
saveas(gcf, "figures/ensemble/corr_small_big.png")


%% Visualize Ensemble:

% initialize the arrays
observed_mean_bias = struct;
choices = {'sv', 'bv', 'si', 'bi'};
for c = choices
    observed_mean_bias.(string(c)) = [];
end
observed_mean_bias.total = [];
observed_mean_bias.ideal = [];

% calculate the mean biases of the ensembles
for key = subKeys
    subDir = ['ensemble_results/' char(key) session];
    if exist(subDir, 'dir')
        % Score data
        subResults = load([subDir '/experiment_results.mat']);
        subResults = subResults.results;
        scoreResults = clip_results(subResults,121,1080); % non-practice trials
        % cue sizes
        upCueSize = max(subResults.cue_size);
        lowCueSize = min(subResults.cue_size);

        % Ensemble data
        subExp = load([subDir '/Experiment.mat']);
        subExp = subExp.Exp;

        % gather the orientations of the ensembles
        Ensembles = [];
        displaySides = [];
        for b = blocks
            ensemble = [subExp.blocks.(string(b)).expDesign.T; subExp.blocks.(string(b)).expDesign.F];
            Ensembles = [Ensembles ensemble];   
            displaySides = [displaySides subExp.blocks.(string(b)).expDesign.cue_loc];
        end

        % Correct for the display side
        % indices when the stimulus appeared on the left side of the screen
        leftIndices = ((displaySides == 1) & (scoreResults.valid == 0)) | ...
            ((displaySides == 2) & (scoreResults.valid == 1));
        % flip to normalize all to right side of screen
        Ensembles(3:end, leftIndices) = flip(Ensembles(3:end, leftIndices), 1);
        
        % loop over conditions;
        for c = choices
            filters = get_filters_less(c, upCueSize, lowCueSize);
            filterIndices = filter_by_index(scoreResults, ...
                    {'valid', 'cue_size'}, [filters], {'eq','eq'});
            o = orientation_importance(Ensembles(:, filterIndices), ...
                scoreResults.response(filterIndices));
            observed_mean_bias.(string(c)) = [observed_mean_bias.(string(c)) mean(o,2)];
        end
            
        % overall observed performance
        o_observed = orientation_importance(Ensembles, scoreResults.response);
        observed_mean_bias.total = [observed_mean_bias.total mean(o_observed,2)];
        % ideal observed performance
        o_ideal = orientation_importance(Ensembles, scoreResults.ensemble_mean);
        observed_mean_bias.ideal = [observed_mean_bias.ideal mean(o_ideal,2)];
        
    end
end

%%
P = [mean(observed_mean_bias.total, 2)'; mean(observed_mean_bias.total, 2)'];
F = P(:, 2:end);
% F = [F; repmat(P(1,1), 1, 9); repmat(P(2,1), 1, 9)];
%     F = [F; repmat(52, 1, 9); repmat(52, 1, 9)];
% m_lim = repmat(57, 1, 9);
% M_lim = repmat(62, 1, 9);
    m_lim = repmat(min(min(F)), 1, 9);
    M_lim = repmat(max(max(F)), 1, 9);
% Spider plot
spider_plot(F, ...
    'AxesLimits', [m_lim; M_lim], ...
    'AxesDisplay', 'one', ...
    'AxesLabels', {'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9'}, ... 
    'LineStyle', {'-', '-'}, ...
    'Color', [0 0 1; 1 0 0], ...,
    'FillOption', {'on', 'on'}, ...
    'FillTransparency', [.1 .1 ], ...
    'LineTransparency', [.75 .75], ...
    'Direction', 'counterclockwise', ...
    'LabelFontSize', 8, ..., 
    'AxesFontSize', 12, ...
    'Marker', 'none', ...
    'AxesScaling', 'linear')

legend('Target Task', 'Ensemble Task', 'Location', 'southeastoutside', 'FontSize',8);
th = text([-1.4 1.4 0 0], [0 0 -1.4 1.4], ["Inner", "Outer", "Lower", "Upper"]);
saveas(gcf, "figures/ensemble/target_vs_ensemble.png")


%%
close all
titles = ["Valid trials", "Invalid trials"];
figure('Position', [10 10 2000 1000]);
i = 1;
for v = ["v", "i"]
    subplot(1,2,i)
    P = [mean(observed_mean_bias.("s"+v), 2)'; mean(observed_mean_bias.("b"+v), 2)'];
    F = P(:, 2:end);
    F = [F; repmat(P(1,1), 1, 9); repmat(P(2,1), 1, 9)];
%     F = [F; repmat(52, 1, 9); repmat(52, 1, 9)];
%     m_lim = repmat(57, 1, 9);
%     M_lim = repmat(62, 1, 9);
    m_lim = repmat(min(min(P)), 1, 9);
    M_lim = repmat(max(max(P)), 1, 9);
    % Spider plot
    spider_plot(F, ...
        'AxesLimits', [m_lim; M_lim], ...
        'AxesDisplay', 'one', ...
        'AxesLabels', {'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9'}, ... 
        'LineStyle', {'-', '-', '--', '--'}, ...
        'Color', [0 0 1; 1 0 0; 0 0 1; 1 0 0], ...,
        'FillOption', {'on', 'on','off','off'}, ...
        'FillTransparency', [.1 .1 .1 .1], ...
        'LineTransparency', [.75 .75 .5 .5], ...
        'Direction', 'counterclockwise', ...
        'LabelFontSize', 8, ..., 
        'AxesFontSize', 12, ...
        'Marker', 'none', ...
        'AxesScaling', 'linear')
    
    legend('Small Cue', 'Big Cue', 'Target (small)', 'Target (big)', 'Location', 'southeastoutside', 'FontSize',8);
    th = text([-1.4 1.4 0 0], [0 0 -1.4 1.4], ["Inner", "Outer", "Lower", "Upper"]);
    title_th = text(0,1.7,titles(i), 'FontSize', 14);
    set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
    set(title_th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
    i = i+1;
end

saveas(gcf, "figures/ensemble/ensemble_task_flankers_all_incorrect_trials.png")

%%
function filters = get_filters(choice, upCueSize, lowCueSize)
    if choice == "bp"
        filters = [upCueSize, 0];
    elseif choice == "bn"
        filters = [upCueSize, 45];
    elseif choice == "bo"
        filters = [upCueSize, 90];
    elseif choice == "sp"
        filters = [lowCueSize, 0];
    elseif choice == "sn"
        filters = [lowCueSize, 45];
    elseif choice == "so"
        filters = [lowCueSize, 90];
    end
end

function filters = get_filters_less(choice, upCueSize, lowCueSize)
    if choice == "sv"
        filters = [0, lowCueSize];
    elseif choice == "si"
        filters = [1, lowCueSize];
    elseif choice == "bv"
        filters = [0, upCueSize];
    elseif choice == "bi"
        filters = [1 upCueSize];
    end
end

function get_anova_tables(results, comparison_type)
    variable_names = {'Y1', 'Y2', 'Y3', 'Y4', 'Y5', 'Y6', 'Y7', 'Y8', 'Y9', 'Y10', 'Y11', 'Y12'};
    cue_size = {'Small'; 'Small'; 'Big'; 'Big';'Small'; 'Small'; 'Big'; 'Big';'Small'; 'Small'; 'Big'; 'Big'};
    validity = {'Valid'; 'Invalid'; 'Valid'; 'Invalid'; 'Valid'; 'Invalid'; 'Valid'; 'Invalid'; 'Valid'; 'Invalid'; 'Valid'; 'Invalid'};
    ensemble_relation = {'P'; 'P'; 'P'; 'P'; 'N'; 'N'; 'N'; 'N'; 'O'; 'O'; 'O'; 'O'};
    data = [results.sp(:,1:2), results.bp(:,1:2), results.sn(:,1:2), results.bn(:,1:2), results.so(:,1:2), results.bo(:,1:2)];

    t = array2table(data, 'VariableNames', variable_names);
    within = table(categorical(cue_size), ...
                   categorical(validity), ...
                   categorical(ensemble_relation), ...
                   'VariableNames', {'CUE_SIZE', 'VALIDITY', 'ENSEMBLE'});

    % interaction factor
    within.CUE_SIZE_ENSEMBLE = within.CUE_SIZE .* within.ENSEMBLE;
    within.VALIDITY_ENSEMBLE = within.VALIDITY .* within.ENSEMBLE;

    rm = fitrm(t,'Y1-Y12~1','WithinDesign',within);
    ranova(rm, 'WithinModel', 'CUE_SIZE*VALIDITY*ENSEMBLE-1')
    multcompare(rm, 'VALIDITY', 'By', 'CUE_SIZE_ENSEMBLE',  'ComparisonType', comparison_type)
end


function [EDGES, CORRECT] = bin_by_value(scores, keys, values, nBins)
    % sort by the values
    [sortedValues, indices] = sort(values);
    sortedScores = scores(indices);
    sortedKeys = keys(indices);
    
    % bin the values and average designated by "keys    results.(string(c)) = []; 
    n = length(scores)/nBins;
    CORRECT = []; EDGES = [];
    for i = 1:n:length(scores)-1    
        bin_keys = sortedKeys(i:i+n-1);
        bin_scores = sortedScores(i:i+n-1);
        correct = [];
        for key = unique(bin_keys)
            correct = [correct mean(bin_scores(bin_keys == key))];
        end
        CORRECT = [CORRECT; correct];
        EDGES = [EDGES sortedValues(i+n-1)];
    end
end

function hBar = error_bar_plot(labels, means, sems, metric_name, plotDataType, data)
    % bar 
    
    hBar = bar(labels, means); 
    
    hold on
    er = errorbar(labels, means, sems);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';
    er.LineWidth = 1.5;
    ylabel(metric_name)
    
    % data points
    [m, n] = size(data);
    if plotDataType == "alone"
        for i = 1:m
        scatter(repmat(labels(i)+.4, 1, n),data(i,:), 25, 'black', 'filled', ...
            'MarkerFaceAlpha', .20)
        end
    elseif plotDataType == "connect"
        for i = 1:n
            p = plot(labels, data(:,i), '-k', ...
                'Marker', 'none', 'MarkerFaceColor', 'k');
            p.Color(4) = .20;
        end
    elseif plotDataType == "connect_pairs"
        for i = 1:n
            for j = 1:2:m
                p = plot(labels(j:j+1), data(j:j+1,i), '-k', ...
                    'Marker', 'none', 'MarkerFaceColor', 'k', 'LineWidth', 1);
                p.Color(4) = .20;
            end
        end 
    end
    hold off
end

function plot_perf_diff(size1, size2, results, axis_idx, perf_label, perf_lim, ...
                        diff_label, diff_lim, colors, alpha)
                    
    titles = ["Congruent", "Neutral", "Incongruent"];
    i = 1;
    for c = ["p", "n", "o"]
        c
        % Raw Scores
        data = [results.("s"+c)(:,1)'; results.("s"+c)(:,2)';
             results.("b"+c)(:,1)'; results.("b"+c)(:,2)'];
        m = mean(data, 2)

        subplot(size1,size2,axis_idx(i))
        if i == 1
            hBar = error_bar_plot([1 2 4 5], m, [], perf_label, 'connect_pairs', data);
        else
            hBar = error_bar_plot([1 2 4 5], m, [], [], 'connect_pairs', data);
        end
        hBar.FaceColor = colors(i,:);
        hBar.FaceAlpha = alpha;
        hBar.EdgeAlpha = 0;
        ylim(perf_lim)
        ti = title(titles(i));
        ti.FontWeight = 'normal';
        ax = gca;
        ax.XTickLabels = {'V', 'I', 'V', 'I'};
        set(ax,'box','off','LineWidth',1.5)
        offset = perf_lim(1) - .15*(perf_lim(2) - perf_lim(1));
        th = text([1.5 4.5], [offset offset], ["(Small)", "(Large)"], 'FontSize', 10);
        set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')

        % Differences
        cue_diff_small = -diff([results.("s"+c)(:,1)' ; results.("s"+c)(:,2)']);
        cue_diff_big = -diff([results.("b"+c)(:,1)' ; results.("b"+c)(:,2)']);

        data = [cue_diff_small; cue_diff_big];
        m = mean(data, 2)
        sem = std(data, 0, 2)/sqrt(length(data))
        
        [~, p_small, ~, stat_small] = ttest(cue_diff_small)
        [~, p_big, ~, stat_big] = ttest(cue_diff_big)
        ttp = [p_small, p_big];

        subplot(size1,size2,axis_idx(i+3))

        if i == 1
            hBar = error_bar_plot([1.5,4.5], m, sem, diff_label, 'alone', data);
        else
            hBar = error_bar_plot([1.5,4.5], m, sem, [], 'alone', data);
        end
        hBar.FaceColor = colors(i,:);
        hBar.FaceAlpha = alpha;
        hBar.EdgeAlpha = 0;
        
        pValid = ttp < .05;
        th = text(hBar.XData(pValid), m(pValid) + 3*sign(m(pValid)).*sem(pValid), '*', 'FontSize', 14);
        set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')

        ax2 = gca;
        ax2.XTick = [1.5 4.5];
        ax2.XTickLabels = {'Small', 'Large'};
        set(ax2,'box','off', 'LineWidth', 1.5, 'XLim',[ax.XLim])
        ylim(diff_lim)
        offset = diff_lim(1) - .15*(diff_lim(2) - diff_lim(1));
        if c == 'n'
            th = text([3], [offset], ["Cue size"], 'FontSize', 10);
            set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
        end
        i = i+1;
    end
end


function [d] = orientation_importance(o, r)
    d = sign(45 - abs(o-r)) .* (1 - (abs(abs(90-o) - 45) / 45));
    d = 100 * (d + 1) / 2; % renormalize to be between 0 and 100
    d = d(:, logical(1 - any(isnan(d))));
end

function y = f_line(x,m,b)
    y = m*x+b;
end
