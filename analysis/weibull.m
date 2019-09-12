function y = weibull(p, x)
%WEIBELL a parameterized psychometric (weibull) function
    % p - struct of parameters
        % p.t - threshold value 
        % p.b - slope of the function
        % p.g - performance at chance
        % p.a - performance at threshold (y=p.a if x=p.t)
    % x - vector of x values
    k = (-log((1-p.a)/(1-p.g)))^(1/p.b);
    y = 1 - (1-p.g)*exp(- (k*x/p.t).^p.b);
end

