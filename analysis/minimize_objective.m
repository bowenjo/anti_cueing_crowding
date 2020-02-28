function paramsFit = minimize_objective(variables, A, b, objective_fn, ...
    paramsInit, results, fn)
    % finds optimal variables to minimize objective_fn
        % variables - cell array - variables to find optimal solution
        % objective_fn - function to minimize
        % paramsInit - struct - initial parameter values
    
    % format the variables into a vector
    x0 = [];
    for k = 1:length(variables)
        x0 = [x0 paramsInit.(string(variables(k)))];
    end
    
    % fit the params
    paramsFit = paramsInit;
    fitValues = fmincon(@construct_fn, x0, A, b);
    set_params(fitValues)
    
    function y = construct_fn(x)
        % function for formating the objective_fn to work with fminsearch
        set_params(x)
        y = objective_fn(paramsFit, results, fn); 
    end

    function set_params(values)
        % sets the values from a vector in a struct
        for i = 1:length(values)
            paramsFit.(string(variables(i))) = values(i);
        end
    end

end

    