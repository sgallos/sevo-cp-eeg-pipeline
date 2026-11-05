function q = benjamini_hochberg(p)
%BENJAMINI_HOCHBERG False discovery rate adjusted p-values (q-values), Benjamini & Hochberg (1995).
%   q = BENJAMINI_HOCHBERG(p). Sort the m p-values, p_(1) <= ... <= p_(m); each becomes
%   p_(k) * m / k, then each q is the smallest of these at its rank or above, capped at 1.
%   Calling every test with q < 0.05 a discovery keeps the expected share of false
%   discoveries among them at or below 5%. NaN p-values are left as NaN.
    q = nan(size(p));
    ok = ~isnan(p);
    [sorted, order] = sort(p(ok));
    m = numel(sorted);
    adjusted = sorted(:) .* m ./ (1:m)';
    adjusted = min(1, flipud(cummin(flipud(adjusted))));
    values = zeros(m, 1);
    values(order) = adjusted;
    q(ok) = values;
end
