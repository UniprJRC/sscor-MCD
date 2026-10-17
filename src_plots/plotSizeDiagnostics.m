function hf = plotSizeDiagnostics(CalibrationDatabase, p, alpha0Plot, method, plotMode, nuFilter)
%% ========================================================================
% plotSizeDiagnostics
% ========================================================================
%
% Plot empirical outlier-test size before and after finite-sample
% calibration, for a selected MCD correction method.
%
% SYNTAX
%   fh = plotSizeDiagnostics(CalibrationDatabase,p,alpha0Plot,method,plotMode)
%   fh = plotSizeDiagnostics(...,nuFilter)
%
% INPUTS
%   CalibrationDatabase
%       Table produced by the main simulation script. It contains the
%       empirical sizes, nominal size, and calibrated-size diagnostics
%       for the calibration constructions considered in the simulation.
%
%   p
%       Dimension of the multivariate observations to be plotted.
%
%   alpha0Plot
%       MCD breakdown-point parameter to be plotted.
%
%   method
%       MCD/determinant-correction method to be plotted, e.g.
%           'asymptotic'
%           'det_mean_root'
%           'det_root_mean_cov'
%
%   plotMode
%       Calibration construction to display:
%
%           'pooled'
%               Option A. The empirical calibration cutoff is obtained
%               from the pooled calibration distribution.
%
%           'avg'
%               Option B. The empirical calibration cutoff is obtained by
%               averaging the per-replication quantiles.
%
%           'replicationwise'
%               Option C. The replication-specific calibration quantiles
%               are retained separately.
%
%           'all'
%               Plot the three calibration constructions together.
%
%   nuFilter
%       Optional scalar or vector of nu values to keep. If empty, all
%       available nu values are plotted.
%
% PURPOSE
% -------
% The figure compares the empirical rejection probability of the MCD
% robust-distance outlier test with its nominal level before and after
% finite-sample calibration.
%
%% ========================================================================

%% ------------------------------------------------------------------------
% Defaults
% -------------------------------------------------------------------------

logscale = false;

if nargin < 3 || isempty(alpha0Plot)
    alpha0Plot = min(CalibrationDatabase.alpha0);
end

if nargin < 4 || isempty(method)
    method = 'det_mean_root';
end

if nargin < 5 || isempty(plotMode)
    plotMode = 'avg';
end

if nargin < 6
    nuFilter = [];
end

plotMode = lower(char(plotMode));

validModes = {'pooled','avg','replicationwise','all','pooled_avg'};
if ~ismember(plotMode, validModes)
    error('plotSizeDiagnostics:invalidPlotMode', ...
        ['Unknown plotMode "%s". Use one of: ' ...
         '''pooled'', ''avg'', ''replicationwise'', ''all'', ''pooled_avg''.'], ...
        plotMode);
end


%% ------------------------------------------------------------------------
% Check required variables
% -------------------------------------------------------------------------

requiredVars = { ...
    'method', ...
    'n', ...
    'p', ...
    'nu', ...
    'alpha0', ...
    'sizeRatio', ...
    'q_RD_calibrated'};

switch plotMode
    case 'avg'
        requiredVars{end+1} = 'sizeRatio_calibrated';

    case 'pooled'
        requiredVars{end+1} = 'sizeRatio_calibrated_pooled';

    case 'replicationwise'
        requiredVars{end+1} = 'sizeRatio_calibrated_replicationwise';

    case {'all', 'pooled_avg'}
        requiredVars = [requiredVars, ...
            {'sizeRatio_calibrated', ...
             'sizeRatio_calibrated_pooled'}];

        if strcmp(plotMode, 'all')
            requiredVars{end+1} = 'sizeRatio_calibrated_replicationwise';
        end
end


missingVars = setdiff(requiredVars, CalibrationDatabase.Properties.VariableNames);
if ~isempty(missingVars)
    error('plotSizeDiagnostics:missingVariables', ...
        'CalibrationDatabase is missing: %s', ...
        strjoin(missingVars, ', '));
end

%% ------------------------------------------------------------------------
% Select requested MCD correction construction
% -------------------------------------------------------------------------

T = CalibrationDatabase( ...
    CalibrationDatabase.p == p & ...
    CalibrationDatabase.alpha0 == alpha0Plot & ...
    strcmp(CalibrationDatabase.method, method), :);

if ~isempty(nuFilter)
    T = T(ismember(T.nu, nuFilter), :);
end

if isempty(T)
    error(['No data found for p=%d, alpha0=%.4g, ' ...
        'method=%s, nuFilter=%s.'], ...
        p, alpha0Plot, method, mat2str(nuFilter));
end

nuGrid = unique(T.nu);
nCols = numel(nuGrid);

%% ------------------------------------------------------------------------
% Plotting defaults
% -------------------------------------------------------------------------

set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');

fs = 20;
set(groot, ...
    'defaultAxesFontSize', fs, ...
    'defaultTextFontSize', fs, ...
    'defaultLegendFontSize', fs);

colBefore = [0.40 0.40 0.40];
colPooled = [0.0000 0.4470 0.7410];
colAvg    = [0.8500 0.3250 0.0980];
colRep    = [0.4940 0.1840 0.5560];

lw = 2;
mkSize = 7;

%% ------------------------------------------------------------------------
% Determine which calibrated columns are plotted
% -------------------------------------------------------------------------

switch plotMode
    case 'pooled'
        calibratedVars = {'sizeRatio_calibrated_pooled'};
        calibratedLabels = {'after pooled calibration'};
        calibratedStyles = {'--'};
        calibratedMarkers = {'s'};
        calibratedColors = {colPooled};

    case 'avg'
        calibratedVars = {'sizeRatio_calibrated'};
        calibratedLabels = {'after average calibration'};
        calibratedStyles = {'--'};
        calibratedMarkers = {'s'};
        calibratedColors = {colAvg};

    case 'replicationwise'
        calibratedVars = {'sizeRatio_calibrated_replicationwise'};
        calibratedLabels = {'after replication-wise calibration'};
        calibratedStyles = {'--'};
        calibratedMarkers = {'d'};
        calibratedColors = {colRep};

    case 'pooled_avg'
        calibratedVars = { ...
            'sizeRatio_calibrated_pooled', ...
            'sizeRatio_calibrated'};

        calibratedLabels = { ...
            'after pooled calibration', ...
            'after average calibration'};

        calibratedStyles = {'--','-.'};
        calibratedMarkers = {'s','o'};
        calibratedColors = {colPooled, colAvg};

    case 'all'
        calibratedVars = { ...
            'sizeRatio_calibrated_pooled', ...
            'sizeRatio_calibrated', ...
            'sizeRatio_calibrated_replicationwise'};

        calibratedLabels = { ...
            'after pooled calibration', ...
            'after average calibration', ...
            'after replication-wise calibration'};

        calibratedStyles = {'--','-.',':'};
        calibratedMarkers = {'s','o','d'};
        calibratedColors = {colPooled, colAvg, colRep};
end


%% ------------------------------------------------------------------------
% Determine common y-axis range
% -------------------------------------------------------------------------

allRatios = T.sizeRatio;
allRatios = [allRatios; 1];

for j = 1:numel(calibratedVars)
    allRatios = [allRatios; T.(calibratedVars{j})]; %#ok<AGROW>
end

allRatios = allRatios(isfinite(allRatios));

yMin = min(allRatios);
yMax = max(allRatios);

yPad = 0.05 * (yMax - yMin);
if yPad == 0
    yPad = 0.05;
end

yLim = [yMin - yPad, yMax + yPad];

%% ------------------------------------------------------------------------
% Create figure
% -------------------------------------------------------------------------

if strcmp(plotMode, 'all')
    modeTitle = 'A/B/C calibration comparison';
elseif strcmp(plotMode, 'pooled_avg')
    modeTitle = 'pooled vs average calibration';
else
    modeTitle = calibratedLabels{1};
end


hf = figure( ...
    'Name', ...
    sprintf('Outlier-test size diagnostics: p=%d, alpha0=%.2f, %s', ...
    p, alpha0Plot, modeTitle));

%% ------------------------------------------------------------------------
% Plot each nu
% -------------------------------------------------------------------------

for iu = 1:nCols

    nu = nuGrid(iu);

    Tn = T(T.nu == nu, :);
    Tn = sortrows(Tn, 'n');

    subplot(1, nCols, iu);
    hold on;

    % Before calibration
    plot(Tn.n, ...
        Tn.sizeRatio, ...
        'LineStyle', '-', ...
        'Marker', 'o', ...
        'Color', colBefore, ...
        'LineWidth', lw, ...
        'MarkerSize', mkSize, ...
        'DisplayName', 'before calibration');

    % Calibrated curves
    for j = 1:numel(calibratedVars)
        plot(Tn.n, ...
            Tn.(calibratedVars{j}), ...
            'LineStyle', calibratedStyles{j}, ...
            'Marker', calibratedMarkers{j}, ...
            'Color', calibratedColors{j}, ...
            'LineWidth', lw, ...
            'MarkerSize', mkSize, ...
            'DisplayName', calibratedLabels{j});
    end

    % Nominal size
    yline(1, 'k:', ...
        'HandleVisibility', 'off', 'LineWidth', 2.5);

    if logscale
        set(gca, 'XScale', 'log');

        xi = unique(Tn.n);
        xticks(xi);
        if all(mod(xi, 1) == 0)
            xtickformat('%,.0f');
        end
    end

    ylim(yLim);
    xlabel('$n$', 'Interpreter', 'latex');

    [~, imax] = max(Tn.n);
    qCal = Tn.q_RD_calibrated(imax);

    title(sprintf('$p=%d$, $\\alpha_0=%.2f$, $\\nu=%d$ -- Cutoff for largest $n$: $\\sqrt{q_{cal}}=%.2f$', ...
        p, alpha0Plot, nu, qCal), 'Interpreter', 'latex');

    if iu == 1
        ylabel('empirical size / nominal size', 'Interpreter', 'latex');
        legend('Location', 'best', 'Interpreter', 'latex');
    end
end

%% ------------------------------------------------------------------------
% Console diagnostic
% -------------------------------------------------------------------------

fprintf('\nSize diagnostic summary\n');
fprintf('p = %d, alpha0 = %.4g, MCD method = %s\n', ...
    p, alpha0Plot, method);
fprintf('calibration plot mode = %s\n\n', plotMode);

for iu = 1:nCols

    nu = nuGrid(iu);

    Tn = T(T.nu == nu, :);
    Tn = sortrows(Tn, 'n');

    fprintf('nu = %g:\n', nu);
    fprintf('  before calibration : min = %.4f, max = %.4f\n', ...
        min(Tn.sizeRatio), max(Tn.sizeRatio));

    for j = 1:numel(calibratedVars)
        x = Tn.(calibratedVars{j});
        fprintf('  %-36s: min = %.4f, max = %.4f\n', ...
            calibratedLabels{j}, min(x), max(x));
    end

    fprintf('\n');
end

end
