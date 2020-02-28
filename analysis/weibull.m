function y = weibull(p, x)
%WEIBELL a parameterized psychometric (weibull) function
    % p - struct of parameters
        % p.t - threshold value 
        % p.b - slope of the function
        % p.g - performance at chance
        % p.a - performance at threshold (y=p.a if x=p.t)
        % p.s - performance at asymptote
    % x - vector of x values
    k = (-log((p.s-p.a)/(p.s-p.g)))^(1/p.b);
    y = p.s - (p.s-p.g)*exp(- (k*x/p.t).^p.b);
end

