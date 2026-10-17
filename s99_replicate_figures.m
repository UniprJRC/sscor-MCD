%% ========================================================================
% s99_replicate_figures.m
% ========================================================================
%
% Replication script for all figures in the paper.
% Each section of the script corresponds to one figure or figure panel and
% reads the precomputed calibration, interpolation, or application data
% produced by the earlier scripts.

clear all; close all; clc;

projectRoot = '.';
addpath(fullfile(projectRoot, 'src_srep'));
addpath(fullfile(projectRoot, 'src_core'));
addpath(fullfile(projectRoot, 'src_plots'));

%% Figure 1: determinant-bias diagnostics

% Load the calibration table for the mean-root determinant construction.
% This file contains the finite-sample bias factor estimates used in the paper.
F1 = fullfile(projectRoot, "out_article", "BiasDet_table_mean_root.csv");
T_mean_root = readtable(F1);

% The alternative root of the determinant of the mean covariance is not of
% interest here.
T_root_mean_cov = [];

% Select the configuration used for the figure:
p_F1        = 5;     % dimension
alpha0_F1   = 0.5;   % trimming proportion
nuFilter_F1 = 3;     % only show the nu = 3 panel

% Plot the finite-sample determinant bias and its inverse correction factor.
h_F1 = plotDeterminantBiasDiagnostics( ...
       T_mean_root, T_root_mean_cov, p_F1, alpha0_F1, nuFilter_F1);


%% Figure 2



%% Figure 3: LOESS interpolation surface for delta_hat

% This script is an extract of function plot_loess_interpolants.m

% Load the interpolation lookup table produced by s02.
% This table stores the dense LOESS surface for delta_hat in long format.
InterpolationRoot = fullfile(projectRoot, 'out_article');
T_F3 = readtable(fullfile(InterpolationRoot, 'delta_loess_lookup.csv'));

% Select the slice used for the figure.
% The plot shows delta_hat as a function of n and alpha0,
% for fixed dimension p and degrees of freedom nu.
pSel_F3   = 2;
nuSel_F3  = 5;

% Keep only the rows corresponding to the chosen (p, nu) pair.
sel = T_F3.p == pSel_F3 & T_F3.nu == nuSel_F3;
T_F3_sel = T_F3(sel, :);

% Rebuild the surface on the (n, alpha0) grid.
nVals = unique(T_F3_sel.n, 'sorted');
aVals = unique(T_F3_sel.alpha0, 'sorted');

Z = nan(numel(aVals), numel(nVals));
[~, in] = ismember(T_F3_sel.n, nVals);
[~, ia] = ismember(T_F3_sel.alpha0, aVals);
Z(sub2ind(size(Z), ia, in)) = T_F3_sel.loess;

% Plot the LOESS surface.
h_F3 = figure('Name', sprintf('LOESS surface for delta_hat: p=%d, nu=%d', pSel_F3, nuSel_F3));
setfont = 20;

surf(nVals, aVals, Z, 'EdgeColor', 'none')
ax = gca;
ax.FontSize  = 18;
ax.LineWidth = 0.5;
xlabel('$n$', 'Interpreter', 'latex', 'FontSize', setfont)
ylabel('$\alpha_0$', 'Interpreter', 'latex', 'FontSize', setfont)
zlabel('$\widehat{\delta}(n,p,\alpha_0,\nu)$ LOESS surface', ...
    'Interpreter', 'latex', 'FontSize', setfont)
view(45, 30)
grid on

%% Figure 4: distance-based calibration factor kappa_RD

% Load the calibration database produced by s01.
% This CSV contains the empirical and calibrated robust-distance quantiles
% used to compute kappa_RD under the multivariate t model.
F4  = fullfile(projectRoot, "out_article", "mcd_heavytails_RD_calibration.csv");
T_4 = readtable(F4);

% Select the configuration used for the figure
p_F4        = 5;      % dimension
alpha0_F4   = 0.50;   % trimming proportion
nuFilter_F4 = 3;      % only show the nu = 3 panel
plotMode_F4 = 'avg';  % average calibration approach adopted in Equation (21)

% Plot the finite-sample calibration factor kappa_RD.
% The 'avg' mode shows the calibration based on the average per-replication
% quantile, which is the main quantity used in the paper.
fh_F4 = plotKappaRDDiagnostics(T_4, p_F4, alpha0_F4, plotMode_F4, nuFilter_F4);

%% Figure 5: size diagnostics

% Load ... produced by s01.
% This CSV contains ...
F5  = fullfile(projectRoot, "out_article", "mcd_heavytails_RD_calibration.csv");
T_5 = readtable(F5);

p_F5        = 5;      % dimension
alpha0_F5   = 0.50;   % trimming proportion
nuFilter_F5 = 3;      % only show the nu = 3 panel
method_F5   = 'det_mean_root'; % root determinant of the mean covariance matrix
plotMode_F5 = 'avg';  % average calibration approach adopted in Equation (21)

h_F5 = plotSizeDiagnostics(T_5, p_F5, alpha0_F5, method_F5, plotMode_F5, nuFilter_F5);

