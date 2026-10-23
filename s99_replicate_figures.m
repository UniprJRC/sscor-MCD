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

% Replicate the mean-root determinant bias diagnostic used in the paper.
% Load the precomputed bias table, keep p = 5 and alpha0 = 0.5, and show
% only the nu = 3 panel.

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

p  = 5;
nu = [3  10];
alpha0Min = 0.05;
alpha0Max = 0.50;
savein = false;

%csvFile = "out_article/BiasDet_table_mean_root_FT.csv";
csvFile = "out_article/BiasDet_table_mean_root.csv";
fh = plotResidualDeterminantBias(csvFile, p, nu, alpha0Min, alpha0Max, savein);


%% Figure 3: LOESS interpolation surface for delta_hat

% Replicate the delta_hat LOESS surface from the interpolation lookup table.
% Plot the slice for fixed p = 2 and nu = 5.

% This script is an extract of function plot_loess_interpolants.m

% Load the interpolation lookup table produced by s02.
% This table stores the dense LOESS surface for delta_hat in long format.
InterpolationRoot = fullfile(projectRoot,    'out_article');
T_F3 = readtable(fullfile(InterpolationRoot, 'delta_loess_lookup.csv'));

% Select the slice used for the figure.
% The plot shows delta_hat as a function of n and alpha0,
% for fixed dimension p and degrees of freedom nu.
pSel_F3   = 2;
nuSel_F3  = 5;
conflevSel_F3 = 0.50;

% Plot the delta_hat LOESS surface for the selected (p, nu) slice.
h_F3 = plotLoessInterpolantDelta(T_F3, pSel_F3, nuSel_F3);


%% Figure 4: distance-based calibration factor kappa_RD

% Replicate the kappa_RD diagnostics from the calibration database.
% Use the average calibration construction and show only the nu = 3 panel.

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

%% Figure 5: size diagnostics for the robust-distance outlier test

% Replicate the empirical size diagnostics before and after calibration.
% Use the det_mean_root method, the average calibration construction, and
% show only the nu = 3 panel.

% Load the simulation output produced by s01.
% This table contains the empirical size of the outlier test before
% calibration, together with the calibrated size ratios for the available
% correction constructions.
F5  = fullfile(projectRoot, "out_article", "mcd_heavytails_RD_calibration.csv");
T_5 = readtable(F5);

% Select the configuration shown in the paper:
p_F5        = 5;      % dimension
alpha0_F5   = 0.50;   % trimming proportion
nuFilter_F5 = 3;      % only show the nu = 3 panel
method_F5   = 'det_mean_root'; % root determinant of the mean covariance matrix
plotMode_F5 = 'avg';  % average calibration approach adopted in Equation (21)

% Plot the empirical size divided by the nominal size, before and after
% calibration. Values near 1 indicate good finite-sample calibration.
h_F5 = plotSizeDiagnostics(T_5, p_F5, alpha0_F5, method_F5, plotMode_F5, nuFilter_F5);

%% Figure 6: LOESS interpolation surface for kappa_RD^delta

% Replicate the RD LOESS surface from the interpolation lookup table.
% Plot the slice for fixed p = 2, nu = 5, and conflev = 0.95.

% This script is an extract of function plot_loess_interpolants.m

% Load the interpolation lookup table produced by s02.
% This table stores the dense LOESS surface for delta_hat in long format.
InterpolationRoot = fullfile(projectRoot,    'out_article');
T_F6 = readtable(fullfile(InterpolationRoot, 'RD_loess_lookup.csv'));

% Select the slice used for the figure.
% The plot shows delta_hat as a function of n and alpha0,
% for fixed dimension p and degrees of freedom nu.
pSel_F6   = 2;
nuSel_F6  = 5;
conflevSel_F6 = 0.95;

% Plot the kappa_RD^delta LOESS surface for the selected (p, nu) slice.
h_F6 = plotLoessInterpolantRD(T_F6, pSel_F6, nuSel_F6, conflevSel_F6);

%% Figure 7: application to Grass dataset

s03_application;

%% Figure B1: size diagnostics under two percentile conventions

% Compare the Figure 5 diagnostic under two calibration settings:
%   - 'inclusive'  -> the default convention used in the main paper
%   - 'midpoint'   -> the alternative convention used to build a separate
%                     calibration table
% Both figures use the same plotting settings; only the calibration table
% changes.
p_F5        = 5;      % dimension
alpha0_F5   = 0.50;   % trimming proportion
nuFilter_F5 = 3;      % only show the nu = 3 panel
method_F5   = 'det_mean_root'; % root determinant of the mean covariance matrix
plotMode_F5 = 'avg';  % average calibration approach adopted in Equation (21)

% Calibration table computed with the 'inclusive' convention.
F5  = fullfile(projectRoot, "out_article", "mcd_heavytails_RD_calibration.csv");
T_5 = readtable(F5);

% Calibration table computed with the 'midpoint' convention.
FB1m  = fullfile(projectRoot, "out_article", "mcd_heavytails_RD_calibration_midpoint.csv");
T_B1m = readtable(FB1m);

% Plot the baseline Figure 5 version.
h_B1i = plotSizeDiagnostics(T_5, p_F5, alpha0_F5, method_F5, plotMode_F5, nuFilter_F5);

% Plot the counterpart obtained with the alternative 'midpoint' setting.
h_B1m = plotSizeDiagnostics(T_B1m, p_F5, alpha0_F5, method_F5, plotMode_F5, nuFilter_F5);

%% Figure B2: size diagnostics with average and pooled calibrations

% Replicate the Figure 5 setup, but keep only the two main calibration
% summaries: pooled and average. This makes the comparison between the two
% aggregated calibration rules explicit while leaving all other settings
% unchanged.

% Reuse the inclusive calibration table from the main paper.
F_B2 = fullfile(projectRoot, "out_article", "mcd_heavytails_RD_calibration.csv");
T_B2 = readtable(F_B2);

% Same configuration as Figure 5.
p_F_B2        = 5;     % dimension
alpha0_F_B2   = 0.50;  % trimming proportion
nuFilter_F_B2 = 3;     % keep only the nu = 3 panel
method_F_B2   = 'det_mean_root';

% Plot only pooled and average calibration curves in the same panel.
plotMode_F_B2 = 'pooled_avg';

h_B2 = plotSizeDiagnostics( ...
    T_B2, p_F_B2, alpha0_F_B2, method_F_B2, plotMode_F_B2, nuFilter_F_B2);
