function [axRD, axSPM] = plotApplicationDiagnostics(X0, RD2, group_labels, q2_asym, q2_cal, datasetName)
%% ========================================================================
% plotApplicationDiagnostics
% ========================================================================
%
% Plot the robust-distance diagnostic and the grouped scatterplot matrix
% for an MCD application.
%
% Inputs:
%   X0           data matrix
%   RD2          squared robust distances to plot
%   group_labels  integer labels:
%                   0 = regular units
%                   1 = calibrated outliers
%                   2 = asymptotic-only borderline units
%   q2_asym      asymptotic squared cutoff
%   q2_cal       calibrated squared cutoff
%   datasetName   figure title prefix, e.g. 'Grass Dataset'
%
% Outputs:
%   hRD   handle to the robust-distance diagnostic figure
%   hSPM  handle to the scatterplot-matrix figure
%% ========================================================================

if nargin < 6 || isempty(datasetName)
    datasetName = 'Application';
end

n0 = size(X0, 1);
p0 = size(X0, 2);

regularColor = [0.2 0.2 0.2];
regularFace  = 'none';
calColor     = [0.00 0.45 0.74];
calFace      = [0.00 0.45 0.74];
borderColor  = [0.85 0.33 0.10];
borderFace   = [0.85 0.33 0.10];

idx0 = find(group_labels == 0);
idx1 = find(group_labels == 1);
idx2 = find(group_labels == 2);

%% Robust-distance diagnostic
figure('Name', sprintf('%s_RD_Diagnostic', datasetName)); %'Position', [100, 100, 900, 500]);
hold on; grid on;

plot(idx0, RD2(idx0), 'o', ...
    'Color', regularColor, 'MarkerFaceColor', regularFace, ...
    'MarkerSize', 5, 'DisplayName', 'Regular units');

plot(idx1, RD2(idx1), 'o', ...
    'Color', calColor, 'MarkerFaceColor', calFace, ...
    'MarkerSize', 6, 'DisplayName', 'Calibrated outliers');

plot(idx2, RD2(idx2), 'o', ...
    'Color', borderColor, 'MarkerFaceColor', borderFace, ...
    'MarkerSize', 8, 'DisplayName', 'Borderline (asymptotic only)');

yline(q2_asym, '--r', 'LineWidth', 1.8, ...
    'DisplayName', 'Asymptotic cutoff');
yline(q2_cal, '-b', 'LineWidth', 2.0, ...
    'DisplayName', 'Calibrated cutoff');

xlabel('Observation index $i$', 'Interpreter', 'latex', 'FontSize', 14);
ylabel('Squared robust distance', 'Interpreter', 'latex', 'FontSize', 14);
title(sprintf('%s ($n=%d, p=%d$)', datasetName, n0, p0), ...
    'Interpreter', 'latex', 'FontSize', 16);
legend('Location', 'northeast', 'Interpreter', 'latex', 'FontSize', 12);

ylim([0, max([RD2; q2_cal]) * 1.15]);
axRD = gca;

%% Scatterplot matrix
groupOrder = [0 1 2];
groupNames = strings(n0, 1);
groupNames(group_labels == 0) = "Regular units";
groupNames(group_labels == 1) = "Calibrated outliers";
groupNames(group_labels == 2) = "Borderline (asymptotic only)";

plo = struct;
plo.sym = repmat({'o'}, 1, numel(groupOrder));
plo.doleg = 'on';

[~, AX1, BigAx1] = spmplot(X0, 'group', groupNames, ...
    'plo', plo, 'dispopt', 'box');

sgtitle(sprintf('%s: Outlier Calibration Diagnostics', datasetName), ...
    'FontSize', 16, 'Interpreter', 'latex');

pData = size(X0, 2);

if ismatrix(AX1) && size(AX1,1) >= pData && size(AX1,2) >= pData
    axGrid = AX1(1:pData, 1:pData);
    mask = ~eye(pData);
    axOff = axGrid(mask);
    [ii, jj] = ind2sub([pData, pData], find(mask));
else
    axOff = AX1(:);
    axOff = axOff(1:min(numel(axOff), pData * (pData - 1)));
    [ii, jj] = ind2sub([pData, pData], (1:numel(axOff)).');
    keep = ii ~= jj;
    axOff = axOff(keep);
    ii = ii(keep);
    jj = jj(keep);
end

for k = 1:numel(axOff)
    ax = axOff(k);
    i = ii(k);
    j = jj(k);

    hLines = findall(ax, 'Type', 'line');
    hLines = hLines(arrayfun(@(h) isprop(h, 'Marker') && ~strcmp(h.Marker, 'none'), hLines));

    if isempty(hLines)
        continue;
    end

    for h = 1:numel(hLines)
        coords = [hLines(h).XData(:), hLines(h).YData(:)];

        for g = 0:2
            expected = X0(group_labels == g, [j i]);

            if isempty(expected)
                continue;
            end

            if size(coords, 1) == size(expected, 1) && isequal(sortrows(coords), sortrows(expected))
                switch g
                    case 0
                        hLines(h).MarkerEdgeColor = regularColor;
                        hLines(h).MarkerFaceColor = regularFace;
                    case 1
                        hLines(h).MarkerEdgeColor = calColor;
                        hLines(h).MarkerFaceColor = calFace;
                    case 2
                        hLines(h).MarkerEdgeColor = borderColor;
                        hLines(h).MarkerFaceColor = borderFace;
                end
                break;
            end
        end
    end
end

axSPM = BigAx1;
end
