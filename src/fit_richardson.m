function [params_best, x_fit, y_fit] = fit_richardson(years, us_data, ussr_data)
% =========================================================
%  Richardson Parameter Estimation via Nonlinear Least Squares
%
%  Model:
%    dx/dt = a*y - m*x + r    (USA)
%    dy/dt = b*x - n*y + s    (USSR)
%
%  params = [a, m, r, b, n, s]
%    a, b : reaction coefficients (sensitivity to opponent's spending)
%    m, n : fatigue coefficients  (cost-of-arms, economic drag)
%    r, s : grievance terms       (baseline spending independent of opponent)
%
%  This is an inverse problem: given the observed trajectories x(t) and
%  y(t), find the parameter vector that minimizes the ODE simulation error.
%
%  lsqnonlin is used with MultiStart (50 random initializations) to
%  reduce the risk of converging to a local minimum — necessary for a
%  6-parameter system driven by a nonlinear ODE solver.
% =========================================================

tspan = years - years(1);           % time axis: t=0 corresponds to 1960
y0    = [us_data(1); ussr_data(1)]; % initial conditions from first observation

residual_fn = @(p) compute_residuals(p, tspan, y0, us_data(:), ussr_data(:));

% Parameter bounds — enforce physical constraints:
%   reaction and fatigue coefficients must be non-negative
%   grievance terms are non-negative by definition
lb = [0.0, 0.05, 0.00,  0.0, 0.05, 0.00];
ub = [1.5, 1.50, 0.30,  1.5, 1.50, 0.30];

options = optimoptions('lsqnonlin', ...
    'Display',             'off',  ...  % MultiStart handles progress display
    'MaxIterations',       2000,   ...
    'FunctionTolerance',   1e-12,  ...
    'StepTolerance',       1e-12,  ...
    'OptimalityTolerance', 1e-10);

problem = createOptimProblem('lsqnonlin', ...
    'objective', residual_fn, ...
    'x0',  [0.5, 0.8, 0.05, 0.4, 0.7, 0.03], ...
    'lb',  lb, ...
    'ub',  ub, ...
    'options', options);

ms = MultiStart('Display', 'iter', 'FunctionTolerance', 1e-8);
fprintf('Running MultiStart (50 initial points)...\n');
[params_best, resnorm] = run(ms, problem, 50);

fprintf('\n--- Fit Results ---\n');
labels = {'a (USA reaction)   ', 'm (USA fatigue)    ', 'r (USA grievance)  ', ...
          'b (USSR reaction)  ', 'n (USSR fatigue)   ', 's (USSR grievance) '};
for i = 1:6
    fprintf('  %s = %.4f\n', labels{i}, params_best(i));
end
fprintf('  Residual norm      = %.6f\n', resnorm);

% Richardson stability condition: equilibrium is stable iff m*n > a*b
% This follows directly from the sign of the Jacobian eigenvalues.
fprintf('\n--- Stability Analysis ---\n');
ab = params_best(1) * params_best(4);
mn = params_best(2) * params_best(5);
if ab < mn
    fprintf('  Stability condition satisfied: a*b < m*n (%.4f < %.4f)\n', ab, mn);
    fprintf('  The arms race is a stable dynamical system.\n');
else
    fprintf('  Stability condition VIOLATED: a*b >= m*n (%.4f >= %.4f)\n', ab, mn);
    fprintf('  The arms race is unstable — expenditures diverge.\n');
end

if params_best(1) < params_best(4)
    fprintf('  USSR is more reactive to US spending (b=%.3f > a=%.3f)\n', ...
            params_best(4), params_best(1));
else
    fprintf('  USA is more reactive to USSR spending (a=%.3f > b=%.3f)\n', ...
            params_best(1), params_best(4));
end

% Simulate with best-fit parameters for visualization
[~, sol] = ode45(@(t,y) rhs(t, y, params_best), tspan, y0);
x_fit = sol(:,1);
y_fit = sol(:,2);
end

% ----------------------------------------------------------
function res = compute_residuals(p, tspan, y0, us_data, ussr_data)
% Integrates the Richardson ODE and returns the residual vector.
% USSR residuals are weighted 1.5x because the CIA estimates are
% less certain than the SIPRI figures — this prevents the optimizer
% from over-fitting the US side at the expense of the USSR fit.
    opts = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
    try
        [~, sol] = ode45(@(t,y) rhs(t, y, p), tspan, y0, opts);
        res = [sol(:,1) - us_data;
               1.5 * (sol(:,2) - ussr_data)];
    catch
        % If the ODE blows up (unstable parameters), return a large penalty
        res = 1e6 * ones(2*length(tspan), 1);
    end
end

% ----------------------------------------------------------
function dydt = rhs(~, y, p)
% Richardson ODE right-hand side
%   y(1) = x : USA expenditure (normalized)
%   y(2) = y : USSR expenditure (normalized)
    dydt = [p(1)*y(2) - p(2)*y(1) + p(3);
            p(4)*y(1) - p(5)*y(2) + p(6)];
end
