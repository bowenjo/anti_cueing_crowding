%% load in data
utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

%% all scores
all = analyze_results(results, 'spacing', {'correct'}, {} [])
scatter(all.spacing, all.correct);


%% plot valid-long vs invalid-long
validLong = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.6, 1]);
invalidLong = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.6, 0]);

scatter(validLong.spacing, validLong.correct);
hold
scatter(invalidLong.spacing, invalidLong.correct);

%% plot valid-short vs invalid-short
validShort = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.04, 1]);
invalidShort = analyze_results(results, 'spacing', {'correct'}, ...
    {'soa_time', 'valid'}, [.04, 0]);

scatter(validShort.spacing, validShort.correct);
hold
scatter(invalidShort.spacing, invlaidShort.correct);

%% plot invalid-short vs valid-long
scatter(invalidShort.spacing, invalidShort.correct);
hold
scatter(validLong.spacing, validLong.correct);

