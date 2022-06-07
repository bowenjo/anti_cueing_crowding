%% Set the paths
utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

%% Pick Subjects and Sessions
sessionNums = {'1','2','3','4'};


subKeys = {'sub001','sub002','sub003', 'sub005', 'sub006', 'sub007', ...
      'sub008', 'sub009', 'sub011', 'sub012', 'sub015', 'sub016', ...
      'sub019', 'sub020', 'sub021', 'sub022', 'sub023', 'sub024', ...
      'sub025', 'sub026', 'sub027'};


%  
%  subKeys = {'sub004','sub010', 'sub013', 'sub0017'}

%%
% ind = 1:60;
% offset = 0;
% trial_indices = [];
% for i = 1:8
%     trial_indices = [trial_indices ind + offset];
%     offset = offset + 120;
% end


%% Load in the results
diameters = [];
results = struct;
for key = subKeys
    subCount = 1;
    subResults = struct;
    % get the radius of the grating
    exp = load(['results/' char(key) '/1/Experiment.mat']);
    radius = exp.Exp.blocks.block_1.diameter / 2;
    diameters = [diameters exp.Exp.blocks.block_1.diameter];

    for session = sessionNums
        sessDir = ['results/' char(key) '/' char(session)];
        if exist(sessDir, 'dir')
            sessResults = load([sessDir '/experiment_results.mat']);
            sessResults = sessResults.results ;
            
            % make the spacing center-to-center
            sessResults.spacing = sessResults.spacing + radius;

            for field = fields(sessResults)'  
                r = sessResults.(string(field));
%                 r = r(2:2:960);
                if subCount == 1
                    subResults.(string(field)) = r;
                else
                    subResults.(string(field)) = [subResults.(string(field)) ...
                        r];
                end    
            end
            subCount = subCount + 1;
        end
    end
    results.(string(key)) = subResults;
end

%% Fit Accuracy Psychometric Curves
% initial parameters
pInit = struct;
pInit.g = 0.50; % performance at chance
pInit.b = 1.5; % slope of psychometric curve
pInit.s = .90; % asymptote
pInit.a = 0.78;

% experiment conditions
conditions = {'valid_short', 'invalid_short', 'valid_long', 'invalid_long'};
% variables to fit
variables = {'t','b', 's'};
% constraints on the variables
A = [0 0 1]; % constrain the asymptote to be <= 1
b = [1]; 

FitData = fit_accuracy(results, subKeys, conditions, pInit, variables, A, b);

%% Fit Reaction Time 
% initial parameters
pInit = struct;
pInit.m = -1;
pInit.b = .8;

% experiment conditions
conditions = {'valid_short', 'invalid_short', 'valid_long', 'invalid_long'};
% variables to fit
variables = {'m','b'};
%constraints on the variables
A = [];
b = [];

FitDataRT = fit_rt(results, subKeys, conditions, pInit, variables, A, b);


%% Calculate grouped data
groupResults = struct;
groupResults.conditions = conditions;

groupResultFields = {'r2_acc', 'r2_rt', 'n_mt', 'lapse', 'ta_acc', 'ta_rt',...
  'infl_perf','cs_perf', 'rt_perf', 'rt_total'};

% set the result matrices
for field = groupResultFields
    groupResults.(string(field)) = nan(length(conditions), length(subKeys));
end

for cond_i = 1:length(conditions)
    for key_i = 1:length(subKeys)
        % get the data for the subject and condition
        DataCS = FitData.(string(subKeys(key_i))).(string(conditions(cond_i)));
        DataRT = FitDataRT.(string(subKeys(key_i))).(string(conditions(cond_i)));
        
        % r squared (quality of fit)
        y = DataCS.data.y;
        y_pred = weibull(DataCS.fit, DataCS.data.x); 
        groupResults.r2_acc(cond_i, key_i) = r_squared(y, y_pred);
        y = DataRT.data.y;
        y_pred = poly1(DataRT.fit, DataRT.data.x);
        groupResults.r2_rt(cond_i, key_i) = r_squared(y, y_pred);
 
        % Missed trials
        groupResults.n_mt(cond_i, key_i) = 1 - DataCS.count;
        
        % Lapse 
        groupResults.lapse(cond_i, key_i) = 1 - DataCS.fit.s;
        
        % Target Alone Accuracy/RT
        groupResults.ta_acc(cond_i, key_i) = 1 - DataCS.data.alone(1);
        groupResults.ta_rt(cond_i, key_i) = 1000*DataRT.data.alone(1);
        
        % Inflection Performance
        infl_pt = get_inflection_pt(FitData.(string(subKeys(key_i))).total.fit);
        critical_performance = weibull(FitData.(string(subKeys(key_i))).total.fit, infl_pt);
        groupResults.infl(cond_i, key_i) = critical_performance;
        
        
        % CS/RT ------------------------------------------
        
        % Crtical spacing at designated performance  
        groupResults.cs_perf(cond_i, key_i) = DataCS.fit.t;
        
        % RT at critical spacing per condition
        critical_spacing = DataCS.fit.t;
        groupResults.rt_perf(cond_i, key_i) = 1000*poly1(DataRT.fit, critical_spacing);
        
        % RT at critical spacing all conditions combined
        critical_spacing = FitData.(string(subKeys(key_i))).total.fit.t;
        groupResults.rt_total(cond_i, key_i) = 1000*poly1(DataRT.fit, critical_spacing);
    end
end

% save('results/split_half/even_trials.mat', 'groupResults')

%% Visualize Individual Subject Accuracy/RT Results
close all
colors = {'green', 'black', 'blue', 'red'};
for key = subKeys
    close all
    figure('Position', [10 10 1500 600])
    % Accuracy
    subplot(1,2,1)
    raw_fit_data_plot(key, conditions, FitData, @weibull, ...
        'Accuracy (percent correct)', [.5,1], string(key), ...
        {'Opp. Short', 'Cue Short', 'Opp. Long', 'Cue Long'}, ...
        'southwest', colors)
    % Reaction Time
    subplot(1,2,2)
    raw_fit_data_plot(key, conditions, FitDataRT, @poly1, ...
        'Response Time (secs)', [], '', ...
        {'Opp. Short', 'Cue Short', 'Opp. Long', 'Cue Long'}, ...
        'northeast', colors)
     saveas(gcf, "figures/idv/"+string(key)+".png")
end

%%
% Swarm Plots with mean and SEM error bars
% 2x1 subplots for RT, CS, Lapse
% 1) All four conditions 2) Differences
close all
rSquaredMin = 0;

titles = {'Response Time', 'Critical Spacing'};
result_fields = {'rt_total', 'cs_perf'};
labels = {'Response Time (msec)', 'Critical Spacing (degrees)'};
diff_labels = {'RT (Cue) - RT (Opp.)', 'CS (Cue) - CS (Opp.)'};
y_ranges = [360, 650; 1.4, 4.5];
offsets = [.12, .20];
colors = [.35, .45, .95; .85, .45, 0];
alpha = .5;

figure('Position', [10 10 800 650]);

for i = 1:length(result_fields)
    [data, data_diff, m, s, dm, ds, ttp] = get_grouped_data(result_fields(i), groupResults,...
        {}, [], {});

    subplot(2,2,i)
    hBar = error_bar_plot([1 2 4 5], m, [], labels(i), 'connect_pairs', data);
    hBar.FaceColor = colors(i,:);
    hBar.FaceAlpha = alpha;
    hBar.EdgeAlpha = 0;

    ax = gca;
    ax.XTickLabels = {'Opp.'; 'Cue'; 'Opp.'; 'Cue'};
    
    % set up axis labels
    yRange = y_ranges(i,:);
    th = text([1 2 4 5], repmat(yRange(1) - offsets(1)*diff(yRange), 1, 4), ["(80%)", "(20%)", "(80%)", "(20%)"]);
    set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
    set(ax,'box','off')

    th = text([1.5 4.5], repmat(yRange(1) - offsets(2)*diff(yRange), 1, 2), ["SOA = 40 ms", "SOA = 600 ms"]);
    set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
    
    ylim(yRange)
    ti = title(titles(i))
    ti.FontWeight = 'normal'

    subplot(2,2,i+length(result_fields))
    hBar = error_bar_plot([1.5,4.5], dm, ds, diff_labels(i), 'alone', data_diff);
    hBar.FaceColor = colors(i,:);
    hBar.FaceAlpha = alpha;
    hBar.EdgeAlpha = 0;
    hBar.BarWidth = .6;
    ax2=gca;
    ax2.XTick = [1.5 4.5];
    ax2.XTickLabels = {'40 ms'; '600 ms'};
    xlabel('SOA')
    set(ax2,'box','off')
    set(ax2,'XLim',[ax.XLim])

    pValid = ttp < .05;
    th = text(hBar.XData(pValid), dm(pValid) + 3*sign(dm(pValid)).*ds(pValid), '*', 'FontSize', 14);
    set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
    
    % repeated measures anova
    t = array2table(data', 'VariableNames',  {'Y1', 'Y2', 'Y3', 'Y4'});
    within = table(categorical({'Opp'; 'Cue'; 'Opp'; 'Cue'}), categorical({'Short'; 'Short'; 'Long'; 'Long'}), ...
        'VariableNames', {'LOC', 'SOA'});
    
    
    rm = fitrm(t,'Y1-Y4~1','WithinDesign',within);
    
    % print the stats
    result_fields(i)
    m
    s
    dm
    ds
    ttp
    ranova(rm, 'WithinModel', 'SOA*LOC-1')
    multcompare(rm, 'LOC', 'By', 'SOA', 'ComparisonType', 'bonferroni')

end

print(gcf,'figures/grp/cs_rt_error_bar.eps','-depsc','-r300')


%% Correlate Within Subject Differences 
close all
fieldNames = {'rt_total', 'cs_perf'};
labels1 = {'RT(Cue) - RT(Opp.)', 'CS(Cue) - CS(Opp.)'};
labels2 = {'Short SOA', 'Long SOA'};
colors = [0 0 0; 0 0 0; .35, .45, .95; .85, .45, 0 ];
titles = {'Involuntary Attention', 'Voluntary Attention', 'Response Time', 'Critical Spacing'};

n = length(subKeys);

figure('Position', [10 10 950 400])

% get the data
r1 = groupResults.(string(fieldNames(1)));
d1 = [r1(2,:) - r1(1,:);
      r1(4,:) - r1(3,:)];
r2 = groupResults.(string(fieldNames(2)));
d2 = [r2(2,:) - r2(1,:);
      r2(4,:) - r2(3,:)];

% fit the data
% short SOA
data = struct;
data.short.x = d1(1,:); data.short.y = d2(1,:); 
% long SOA
data.long.x = d1(2,:); data.long.y = d2(2,:); 
% rt
data.rt.x = d1(1,:); data.rt.y = d1(2,:); 
% cs
data.cs.x = d2(1,:); data.cs.y = d2(2,:); 

% initialize
pInit.m = 1;
pInit.b = 0;

keys = fields(data)';

i = 3;
for f = keys(3:4)
    dataField = data.(string(f));
    % regress
    mdl = fitlm(dataField.x', dataField.y');
        
    % get correlation coeff
    [r, pVal] = corrcoef(dataField.x', dataField.y', 'alpha', .05);
    
    subplot(1,2,i-2)
    hold on
        p = plot(mdl);
        % Line/Color Parameters
        p(1).Color = colors(i,:);
        p(1).LineWidth = 1.25;
        % Regression Line
        p(2).Color = colors(i,:);
        p(2).LineWidth = 1.5;
        % Confidence Intervals
        p(3).Color = colors(i,:);
        p(3).LineWidth = 1.25;
        p(4).Color = colors(i,:);
        p(4).LineWidth = 1.25;
        
        % labels
        if i == 1
            xlabel({string(labels1(1)); string(labels2(1))}, 'Color', colors(3,:))
            ylabel({string(labels2(1)); string(labels1(2))}, 'Color', colors(4,:))
            xRangeLabels = ["enhances","impairs"];
            yRangeLabels = ["enhances","impairs"];
        elseif i == 2
            xlabel({string(labels1(1)); string(labels2(2))}, 'Color', colors(3,:))
            ylabel({string(labels2(2)); string(labels1(2))}, 'Color', colors(4,:))
            xRangeLabels = ["impairs", "enhances"];
            yRangeLabels = ["impairs", "enhances"];
        elseif i == 3
            xlabel({string(labels1(1)); string(labels2(1))})
            ylabel({string(labels2(2)); string(labels1(1))})
            xRangeLabels = ["enhances", "impairs"];
            yRangeLabels = ["impairs", "enhances"];
        elseif i == 4
            xlabel({string(labels1(2)); string(labels2(1))})
            ylabel({string(labels2(2)); string(labels1(2))})
            xRangeLabels = ["enhances", "impairs"];
            yRangeLabels = ["impairs", "enhances"];
        end
        
        yrange = ylim();
        xrange = xlim();
        % x-range labels
        th = text(xrange, repmat(yrange(1) - .12*diff(yrange), 1, 2), xRangeLabels);
        th2 = text(xrange, repmat(yrange(1) - .08*diff(yrange), 1, 2), ["attention", 'attention']);
        set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')
        set(th2,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle')

        % y-range labels
        th = text(repmat(xrange(1) - .12*diff(xrange), 1, 2), yrange, yRangeLabels);
        th2 = text(repmat(xrange(1) - .16*diff(xrange), 1, 2), yrange, ["attention", "attention"]);
        set(th,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle', 'Rotation', 90)
        set(th2,'visible','on','HorizontalAlignment','center','VerticalAlignment','middle', 'Rotation', 90)
        
        % legend
        dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
        legend(dummyh, compose('r = %4.3f; p = %4.3f', [r(2), pVal(2)]), 'Location', 'northeast')
        legend boxoff
        ti = title(string(titles(i)));
        ti.FontWeight = 'normal';
        
    hold off
    i = i+1;
end
saveas(gcf, "figures/idv/corr_plots_endoVexo", 'epsc')

%% 
% Split-half Analysis
close all
fieldNames = {'rt_total', 'cs_perf'};
labels1 = {'Odd Trials', 'Even Trials'}; 
labels2 = {'RT(Cue) - RT(Opp.)', 'CS(Cue) - CS(Opp.)'};
titles = {'Short SOA', 'Long SOA'};

colors = [.35, .45, .95; .35, .45, .95; .85, .45, 0 ; .85, .45, 0];

% load in halves
h1 = load('results/split_half/odd_trials.mat');
h1 = h1.groupResults;
h2 = load('results/split_half/even_trials.mat');
h2 = h2.groupResults;

f1 = any(filter_by_index(h1, {'r2_acc'}, [0], {'lt'}), 1);
f2 = any(filter_by_index(h1, {'r2_acc'}, [0], {'lt'}), 1);
fi = logical(1 - (f1 .* f2));

figure('Position', [10 10 1000 900])

i = 1;
for f = fieldNames % metrics
    % calculate difference scores
    r1 = h1.(string(f));
%     r1 = r1(:, fi);
    % first half differences
    x = [r1(2,:) - r1(1,:);
         r1(4,:) - r1(3,:)];
    r2 = h2.(string(f));
%     r2 = r2(:, fi);
    % second half differences
    y = [r2(2,:) - r2(1,:) ;
         r2(4,:) - r2(3,:)];
    
    for c = 1:2 % short and long SOAs
        % regress
        mdl = fitlm(x(c,:), y(c,:));
        % get correlation coeff
        [r, pVal] = corrcoef(x(c,:), y(c,:), 'alpha', .05);
        
        subplot(2,2,i)
        hold on
            p = plot(mdl);
            % Line/Color Parameters
            p(1).Color = colors(i,:);
            p(1).LineWidth = 1.25;
            % Regression Line
            p(2).Color = colors(i,:);
            p(2).LineWidth = 1.5;
            % Confidence Intervals
            p(3).Color = colors(i,:);
            p(3).LineWidth = 1.25;
            p(4).Color = colors(i,:);
            p(4).LineWidth = 1.25;
            
            title(string(titles(c)))
            % First Metric
            if i == 1 || i==2
                xlabel({string(labels1(1)); string(labels2(1))})
                ylabel({string(labels1(2)); string(labels2(1))})
            % Second Metric
            else
                xlabel({string(labels1(1)); string(labels2(2))})
                ylabel({string(labels1(2)); string(labels2(2))})
            end
            
            % Legend
            dummyh = line(nan, nan, 'Linestyle', 'none', 'Marker', 'none', 'Color', 'none');
            legend(dummyh, compose('r = %4.3f; p = %4.3f', [r(2), pVal(2)]), 'Location', 'northeast')
            legend boxoff
        hold off
            
        i = i+1;
    end
end

%% Response Time over a range of performances

groupResults = struct;
performances = .6:.1:.90;

for i = length(performances)
    groupResults.("perf_"+string(i)) = nan(length(conditions), length(subKeys));
end
groupResults.lapse = nan(length(conditions), length(subKeys));
groupResults.alone = nan(length(conditions), length(subKeys));

for cond_i = 1:length(conditions)
    for key_i = 1:length(subKeys)
        DataCS = FitData.(string(subKeys(key_i))).(string(conditions(cond_i)));
        DataRT = FitDataRT.(string(subKeys(key_i))).(string(conditions(cond_i)));
        for i = 1:length(performances)
            x = linspace(0,max(DataCS.data.x)+5,1000);
            y = weibull(DataCS.fit,x);
            p = performances(i);
            [~, c] = min(abs(y-p));
            groupResults.("perf_"+string(i))(cond_i, key_i) = poly1(DataRT.fit, x(c));
        end
            
        groupResults.alone(cond_i, key_i) = DataRT.data.alone(1);
        groupResults.lapse(cond_i, key_i) = 1 - DataCS.fit.s;
        
    end
end

close all
labels = {'Long (600ms)', 'Short (40ms)'};
xLabel = {'condition'}; %'SOA';
legendTitle = 'Point Type';

figure
rt_fields = {'perf_1', 'perf_2', 'perf_3', 'perf_4', 'alone'};
yLabel = 'RT(same) - RT(opp.)';
legendLabels = {'60%'; '70%'; '80%'; '90%'; 'Alone'};

[~, ~, dm, ds] = get_grouped_data(rt_fields, groupResults,...
    {'lapse'}, [1], {'gt'});
grouped_error_bar_plot(labels, dm, ds, xLabel, yLabel, ...
     legendLabels, legendTitle)
saveas(gcf, "figures/rt_multi_perf_correct.png");



%% Bootstrap sample RTs

nSamples = [24:24:192];
numIters = 1000;

testSamples = [];
for s = nSamples
    testResults=[];
    for i = 1:numIters
        r = [];
        for key = subKeys
            subData = Data.(string(key));
            % 600ms
            vl=median(datasample(subData.valid_long,s));
            il=median(datasample(subData.invalid_long,s));
            % 40ms
            vs=median(datasample(subData.valid_short, s));
            is=median(datasample(subData.invalid_short,s));
            
            % 600ms
%             vl=median(datasample(subData.valid_long, ...
%                 min(s,length(subData.valid_long)), 'Replace',false));
%             il=median(datasample(subData.invalid_long, ...
%                 min(s,length(subData.invalid_long)),'Replace',false));
%             % 40ms
%             vs=median(datasample(subData.valid_short, ...
%                 min(s,length(subData.valid_short)),'Replace',false));
%             is=median(datasample(subData.invalid_short, ...
%                 min(s,length(subData.invalid_short)), 'Replace',false));
            r = [r [vl; il; vs; is]];
        end
        [hl,pl] = ttest(r(2,:), r(1,:));
        [hs,ps] = ttest(r(4,:), r(3,:));
        testResults = [testResults [hl;hs]];

    end

    testSamples = [testSamples mean(testResults,2)];
end

figure
plot(nSamples, testSamples, 'LineWidth', 2)
ylabel({'Proportion of null hypothesis rejected'; '[pValue < .05; 100 iterations]'});
xlabel("Trials used");
hleg = legend({'600ms','40ms'}, 'Location', "southeast");
title(hleg, "SOA")
title("Sample Without Replacement");

saveas(gcf, "figures/target_alone_analysis_replacement.png");


%% Functions
% =================================================================================

% Analysis Functions
function FitData = fit_accuracy(results, subKeys, conditions, pInit, variables, A, b)
    FitData = struct;
    for key = subKeys
        subResults = results.(string(key));
        FitData.(string(key)) = struct;
        % Get the overall critical point for all conditions
        totalAcc = analyze_results(subResults, 'spacing', {'correct'}, {'post_fix_check'}, [0], ...
            {'gt'}, @mean);
        totalCount = analyze_results(subResults, 'spacing', {'correct'}, {'post_fix_check'}, [0], ...
            {'gt'}, @length);
        psychDataTotal = get_data(totalAcc, totalCount, "correct");
        pInit.t = (max(psychDataTotal.x) - min(psychDataTotal.x)) / 2;
%         pInit.t = max(psychDataTotal.x);
        pFitTotal = minimize_objective(variables, A, b, @squared_error_reg,...
            pInit, psychDataTotal, @weibull);
        FitData.(string(key)).total.data = psychDataTotal;
        FitData.(string(key)).total.fit = pFitTotal;

        for condition = conditions
            % get the filters for the conditon
            filters = get_condition_filters(string(condition));
            % get accuracy and count
            conditionAcc = analyze_results(subResults, 'spacing', {'correct'}, ...
                {'soa_time', 'valid', 'post_fix_check'}, filters, {'eq', 'eq', 'gt'}, @mean);
            conditionCount = analyze_results(subResults, 'spacing', {'correct'}, ...
                {'soa_time', 'valid', 'post_fix_check'}, filters, {'eq', 'eq', 'gt'}, @length);
            psychData = get_data(conditionAcc, conditionCount, "correct");
            pInit.t = (max(psychData.x) - min(psychData.x)) / 2;
            pFit = minimize_objective(variables, A, b, @squared_error_reg,...
                pInit, psychData, @weibull);
            FitData.(string(key)).(string(condition)).data = psychData;
            FitData.(string(key)).(string(condition)).fit = pFit;
            
            conditionCountAll = analyze_results(subResults, 'spacing', {'correct'}, ...
                {'soa_time', 'valid'}, filters, {'eq', 'eq'}, @length);
            FitData.(string(key)).(string(condition)).count = (sum(conditionCount.correct)./sum(conditionCountAll.correct));
        end
    end
end

function FitDataRT = fit_rt(results, subKeys, conditions, pInit, variables, A, b)
    FitDataRT = struct;
    for key = subKeys
        subResults = results.(string(key));
        FitDataRT.(string(key)) = struct;
        for condition = conditions
            % get the filters for the conditon
            filters = get_condition_filters(string(condition));
            filters = [filters 1];
            % get accuracy and count
            conditionRT = analyze_results(subResults, 'spacing', {'RT'}, ...
                {'soa_time', 'valid', 'post_fix_check', 'correct'}, filters, ...
                {'eq', 'eq', 'gt', 'eq'}, @median);
            conditionCount = analyze_results(subResults, 'spacing', {'RT'}, ...
                {'soa_time', 'valid', 'post_fix_check', 'correct'}, filters, ...
                {'eq', 'eq', 'gt', 'eq'}, @length);
            % make the psychometric function data structure
            psychData = get_data(conditionRT, conditionCount, "RT");
            % fit the data
            pFit = minimize_objective(variables, A, b, @squared_error,...
                pInit, psychData, @poly1);
            FitDataRT.(string(key)).(string(condition)).data = psychData;
            FitDataRT.(string(key)).(string(condition)).fit = pFit;
        end
    end
end

function psychData = get_data(scores, count, field)
    % make the psychometric function data structure
    totalTrials = sum(count.(field)(1:8));
    psychData = struct;
    psychData.x = scores.spacing(1:7); % x-values
    psychData.y = scores.(field)(1:7); % y-values
    psychData.w = count.(field)(1:7) ./ totalTrials;
    psychData.alone = [scores.(field)(8), count.(field)(8)./totalTrials];
end

function pt = get_inflection_pt(pFit)
    % get the steepest part of the curve
    syms w(x)
    w(x) = weibull(pFit, x);
    dw = diff(w,x);
    
    input = linspace(.01,10,1000);
    output = dw(input);
    [~, i] = max(output);
    pt = input(i);
end

% Helper functions
function filters = get_condition_filters(condition)
    if condition == "valid_long"
        filters = [.6, 1, 0];
    elseif condition == "invalid_long"
        filters = [.6, 0, 0];
    elseif condition == "valid_short"
        filters = [.04, 1, 0];
    elseif condition == "invalid_short"
        filters = [.04, 0, 0];
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
        scatter(repmat(labels(i)+.3, 1, n),data(i,:), 25, 'black', 'filled', ...
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
                    'Marker', 'none', 'MarkerFaceColor', 'k', 'LineWidth', 1.5);
                p.Color(4) = .20;
            end
        end 
    end
    hold off
end

function grouped_error_bar_plot(labels, means, sems, xLabel, yLabel, ...
    legendLabels, legendTitle, plotTitle)
    hBar = bar(1:length(labels), means');
    hAx=gca;                       % handle to the axes object
    hAx.XTickLabel=labels(1:length(labels));  % label by categories
    hold on
    X=cell2mat(get(hBar,'XData')).'+ [hBar.XOffset];  % compute bar locations
    hEB = errorbar(X, means',sems','.');  % add the errorbar
    for i=1:length(hEB)            
        hEB(i).Color='k';
    end
    xlabel(xLabel)
    ylabel(yLabel)
    hleg = legend(legendLabels, 'Location', 'southeast');
    title(hleg, legendTitle)
    title(plotTitle)
end

function raw_fit_data_plot(key, conditions, FitData, fn, yLabel, ...
    yLim, Title, legendLabels, location, colors)
    hold on
    color_cnt = 1;
    plots = [];
    for condition = conditions
        Data = FitData.(string(key)).(string(condition));
        x = linspace(0,max(Data.data.x),100);
        % plot linear function
        y = fn(Data.fit,x);
        p = plot(x, y, 'DisplayName', string(condition), 'Color',...
            char(colors(color_cnt)), 'LineWidth', 1.5);
        plots = [plots p];
        % plot the raw data
        scatter(Data.data.x, Data.data.y, 30, 'MarkerEdgeColor',...
        char(colors(color_cnt)), 'Marker', 's', 'MarkerFaceColor', ...
        char(colors(color_cnt)), 'MarkerFaceAlpha',.3,'MarkerEdgeAlpha',.3); 
        % plot target alone 
        scatter(max(Data.data.x), Data.data.alone(1), 30, 'MarkerEdgeColor',...
        char(colors(color_cnt)), 'Marker', '*', 'MarkerFaceColor', ...
        char(colors(color_cnt)));
        color_cnt = color_cnt + 1;
    end
    xlim([0,max(x)]);
    if ~isempty(yLim)
        ylim(yLim);
    end
    xlabel('Target-Flanker Spacing (DVA)');
    ylabel(yLabel);
    title(Title);
    legend(plots, legendLabels, 'Location', location)
    hold off
end

function [r, diff, means_fields, sems_fields, diff_means_fields, diff_sems_fields, ttest_fields] = get_grouped_data(fields, ...
    results, filterFields, filterMins, filterOperators)
    % initialize the fields
    means_fields = [];
    sems_fields = [];
    diff_means_fields =[];
    diff_sems_fields = [];
    ttest_fields = [];
    
    
    for field = fields
        r = results.(string(field));
        if ~isempty(filterFields)
            filters = filter_indices(results, filterFields, filterMins, filterOperators);
            r = r(:,filters);
        end
        
        % group means
        means = mean(r, 2)'; 
        sems = std(r,0,2)'./ sqrt(length(r));
        
        % group mean difference scores
        diff = [(r(2,:) - r(1,:));
                (r(4,:) - r(3,:))];

        diff_means = mean(diff,2)';
        diff_sems = std(diff,0,2)'./ sqrt(length(r));
        
        % ttest
        [~, ps, ~, stats] = ttest(r(2,:) - r(1,:));
        [~, pl, ~, statl] = ttest(r(4,:) - r(3,:));
        
        stats
        statl
        
        % append the data for each field
        means_fields = [means_fields; means];
        sems_fields = [sems_fields; sems];
        diff_means_fields = [diff_means_fields; diff_means];
        diff_sems_fields = [diff_sems_fields; diff_sems];
        ttest_fields = [ttest_fields; [ps pl]];
    end
end

function filters = filter_indices(results, filterFields, filterMins, filterOperators)
    for i = 1: length(filterFields)
        field = filterFields(i);
        value = filterMins(i);
        operator = filterOperators(i);
        filter = ~any(feval(string(operator), results.(string(field)), value), 1);
        if i == 1
            filters = logical(filter);
        else
            filters = logical(filter .* filters);
        end    
    end
end
function r2 = r_squared(y, y_pred)
    res = sum((y - y_pred).^2);
    total = sum((y - mean(y)).^2);
    r2 = 1 - (res/total);
    
end

