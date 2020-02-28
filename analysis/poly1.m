function y = poly1(p, x)
    %poly1 Parametrized line function 
    %    p - struct of parameters
    %        p.m = slope
    %        p.b = y-intercept
    %    x - vector of x-values
    y = (p.m .* x) + p.b;
end

