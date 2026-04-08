% =========================================================
%  Richardson Arms Race Model — Entry Point
%  Run this file. Everything else is called from here.
%
%  Pipeline:
%    1. Load US (SIPRI/OWID) and USSR (CIA) expenditure data
%    2. Fit Richardson ODE parameters via nonlinear least squares
%    3. Analyze the resulting dynamical system with PID and root locus
% =========================================================
clear; clc; close all;

[years, us_data, ussr_data] = data_loader();

fprintf('\n=== STAGE 1: Parameter Estimation ===\n');
[params, us_fit, ussr_fit] = fit_richardson(years, us_data, ussr_data);

% --- Visualize fit quality ---
figure('Position', [100 100 1000 500]);
plot(years, us_data,   'b-o', 'LineWidth', 2, 'DisplayName', 'USA (actual)');    hold on;
plot(years, ussr_data, 'r-o', 'LineWidth', 2, 'DisplayName', 'USSR (actual)');
plot(years, us_fit,    'b--', 'LineWidth', 2, 'DisplayName', 'USA (model fit)');
plot(years, ussr_fit,  'r--', 'LineWidth', 2, 'DisplayName', 'USSR (model fit)');

% Mark major historical events — these are the periods where the model
% is expected to diverge, because Richardson cannot capture domestic shocks
xline(1968, 'k:', 'LineWidth', 1.2);
text(1968.2, 0.72, 'Vietnam Peak',      'Rotation', 90, 'FontSize', 8);
xline(1979, 'k:', 'LineWidth', 1.2);
text(1979.2, 0.72, 'Afghanistan',       'Rotation', 90, 'FontSize', 8);
xline(1981, 'k:', 'LineWidth', 1.2);
text(1981.2, 0.72, 'Reagan Buildup',    'Rotation', 90, 'FontSize', 8);
xline(1985, 'k:', 'LineWidth', 1.2);
text(1985.2, 0.72, 'Gorbachev',         'Rotation', 90, 'FontSize', 8);

legend('Location', 'northwest'); grid on;
xlabel('Year'); ylabel('Normalized Expenditure (1960 = 1.0)');
title('Richardson Model — Parameter Fit on SIPRI/CIA Data');

fprintf('\n=== STAGE 2: PID Control Analysis ===\n');
pid_analysis(params);
