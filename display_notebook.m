%% load in data
utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

%% Plot spacing staircase results
pFitInit.t = 1.5;
pFitInit.b = 1;
pFitInit.a = 0.95;
pFitInit.g = 0.50;

%% Flanker-target relationship
results_path = [pwd '/results/9_24'];
r_same = load([results_path '/JB_spacing_constant_same_2flankers/experiment_results.mat']);
r_10 = load([results_path '/JB_spacing_constant_2flankers_large_range/experiment_results.mat']);
r_20 = load([results_path '/JB_spacing_constant_20diff_2flankers/experiment_results.mat']);

out_same = analyze_results(r_same.results, 'spacing', {'correct'}, {}, [], @mean);
out_10 = analyze_results(r_10.results, 'spacing', {'correct'}, {}, [], @mean);
out_20 = analyze_results(r_20.results, 'spacing', {'correct'}, {}, [], @mean);

figure
hold on
plot(out_10.spacing, out_10.correct, 'LineWidth', 2);
plot(out_20.spacing, out_20.correct, 'LineWidth', 2);
plot(out_same.spacing, out_same.correct, 'LineWidth', 2);
xlim([1 3]);
ylim([.5,1])
xlabel('target-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Target-flanker relationship: constant stimuli");
legend('10 deg wedge','20 deg wedge','0 deg wedge', 'Location', 'southeast');
hold off



%% Single oriented flanker
results_path = [pwd '/results/9_19'];
results_path_2 = [pwd '/results/9_23'];
% Michael's results
G1 = load([results_path '/MS_spacing_staircase/GratingThesholdExperiment.mat']);
r1 = load([results_path '/MS_spacing_staircase/grating_threshold_results.mat']);
pFit1 = G1.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r1.results);

% Joel's results
G2 = load([results_path '/JB_spacing_staircase/GratingThesholdExperiment.mat']);
r2 = load([results_path '/JB_spacing_staircase/grating_threshold_results.mat']);
pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

% Dev's results
G3 = load([results_path_2 '/DV_spacing_staircase_1flanker/GratingThesholdExperiment.mat']);
r3 = load([results_path_2 '/DV_spacing_staircase_1flanker/grating_threshold_results.mat']);
pFit3 = G3.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r3.results);

x = linspace(1, 4, 100);
y1 = weibull(pFit1, x);
y2 = weibull(pFit2, x);
y3 = weibull(pFit3, x);

figure
hold on
plot(x, y1)
plot(x, y2)
plot(x, y3)
xlim([1 4]);
ylim([.5,1])
xlabel('target-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: Single Oriented Grating");
legend('MS', 'JB','DV', 'Location', 'southeast');
hold off

%% Flanker-target rlationship staircase oriented flankers
% Joel's results
results_path = [pwd '/results/9_24'];
G1 = load([results_path '/JB_spacing_staircase_10diffall_2flanker/GratingThesholdExperiment.mat']);
r1 = load([results_path '/JB_spacing_staircase_10diffall_2flanker/grating_threshold_results.mat']);
pFit1 = G1.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r1.results);

G2 = load([results_path '/JB_spacing_staircase_20diff_2flankers/GratingThesholdExperiment.mat']);
r2 = load([results_path '/JB_spacing_staircase_20diff_2flankers/grating_threshold_results.mat']);
pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

G3 = load([results_path '/JB_spacing_staircase_same_2flankers/GratingThesholdExperiment.mat']);
r3 = load([results_path '/JB_spacing_staircase_same_2flankers/grating_threshold_results.mat']);
pFit3 = G3.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r3.results);


% Dev's results
% G2 = load([results_path_2 '/DV_spacing_staircase_2flanker/GratingThesholdExperiment.mat']);
% r2 = load([results_path_2 '/DV_spacing_staircase_2flanker/grating_threshold_results.mat']);
% pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

x = linspace(1, 4, 100);
y1 = weibull(pFit1, x);
y2 = weibull(pFit2, x);
y3 = weibull(pFit3, x);
% % 
figure
hold on
plot(x, y1)
plot(x, y2)
plot(x, y3)
xlim([1 4]);
ylim([.5,1])
xlabel('target-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Target-flanker relationship: staircase");
legend('10 diff', '20 diff', 'same', 'Location', 'southeast');
hold off




%% Plaid gratings
results_path = [pwd '/results/9_19'];
% fixed-plaid
G1 = load([results_path '/JB_spacing_staircase_hash/GratingThesholdExperiment.mat']);
r1 = load([results_path '/JB_spacing_staircase_hash/grating_threshold_results.mat']);
pFit1 = G1.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r1.results);

% random rotating plaid
G2 = load([results_path '/JB_spacing_staircase_hash_fixed/GratingThesholdExperiment.mat']);
r2 = load([results_path '/JB_spacing_staircase_hash_fixed/grating_threshold_results.mat']);
pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

x = linspace(1, 4, 100);
y1 = weibull(pFit1, x);
y2 = weibull(pFit2, x);

figure
hold on
plot(x, y1)
plot(x, y2)
xlim([1 4]);
ylim([.5,1])
xlabel('target-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: fixed vs rotating plaid");
legend('fixed plaid', 'rotated plaid', 'Location', 'southeast');
hold off

%% T's and H's
results_path = [pwd '/results/9_19'];
% 9-deg
G1 = load([results_path '/JB_spacing_staircase_rotated_t_9deg/GratingThesholdExperiment.mat']);
r1 = load([results_path '/JB_spacing_staircase_rotated_t_9deg/grating_threshold_results.mat']);
pFit1 = G1.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r1.results);

% 12-deg
G2 = load([results_path '/JB_spacing_staircase_rotated_t_12deg/GratingThesholdExperiment.mat']);
r2 = load([results_path '/JB_spacing_staircase_rotated_t_12deg/grating_threshold_results.mat']);
pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

x = linspace(1, 4, 100);
y1 = weibull(pFit1, x);
y2 = weibull(pFit2, x);

figure
hold on
plot(x, y1)
plot(x, y2)
xlim([1 4]);
ylim([.5,1])
xlabel('target-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: Rotating H's and T targets");
legend('9 deg', '12 deg', 'Location', 'southeast');
hold off

%% Full experiment plots
results_path = [pwd '/results/sub005/2/'];
r = load([results_path '/experiment_results.mat']);
results = r.results;
%% all scores
all = analyze_results(results, 'spacing', {'correct'}, {}, [], @mean);

figure
hold on
scatter(all.spacing, all.correct);
plot(all.spacing, repmat(all.correct(8), 1, 8));
% ylim([.7, 1.01]);
title('All trials');
xlabel('target-flanker spacing (DVA)');
ylabel('percent correct');
legend('all trials', 'target alone', 'Location', 'southeast')
hold off

%% plot valid-long vs invalid-long
validLong = analyze_results(results, 'spacing', {'correct', 'RT'}, ...
    {'soa_time', 'valid'}, [.6, 1], @mean);
invalidLong = analyze_results(results, 'spacing', {'correct', 'RT'}, ...
    {'soa_time', 'valid'}, [.6, 0], @mean);

figure
hold on
plot(validLong.spacing, validLong.correct);
plot(invalidLong.spacing, invalidLong.correct);
% ylim([.6, 1]);
title('Long Soa Trials');
xlabel('target-flanker spacing (DVA)');
ylabel('percent correct');
legend('valid-long', 'invalid-long', 'Location', 'southeast')
hold off
%% plot valid-short vs invalid-short
validShort = analyze_results(results, 'spacing', {'correct', 'RT'}, ...
    {'soa_time', 'valid'}, [.04, 1], @mean);
invalidShort = analyze_results(results, 'spacing', {'correct', 'RT'}, ...
    {'soa_time', 'valid'}, [.04, 0], @mean);

figure
hold on
plot(validShort.spacing, validShort.correct);
plot(invalidShort.spacing, invalidShort.correct);
% ylim([.5, 1]);
title('Short Soa Trials');
xlabel('target-flanker spacing (DVA)');
ylabel('percent correct');
legend('valid-short', 'invalid-short', 'Location', 'southeast')
hold off
%% plot invalid-short vs valid-long
figure
hold on
plot(validLong.spacing, validLong.correct);
plot(invalidShort.spacing, invalidShort.correct);
% ylim([.7, 1]);
title('Cue vs Anti-cue Trials');
xlabel('target-flanker spacing (DVA)');
ylabel('percent correct');
legend('valid-long', 'invalid-short', 'Location', 'southeast')
hold off

%% all
figure
hold on
plot(validLong.spacing, validLong.correct);
plot(invalidLong.spacing, invalidLong.correct);
plot(validShort.spacing, validShort.correct);
plot(invalidShort.spacing, invalidShort.correct);
% ylim([.6, 1]);
title('Cue vs Anti-cue Trials');
xlabel('target-flanker spacing (DVA)');
ylabel('percent correct');
legend('valid-long', 'invalid-long', 'valid-short','invalid-short', 'Location', 'southeast')
hold off

%% all RT
figure
hold on
plot(validLong.spacing, validLong.RT);
plot(invalidLong.spacing, invalidLong.RT);
plot(validShort.spacing, validShort.RT);
plot(invalidShort.spacing, invalidShort.RT);
% ylim([.6, 1]);
title('Cue vs Anti-cue Trials');
xlabel('target-flanker spacing (DVA)');
ylabel('Reaction Time');
legend('valid-long', 'invalid-long', 'valid-short','invalid-short', 'Location', 'northeast')
hold off
