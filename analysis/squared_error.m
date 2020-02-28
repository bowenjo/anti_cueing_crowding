function error = squared_error(fitParams, results, fn)
%SQUARED ERROR 
% Gets the squared error between x and fn fit with params  
    % fn - function 
    % fitParams - fitted parameter struc for the function fn
    % results - struct of recorded values
        %results.x - observed x values
        %reuslts.y - observed y values
        %results.w - weights (n_x / n_total)
        % note: final element in results struct is the asymptotic regulator
    yPred = fn(fitParams, results.x);
    error = sum(results.w .* (yPred - results.y).^2);
end

