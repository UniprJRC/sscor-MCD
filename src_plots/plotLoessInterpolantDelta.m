function hf_delta = plotLoessInterpolantDelta(T_delta, pSel, nuSel)
%% ========================================================================
% plotLoessInterpolantDelta
% ========================================================================
%
% Plot the delta LOESS surface for one (p, nu) slice.
%
% This function is the delta-only counterpart of plotLoessInterpolants.m.
% It receives the already loaded table T_delta and builds the surface used
% in the interpolation diagnostics.
%
% Inputs:
%   T_delta  table with columns: p, nu, n, alpha0, loess
%   pSel     selected dimension
%   nuSel    selected degrees of freedom
%
% Output:
%   hf_delta figure handle
%% ========================================================================

requiredVars = {'p', 'nu', 'n', 'alpha0', 'loess'};
missingVars = setdiff(requiredVars, T_delta.Properties.VariableNames);
if ~isempty(missingVars)
    error('plotLoessInterpolantDelta:missingVariables', ...
        'T_delta is missing: %s', strjoin(missingVars, ', '));
end

sel = T_delta.p == pSel & T_delta.nu == nuSel;
S = T_delta(sel, :);

if isempty(S)
    error('No delta data found for p=%d, nu=%d.', pSel, nuSel);
end

nVals = unique(S.n, 'sorted');
aVals = unique(S.alpha0, 'sorted');

Z = nan(numel(aVals), numel(nVals));
[~, in] = ismember(S.n, nVals);
[~, ia] = ismember(S.alpha0, aVals);
Z(sub2ind(size(Z), ia, in)) = S.loess;

hf_delta = figure('Name', sprintf('delta_hat LOESS surface: p=%d, nu=%d', ...
    pSel, nuSel));

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
end
