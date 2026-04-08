function pid_analysis(params_best)
% =========================================================
%  PID Control Analysis of the Richardson Arms Race System
%
%  The Richardson ODE is recast in state-space form:
%    x_dot = A*x + B*u
%    y_out = C*x + D*u
%
%  Physical interpretation:
%    - The USA acts as the controller, observing Soviet expenditure
%      and adjusting its own spending as the control input.
%    - The USSR's expenditure trajectory is treated as the plant output.
%    - The PID controller models a reactive policy: proportional to the
%      current gap, integral of past threat accumulation, derivative
%      response to the rate of Soviet buildup.
%
%  This framing lets us ask: how aggressively can the USA respond
%  before the closed-loop system becomes unstable? Root locus, step
%  response, and Bode analysis answer this from different angles.
% =========================================================

a = params_best(1); m = params_best(2);
b = params_best(4); n = params_best(5);

% State-space matrices
% Control input enters through the USA equation (B = [1; 0])
% Output is USSR expenditure (C = [0, 1])
A = [-m, a; b, -n];
B = [1; 0];
C = [0, 1];
D = 0;
sys = ss(A, B, C, D);

ev = eig(A);
fprintf('Open-loop eigenvalues: lambda_1=%.4f, lambda_2=%.4f\n', ev(1), ev(2));
if any(real(ev) > 0)
    fprintf('  Open-loop UNSTABLE — arms race diverges without control.\n');
else
    fprintf('  Open-loop stable — arms race converges on its own.\n');
end

tf_sys = tf(sys);
fprintf('Open-loop transfer function:\n'); display(tf_sys);

% PID controller: Kp=1.0, Ki=0.1, Kd=0.05, derivative filter N=10
% The derivative filter (last argument) prevents the pure differentiator
% from amplifying high-frequency noise — important for any realistic policy.
pid_ctrl = pid(1.0, 0.1, 0.05, 0.1);
fprintf('PID controller transfer function:\n'); display(tf(pid_ctrl));

% Closed-loop system with unit negative feedback
sys_cl = feedback(pid_ctrl * sys, 1);

% --- Figure 1: Root Locus ---
% Shows where the closed-loop poles travel as gain K is scaled.
% Poles crossing into the right half-plane signal instability.
figure('Name', 'Root Locus', 'Position', [50 400 700 600]);
rlocus(pid_ctrl * sys);
title('Root Locus: Closed-Loop Pole Trajectories vs. Gain K');
xlabel('Real Axis (\sigma)');
ylabel('Imaginary Axis (j\omega)');
xline(0, 'r--', 'Stability Boundary', 'LineWidth', 2, ...
      'LabelVerticalAlignment', 'bottom');
grid on;

% --- Figure 2: Step Response ---
% Answers: if USSR holds spending constant, how does the USA respond?
% Oscillation indicates marginal stability — a low phase margin signature.
figure('Name', 'Step Response', 'Position', [770 400 620 500]);
step(sys_cl, 30);   % 30-year horizon matches the 1960-1990 data window
title({'Step Response (30-year horizon)', ...
       'USA reaction when USSR holds expenditure constant'});
xlabel('Years'); ylabel('Normalized Expenditure');
grid on;

% --- Figure 3: Bode Plot ---
% Gain margin: how much can K increase before instability?
% Phase margin: how much phase lag can the system tolerate?
% A phase margin below ~30 degrees implies oscillatory transients.
figure('Name', 'Bode Plot', 'Position', [50 50 700 500]);
bode(pid_ctrl * sys);
title('Bode Plot — Gain and Phase Margins');
grid on;

% --- Stability margin report ---
[Gm, Pm, ~, ~] = margin(pid_ctrl * sys);
fprintf('\n--- Stability Margins ---\n');
fprintf('  Gain margin  : %.2f dB\n', 20*log10(Gm));
fprintf('  Phase margin : %.2f degrees\n', Pm);

if Pm > 45
    fprintf('  System is robustly stable (PM > 45 deg).\n');
elseif Pm > 0
    fprintf('  System is stable but with low phase margin — expect oscillatory response.\n');
    fprintf('  In political terms: any bureaucratic or intelligence delay\n');
    fprintf('  could turn a stabilizing policy into a destabilizing one.\n');
else
    fprintf('  System is UNSTABLE — PID gains need to be reduced.\n');
end
end
