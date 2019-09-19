%% load in data
utilsPath = [pwd '/utils'];
analysisPath = [pwd '/analysis'];
addpath(utilsPath)
addpath(analysisPath)

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

