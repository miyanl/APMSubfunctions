function [res] = do_pfit3(data, nint, co, plotdata, Limits)
% takes data in the following formatted table structure:
%
% 	stimulus value	proportion		total
% 	stimulus value	proportion		total.. etc
%
% and fits a psychometric function; also plots it and returns slope, 
% threshold, error and a handle to the graph.
% 17/04/2012 - received from AJL as do_pfit2.m, name changed to do_pfit3.m
% 14/06/2012 - Parameter limits functionality added (APM)
%

% first things first
if nargin<1, error('No data!'); end

% turn warnings off
warning off;

% specify parameters for psignifit

runs = 1999;                        % number of bootstraps
cuts = [0.16 0.5 0.84];           	% which cut do we use? (50%)
shape = 'cumulative Gaussian';      % shape of the fitted function

% plot the psychophysical data
if plotdata == 1
    res.handle.pd = plotpd(data, 'Color', char(co)); 
end
hold on; 

% Make a batch string out of the preferences: 999 bootstrap replications
% assuming 2AFC design. All other options standard.
% Type "help psych_options" for a list of options that can be specified for
% psignifit.mex. Type "help batch_strings" for an explanation of the format.

if exist('Limits')
    if isempty(Limits.gamma)
        prefs = batch('shape', shape, 'n_intervals', nint, ...
            'runs', runs, 'cuts', cuts, 'sens', 0);
    elseif ~isempty(Limits.gamma)
        prefs = batch('shape', shape, 'n_intervals', nint, ...
            'gamma_limits', Limits.gamma, 'lambda_limits', Limits.lambda, 'alpha_limits', Limits.alpha, ...  % Apply strict limits to these parameters
            'runs', runs, 'cuts', cuts, 'sens', 0);
    end
else
     prefs = batch('shape', shape, 'n_intervals', nint, ...
            'runs', runs, 'cuts', cuts, 'sens', 0);
end
    
% prefs = batch('shape', shape, 'n_intervals', nint, ...
%     'gamma_prior' -gaussian, 0.5, 0.001, 'lambda_prior' -gaussian,  0.09, 0.001, ...    % Apply prior distributions to these parameters
%     'alpha_prior' -gaussian, 0, 0.001, ...
%     'runs', runs, 'cuts', cuts, 'sens', 0);

    
% Fit the data, according to the preferences we specified (999 bootstraps).
% The specified output preferences will mean that two structures, called
% 'pa' (for parameters) and 'th' (for thresholds) are created.
% [EST_P OBS_S SIM_P LDOT] = psignifit(data, [prefs outputPrefs]);
[s, sFull, str] = PFIT(data, [prefs]);

% plot the psychometric function associated with these data
res.handle.pf = plotpf(shape, s.params.est, 'Color', char(co));

% just an extra little thingy

% confidence limits for -2, -1 and 1, 2 standard deviations (BCa)
% limsBCa = confint('BCa', sFull.params.sim, [0.023 0.159 0.841 0.977], sFull.params.est, sFull.params.lff, sFull.ldot)
res.t = ajl_CI(confint('percentile', ...
    sFull.params.sim(:,1), ...
    [0.023 0.159 0.5 0.841 0.977]));

% get the confidence intervals for the standard deviation
res.s = ajl_CI(confint('percentile', ...
    abs(sFull.params.sim(:,2)), ...
    [0.023 0.159 0.5 0.841 0.977]));

% return the full data
res.full = sFull;



function ci = ajl_CI(ci)
% this is a function to create the correct confidence intervals (i.e.
% substract the 50% value: the bias in this case). 

if mod(numel(ci),2) == 0, error('Conf. int must contain uneven number of elements'); end

% get the number of elements in the ci array
n = ceil(numel(ci)/2);

% get the actual value so we can substract it
val = ci(n);

% substract this from CI so we can directly feed it to Matlab
ci_new = ci-val;

% substitute the one that is now 0 with the val
ci_new(n) = val;

% return
ci = ci_new;