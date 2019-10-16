function [] = practice_check(Exp, blocks, thresh, threshIndex, threshType)
    % ---------------------------------------------------------------
    % runs part of an experiment until a certain performance is met
    % ---------------------------------------------------------------

    performanceNotMet = true;
    while performanceNotMet
        Exp.run(blocks);
        rawData = Exp.save_run('', blocks);
        processedData = analyze_results(rawData, threshType, {'correct'}, {}, [], @mean); 
        
        if mean(processedData.correct(threshIndex)) >= thresh
            performanceNotMet = false;
        end
    end

