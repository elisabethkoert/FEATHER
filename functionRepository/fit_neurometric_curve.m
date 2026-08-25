function fit_out = fit_neurometric_curve(x, y)
% fit_neurometric_curve fits a cumulative-normal neurometric function to a
% performance measure that grows with a stimulus variable
% Used for the pairwise decoding accuracy of a linear classifier as a function
% of the distance between the two stimuli along the cochlea. The model is the
% two-alternative-forced-choice form of a cumulative normal, which starts at
% chance and saturates at 1:
%
%       y = 0.5 + 0.5 * normcdf((x - mu) / sigma)
%
% so mu is the stimulus value at which performance reaches 75 %, halfway
% between chance and perfect.
%
% input:
%   x (nx1 or 1xn double) stimulus variable, e.g. stimulus spacing in um
%   y (nx1 or 1xn double) performance at each x, as a fraction correct with
%       0.5 = chance and 1 = perfect
% output in fit_out struct:
%   mu (double) stimulus value at 75 % performance, in the unit of x
%   sigma (double) width of the curve, in the unit of x; a larger sigma means
%       performance grows more slowly with x
%   thresh75 (double) the same value as mu, kept under an explicit name
%   success (logical) false when no fit could be computed, in which case the
%       other fields stay at their NaN/empty defaults
%   yfitfun (function handle) evaluates the fitted curve at new x values,
%       empty when success is false
%
% assumptions:
%   Points where either coordinate is NaN are dropped and at least three have
%   to remain, since the model has two free parameters.
%   The parameters are found by unconstrained least squares on the squared
%   error (fminsearch), not by maximum likelihood, and sigma enters through its
%   absolute value so the sign the optimiser settles on does not matter.
%   Nothing keeps mu inside the measured range of x, so a curve that already
%   exceeds 75 % at the smallest measured x returns a mu below that value.

fit_out = struct('mu', NaN, 'sigma', NaN, 'thresh75', NaN, ...
                 'success', false, 'yfitfun', []);

x = x(:);
y = y(:);

% a pair is only usable if both coordinates were measured
valid = ~isnan(x) & ~isnan(y);
x = x(valid);
y = y(valid);

if numel(x) < 3
    return
end

psychfun = @(b, xx) 0.5 + 0.5 * normcdf((xx - b(1)) ./ abs(b(2)));
objfun = @(b) sum((y - psychfun(b, x)).^2);

% start in the middle of the measured range, with a width of the order of
% its spread; the lower bound keeps the first step away from sigma = 0
b0 = [median(x), max(std(x), 0.1)];

try
    opts = optimset('MaxFunEvals', 5000, 'MaxIter', 5000, 'Display', 'off');
    bhat = fminsearch(objfun, b0, opts);

    fit_out.mu = bhat(1);
    fit_out.sigma = abs(bhat(2));
    fit_out.thresh75 = bhat(1);
    fit_out.success = true;
    fit_out.yfitfun = @(xx) psychfun([fit_out.mu fit_out.sigma], xx);
catch
    % a failed optimisation is reported through success = false rather than
    % raising, so a caller can loop over many recordings without guarding
end
end