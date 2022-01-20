function errorTotal = squared_error_reg(fitParams, results, fn)
%SQUARED ERROR 
% Gets the squared error between x and fn fit with params  
    % fn - function 
    % fitParams - fitted parameter struc for the function fn
    % results - struc of recorded values
        %results.x - observed x values
        %reuslts.y - observed y values
        %results.w - weights (n_x / n_total)
    yPred = fn(fitParams, results.x);
    error = sum(results.w .* (yPred - results.y).^2);
    reg = results.alone(2) .* (fitParams.s - results.alone(1)).^2;
    errorTotal = error + reg;
end

