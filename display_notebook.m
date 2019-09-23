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

results_path = [pwd '/results/9_19'];

%% Single oriented flanker
% Michael's results
G1 = load([results_path '/MS_spacing_staircase/GratingThesholdExperiment.mat']);
r1 = load([results_path '/MS_spacing_staircase/grating_threshold_results.mat']);
pFit1 = G1.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r1.results);

% Joel's results
G2 = load([results_path '/JB_spacing_staircase/GratingThesholdExperiment.mat']);
r2 = load([results_path '/JB_spacing_staircase/grating_threshold_results.mat']);
pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

x = linspace(1, 4, 100);
y1 = weibull(pFit1, x);
y2 = weibull(pFit2, x);

hold on
plot(x, y1)
plot(x, y2)
xlim([1 4]);
ylim([.5,1])
xlabel('taget-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: Single Oriented Grating");
legend('MS', 'JB', 'Location', 'southeast');
hold off

%% One vs Two flankers
% 1-flanker
G1 = load([results_path '/JB_spacing_staircase/GratingThesholdExperiment.mat']);
r1 = load([results_path '/JB_spacing_staircase/grating_threshold_results.mat']);
pFit1 = G1.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r1.results);

% 2-flanker
G2 = load([results_path '/JB_spacing_staircase_2flankers/GratingThesholdExperiment.mat']);
r2 = load([results_path '/JB_spacing_staircase_2flankers/grating_threshold_results.mat']);
pFit2 = G2.GratingExp.blocks.grating_block_1.get_size_thresh(pFitInit, r2.results);

x = linspace(1, 4, 100);
y1 = weibull(pFit1, x);
y2 = weibull(pFit2, x);

hold on
plot(x, y1)
plot(x, y2)
xlim([1 4]);
ylim([.5,1])
xlabel('taget-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: One Vs Two Oriented Gratings");
legend('1 flanker', '2 flanker', 'Location', 'southeast');
hold off

%% Plaid gratings
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

hold on
plot(x, y1)
plot(x, y2)
xlim([1 4]);
ylim([.5,1])
xlabel('taget-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: fixed vs rotating plaid");
legend('fixed plaid', 'rotated plaid', 'Location', 'southeast');
hold off

%% T's and H's
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

hold on
plot(x, y1)
plot(x, y2)
xlim([1 4]);
ylim([.5,1])
xlabel('taget-flanker spacing (DVA)');
ylabel('accuracy (percent correct)');
title("Flanker: Rotating H's and T targets");
legend('9 deg', '12 deg', 'Location', 'southeast');
hold off

%% Full experiment plots
%% all scores
all = analyze_results(results, 'spacing', {'correct'}, {}, []);
plot(all.spacing, all.correct);
hold
plot(all.spacing, repmat(all.correct(8), 1, 8))

%% plot valid-long vs invalid-long
validLong = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.6, 1]);
invalidLong = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.6, 0]);

plot(validLong.spacing, validLong.correct);
hold
plot(invalidLong.spacing, invalidLong.correct);

%% plot valid-short vs invalid-short
validShort = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.04, 1]);
invalidShort = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.04, 0]);

plot(validShort.spacing, validShort.correct);
hold
plot(invalidShort.spacing, invlaidShort.correct);

%% plot invalid-short vs valid-long
plot(invalidShort.spacing, invalidShort.correct);
hold
plot(validLong.spacing, validLong.correct);

