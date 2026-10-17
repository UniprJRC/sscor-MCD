function hf_RD = plotLoessInterpolantRD(T_RD, pSel, nuSel, conflevSel)

%% ========================================================================
% plotLoessInterpolantRD
% ========================================================================
%
% Plot the RD LOESS surface for one (p, nu, conflev) slice.
%
% This function is the RD-only counterpart of plotLoessInterpolants.m.
% It receives the already loaded table T_RD and builds the surface used in
% the interpolation diagnostics.
%
% Inputs:
%   T_RD        table with columns: p, nu, conflev, n, alpha0, loess
%   pSel        selected dimension
%   nuSel       selected degrees of freedom
%   conflevSel  selected confidence level
%
% Output:
%   hf_RD       figure handle
%% ========================================================================

requiredVars = {'p', 'nu', 'conflev', 'n', 'alpha0', 'loess'};
missingVars = setdiff(requiredVars, T_RD.Properties.VariableNames);
if ~isempty(missingVars)
    error('plotLoessInterpolantRD:missingVariables', ...
        'T_RD is missing: %s', strjoin(missingVars, ', '));
end

sel = T_RD.p == pSel & T_RD.nu == nuSel & T_RD.conflev == conflevSel;
S = T_RD(sel, :);

if isempty(S)
    error('No RD data found for p=%d, nu=%d, conflev=%.4g.', ...
        pSel, nuSel, conflevSel);
end

nVals = unique(S.n, 'sorted');
aVals = unique(S.alpha0, 'sorted');

Z = nan(numel(aVals), numel(nVals));
[~, in] = ismember(S.n, nVals);
[~, ia] = ismember(S.alpha0, aVals);
Z(sub2ind(size(Z), ia, in)) = S.loess;

hf_RD = figure('Name', sprintf('RD LOESS surface: p=%d, nu=%d, conflev=%.2f', ...
    pSel, nuSel, conflevSel));

setfont = 20;
surf(nVals, aVals, Z, 'EdgeColor', 'none')
ax = gca;
ax.FontSize = 18;
ax.LineWidth = 0.5;
xlabel('$n$', 'Interpreter', 'latex', 'FontSize', setfont)
ylabel('$\alpha_0$', 'Interpreter', 'latex', 'FontSize', setfont)
zlabel('$\kappa_{\mathrm{RD}}^{\delta}(n,p,\nu,\alpha_0,c)$ LOESS surface', ...
    'Interpreter', 'latex', 'FontSize', setfont)
view(45, 30)
grid on
end
