%% ========================================================================
% s99_replicate_figures.m
% ========================================================================
%
% Replication script for all figures in the paper.
% Each section of the script corresponds to one figure or figure panel and
% reads the precomputed calibration, interpolation, or application data
% produced by the earlier scripts.

projectRoot = '.';
addpath(fullfile(projectRoot, 'src_srep'));
addpath(fullfile(projectRoot, 'src_core'));
addpath(fullfile(projectRoot, 'src_plots'));

%% Figure 1: determinant-bias diagnostics

% Load the calibration table for the mean-root determinant construction.
% This file contains the finite-sample bias factor estimates used in the paper.
filename = fullfile(projectRoot, "out_article", "BiasDet_table_mean_root.csv");
T_mean_root = readtable(filename);

% The alternative root of the determinant of the mean covariance is not of
% interest here.
T_root_mean_cov = [];

% Select the configuration used for the figure:
p = 5;              % dimension
alpha0Plot = 0.5;   % trimming proportion
nuFilter = 3;       % only show the nu = 3 panel

% Plot the finite-sample determinant bias and its inverse correction factor.
hf = plotDeterminantBiasDiagnostics( ...
    T_mean_root, T_root_mean_cov, p, alpha0Plot, nuFilter);


%% Figure 2



%% Figure 3: LOESS interpolation surface for delta_hat

% This acript is an extract of function plot_loess_interpolants.m

% Load the interpolation lookup table produced by s02.
% This table stores the dense LOESS surface for delta_hat in long format.
InterpolationRoot = fullfile(projectRoot, 'out_article');
T_delta = readtable(fullfile(InterpolationRoot, 'delta_loess_lookup.csv'));

% Select the slice used for the figure.
% The plot shows delta_hat as a function of n and alpha0,
% for fixed dimension p and degrees of freedom nu.
pSel   = 2;
nuSel  = 5;

% Keep only the rows corresponding to the chosen (p, nu) pair.
T = T_delta;
sel = T.p == pSel & T.nu == nuSel;
S = T(sel, :);

% Rebuild the surface on the (n, alpha0) grid.
nVals = unique(S.n, 'sorted');
aVals = unique(S.alpha0, 'sorted');

Z = nan(numel(aVals), numel(nVals));
[~, in] = ismember(S.n, nVals);
[~, ia] = ismember(S.alpha0, aVals);
Z(sub2ind(size(Z), ia, in)) = S.loess;

% Plot the LOESS surface.
hf_delta = figure;
setfont = 20;

surf(nVals, aVals, Z, 'EdgeColor', 'none')
ax = gca;
ax.FontSize = 18;
ax.LineWidth = 0.5;
xlabel('$n$', 'Interpreter', 'latex', 'FontSize', setfont)
ylabel('$\alpha_0$', 'Interpreter', 'latex', 'FontSize', setfont)
zlabel('$\widehat{\delta}(n,p,\alpha_0,\nu)$ LOESS surface', ...
    'Interpreter', 'latex', 'FontSize', setfont)
view(45, 30)
grid on



