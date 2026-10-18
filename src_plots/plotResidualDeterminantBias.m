function fh = plotResidualDeterminantBias(csvFile, p, nu, alpha0Min, alpha0Max, savein)
% plotResidualDeterminantBias  Residual determinant-bias diagnostics.
%
% fh = plotResidualDeterminantBias(csvFile, p, nu, alpha0Min, alpha0Max, savein)
%
% Inputs:
%   csvFile     CSV file with columns p, nu, n, alpha0, BiasDet
%   p           Dimension to plot
%   nu          Degrees of freedom to plot
%   alpha0Min   Lower bound for alpha0
%   alpha0Max   Upper bound for alpha0
%   savein      Logical flag to save figures
%
% Output:
%   fh          Struct with figure handles:
%               - fh.surface
%               - fh.projN
%               - fh.projNu
%
%{

    projectRoot = '.';
    addpath(fullfile(projectRoot, 'src_srep'));
    addpath(fullfile(projectRoot, 'src_core'));
    addpath(fullfile(projectRoot, 'src_plots'));
    
    csvFile = "out_article/BiasDet_table_mean_root_FT.csv";
    %csvFile = "BiasDet_table_mean_root_FT_v1.csv";
    p  = 5;
    nu = [3  10];
    alpha0Min = 0.05;
    alpha0Max = 0.50;
    savein = false;
    
    fh = plotResidualDeterminantBias(csvFile, p, nu, alpha0Min, alpha0Max, savein)

%}

%plot setting:
ylim_par = [0.8 1.15];


close all;
if nargin < 2 || isempty(p)
    p = 5;
end
if nargin < 3 || isempty(nu)
    nu = 3;
end
if nargin < 4 || isempty(alpha0Min)
    alpha0Min = 0.05;
end
if nargin < 5 || isempty(alpha0Max)
    alpha0Max = 0.50;
end
if nargin < 6 || isempty(savein)
    savein = false;
end

if ~(ischar(csvFile) || isstring(csvFile))
    error('csvFile must be a character vector or string.');
end
csvFile = string(csvFile);

saveFolder = 'TMP_FIGs';
if savein && ~isfolder(saveFolder)
    mkdir(saveFolder);
end

T = readtable(csvFile);

requiredVars = {'p', 'nu', 'n', 'alpha0', 'BiasDet'};
missingVars = setdiff(requiredVars, T.Properties.VariableNames);
if ~isempty(missingVars)
    error('Missing required variables in %s: %s', csvFile, strjoin(missingVars, ', '));
end

for current_nu = nu
    idx = T.p == p & T.nu == current_nu & T.alpha0 >= alpha0Min & T.alpha0 <= alpha0Max;
    if ~any(idx)
        error('No data found for p=%d, nu=%d, alpha0 in [%.4g, %.4g].', ...
            p, current_nu, alpha0Min, alpha0Max);
    end

    X = T.alpha0(idx);
    Y = log(T.n(idx));
    Z = T.BiasDet(idx);

    [X_mesh, Y_mesh] = meshgrid( ...
        linspace(min(X), max(X), 500), ...
        linspace(min(Y), max(Y), 500));

    labx = '$\alpha_0$';
    laby = '$n$';
    labz = '$\widetilde{d}_{p,n,\nu}^{\alpha_0}$';

    ft2 = fittype('loess');
    opts2 = fitoptions('Method', 'LowessFit', ...
        'Normalize', 'on', ...
        'Robust', 'off', ...
        'Span', 0.20);

    fitresult2 = fit([X(:), Y(:)], Z(:), ft2, opts2);
    Z_fit2 = fitresult2(X_mesh, Y_mesh);

    stdfont = 20;
    mymarker = '.';
    mymarkersize = 12;
    mymarkercolor = 'b';
    myfitcolor = 'k';
    xlimin = 0;

    fh = struct();

    % fh.surface = figure('Name', sprintf('Residual determinant bias: p=%d, nu=%d', p, current_nu), ...
    %     'Color', 'w', 'Position', [10, 10, 1100, 400]);
    fh.surface = figure('Name', sprintf('Residual determinant bias: p=%d, nu=%d', p, current_nu), ...
        'Color', 'w');    ax = axes('Parent', fh.surface);
    mesh(ax, X_mesh, Y_mesh, Z_fit2);
    hold(ax, 'on');
    plot3(ax, X, Y, Z, mymarker, ...
        'MarkerSize', mymarkersize, ...
        'MarkerEdgeColor', mymarkercolor, ...
        'LineStyle', 'none');
    hold(ax, 'off');
    %colormap(ax, 'sky');
    box(ax, 'on');
    grid(ax, 'off');
    set(ax, 'FontSize', stdfont);
    xlabel(ax, labx, 'Interpreter', 'latex', 'FontSize', stdfont + 4);
    ylabel(ax, laby, 'Interpreter', 'latex', 'FontSize', stdfont + 4);
    zlabel(ax, labz, 'Interpreter', 'latex', 'FontSize', stdfont + 4);
    xlim(ax, [xlimin, 0.5]);
    ylim(ax, log([50 500]));
    ax.YTick = log([50 100 200 500]);
    ax.YTickLabel = string([50 100 200 500]);
    zlim(ax, ylim_par);

    if savein
        saveas(fh.surface, fullfile(saveFolder, 'ResidualDeterminantBias_surface.fig'));
    end

    alpha_grid = linspace(min(X), max(X), 1000);

    fh.projN = gobjects(0, 1);
    nVals = [100 500];
    for nVal = nVals
        idxN = idx & T.n == nVal;
        if ~any(idxN)
            continue
        end

        Xjj = T.alpha0(idxN);
        Zjj = T.BiasDet(idxN);

        zCurve = fitresult2(alpha_grid, log(nVal * ones(size(alpha_grid))));
        yLim = expandLimits(Zjj, 0.20);

        fh.projN(end+1, 1) = plotProjectionFigure( ...
            alpha_grid, zCurve, Xjj, Zjj, ...
            labx, labz, sprintf('$\\nu=%g\\;--\\;n=%g$', current_nu, nVal), ...
            [xlimin, 0.5], yLim, ...
            mymarker, mymarkersize, mymarkercolor, myfitcolor, stdfont, ...
            savein, saveFolder, sprintf('ResidualDeterminantBias_n_%g.fig', nVal));
        ylim(gca,ylim_par)
    end

    fh.projNu = gobjects(0, 1);
    alpha0Fixed = 0.5;
    nGrid = log(linspace(min(T.n(idx)), max(T.n(idx)), 1000));



    idxNu = T.p == p & T.nu == current_nu & abs(T.alpha0 - alpha0Fixed) < 1e-12;
    if ~any(idxNu)
        continue
    end

    Xjj = log(T.n(idxNu));
    Zjj = T.BiasDet(idxNu);

    zCurve = fitresult2(alpha0Fixed * ones(size(nGrid)), (nGrid));
    yLim = expandLimits(Zjj, 0.20);
    xLim = expandLimits(Xjj, 0.05);

    fh.projNu(end+1, 1) = plotProjectionFigure( ...
        nGrid, zCurve, Xjj, Zjj, ...
        '$n$', labz, sprintf('$\\nu=%g\\;--\\;\\alpha_0=%g$', current_nu, alpha0Fixed), ...
        xLim, yLim, ...
        mymarker, mymarkersize, mymarkercolor, myfitcolor, stdfont, ...
        savein, saveFolder, sprintf('ResidualDeterminantBias_nu_%g.fig', current_nu));
    ylim(gca,ylim_par)

end
end

function fhFig = plotProjectionFigure( ...
    xCurve, yCurve, xData, yData, ...
    xLabelText, yLabelText, titleText, ...
    xLimVals, yLimVals, ...
    mymarker, mymarkersize, mymarkercolor, myfitcolor, stdfont, ...
    savein, saveFolder, figName)

fhFig = figure('Name', char(titleText), 'Color', 'w');
ax = axes('Parent', fhFig);

plot(ax, xCurve, yCurve, '-', 'LineWidth', 2, 'Color', myfitcolor);
hold(ax, 'on');
plot(ax, xData, yData, mymarker, ...
    'MarkerSize', mymarkersize + 6, ...
    'MarkerEdgeColor', mymarkercolor, ...
    'LineStyle', 'none');
hold(ax, 'off');

set(ax, 'FontSize', stdfont);
xlabel(ax, xLabelText, 'Interpreter', 'latex', 'FontSize', stdfont + 10);
ylabel(ax, yLabelText, 'Interpreter', 'latex', 'FontSize', stdfont + 10);
title(ax, titleText, 'Interpreter', 'latex', 'HorizontalAlignment', 'right');
xlim(ax, xLimVals);
ylim(ax, yLimVals);
grid(ax, 'off');
box(ax, 'on');
if strcmp(xLabelText,'$n$')
    vals = [50 100 200 500];             % valori originali da mostrare
    ax.XLim = log([50 500]);             % l'asse va esattamente da 50 a 500
    ax.XTick = log(vals);                % posizioni dei tick (nello spazio log)
    ax.XTickLabel = string(vals);        % etichette = valori originali
end
if savein
    saveas(fhFig, fullfile(saveFolder, figName));
end
end

function limVals = expandLimits(v, padFrac)
v = v(:);
v = v(isfinite(v));

if isempty(v)
    limVals = [0 1];
    return
end

vMin = min(v);
vMax = max(v);
pad = padFrac * (vMax - vMin);

if pad == 0
    pad = max(0.05, 0.1 * abs(vMin));
end

limVals = [vMin - pad, vMax + pad];
end
