function ResultsTable = comparePopulationCalibrationCutoffs(p, nu, conflev, n_vec, B_cal, B_eval)
% ABC_CHECK_CORE  Core simulation for quantile-estimation bias (no plotting)
%
% Inputs:
%   p, nu      Dimension and Student-t degrees of freedom
%   conflev    Nominal confidence level, for example 0.95
%   n_vec      Vector of sample sizes to evaluate
%   B_cal      Number of calibration replications
%   B_eval     Number of evaluation replications
%
% Output:
%   ResultsTable  Table with columns:
%                 - n
%                 - sizeRatio_true
%                 - sizeRatio_pooled
%                 - sizeRatio_avg
%                 - sizeRatio_repwise
%                 - q_avg_over_q_true
%
% Purpose:
%   Simulate squared distances drawn exactly from the known population
%   distribution, without MCD estimation, and compare four cutoff rules:
%     - exact population cutoff
%     - pooled calibration quantile
%     - average of replication-wise calibration quantiles
%     - replication-wise paired test
%
%   For each n in n_vec, the simulation:
%     1. generates B_cal calibration samples and B_eval evaluation samples
%     2. computes the three calibration constructions
%     3. evaluates empirical rejection probabilities
%     4. returns size ratios relative to the nominal size 1 - conflev

%{
    % EXAMPLE 

    clear; clc; close all
    p        = 5;
    nu       = 3;
    conflev  = 0.95;
    n_vec    = 50:10:500;
    B_cal    = 5000;    
    B_eval   = 5000;    
    
    seed     = 20260901;
    rng(seed,'twister');
    
    addpath(fullfile(projectRoot, 'src_core'));

    ResultsTable = comparePopulationCalibrationCutoffs(p, nu, conflev, n_vec, B_cal, B_eval);
    
    set(groot,'DefaultFigureWindowStyle','normal');  
    set(groot,'defaultTextInterpreter','latex');
    set(groot,'defaultAxesTickLabelInterpreter','latex');
    set(groot,'defaultLegendInterpreter','latex');
    fs = 14;
    set(groot,'defaultAxesFontSize',fs,'defaultTextFontSize',fs,'defaultLegendFontSize',fs);
    
    colTrue   = [0.40 0.40 0.40];        % grey
    colPooled = [0.0000 0.4470 0.7410];  % blue
    colAvg    = [0.8500 0.3250 0.0980];  % orange
    colRep    = [0.4940 0.1840 0.5560];  % purple
    
    figure('Name','MCD-free demonstration: quantile-estimation bias');
    hold on
    plot(n_vec, ResultsTable.sizeRatio_true,    '-o', 'Color',colTrue,   'LineWidth',2,'MarkerSize',6, 'DisplayName','true cutoff (exact, no estimation)');
    plot(n_vec, ResultsTable.sizeRatio_pooled,  '--s','Color',colPooled, 'LineWidth',2,'MarkerSize',6, 'DisplayName','pooled calibration (A)');
    plot(n_vec, ResultsTable.sizeRatio_avg,     '-.o','Color',colAvg,    'LineWidth',2,'MarkerSize',6, 'DisplayName','Eq.\ (14)--(15) / average calibration (B)');
    plot(n_vec, ResultsTable.sizeRatio_repwise, ':d', 'Color',colRep,    'LineWidth',2,'MarkerSize',6, 'DisplayName','replication-wise calibration (C)');
    yline(1,'k:','HandleVisibility','off');
    %set(gca,'XScale','log');
    xlabel('$n$'); 
    ylabel('empirical size / nominal size');
    title(sprintf('Empirical size, $p=%d$, $\\nu=%d$ (no MCD, no scatter estimation)',p,nu));
    legend('Location','best')

%}

% "midpoint"    — Midpoint algorithm that uses sorting.
% "inclusive"   — Algorithm that uses sorting and includes the 0th and 1st quantiles within the bounds of the data. (since R2025a)
% "exclusive"   — Algorithm that uses sorting and excludes the 0th and 1st quantiles from the bounds of the data. (since R2025a)
% "approximate" — Calculate approximate quantiles with an algorithm that uses T-Digest for a double or single input array.

q_method = 'inclusive'; % 'inclusive' / 'exclusive' / 'midpoint' / 'approximate' / 'HarrellDavis'
%q_method = 'HarrellDavis';

nominal_size = 1 - conflev;

% exact closed-form cutoff on squared-distance scale (Eq. (12))
q2_true = (nu-2) * (1 ./ betainv(1-conflev, p/2, nu/2) - 1);

nN = numel(n_vec);
sizeRatio_true    = nan(nN,1);
sizeRatio_pooled  = nan(nN,1);
sizeRatio_avg     = nan(nN,1);
sizeRatio_repwise = nan(nN,1);
qAvgOverTrue      = nan(nN,1);

for k = 1:nN
    n = n_vec(k);

    % Draw exact squared distances from population distribution:
    % D^2 = (nu-2) * (1 / Beta(p/2,nu/2) - 1)
    D2 = (nu-2) .* (1 ./ betarnd(p/2, nu/2, n, B_cal + B_eval) - 1);

    % Split calibration / evaluation sets
    calIdx  = 1:B_cal;
    evalIdx = B_cal + (1:B_eval);
    D2cal   = D2(:, calIdx);
    D2eval  = D2(:, evalIdx);

    % Option A: pooled calibration quantile (from all calibration draws)
    if strcmp(q_method,'HarrellDavis')
       q_pooled_sq = harrell_davis(D2cal(:), conflev, 1);  % returns 1 x B_cal -> transpose to B_cal x 1
    else
       q_pooled_sq = quantile(D2cal(:), conflev, Method=q_method);
    end

    % Option B: per-rep quantiles, then average (Eq. 14-15)
    if strcmp(q_method,'HarrellDavis')
        perRepQ_sq = squeeze(harrell_davis(D2cal, conflev, 1));  % returns 1 x B_cal -> transpose to B_cal x 1
        perRepQ_sq = perRepQ_sq(:);                              % returns B_cal-by-1
    else
        perRepQ_sq = quantile(D2cal, conflev, 1, Method=q_method)'; % B_cal x 1
    end

    q_avg_sq   = mean(perRepQ_sq);

    % Option C: replication-wise paired test outcomes
    Bpaired = min(B_cal, B_eval);
    passRepwise = false(n, Bpaired);
    for b = 1:Bpaired
        passRepwise(:,b) = D2eval(:,b) > perRepQ_sq(b);
    end

    % Evaluate empirical rejection probabilities on evaluation set
    sizeRatio_true(k)    = mean(D2eval(:) > q2_true)     / nominal_size;
    sizeRatio_pooled(k)  = mean(D2eval(:) > q_pooled_sq) / nominal_size;
    sizeRatio_avg(k)     = mean(D2eval(:) > q_avg_sq)    / nominal_size;
    sizeRatio_repwise(k) = mean(passRepwise(:))          / nominal_size;

    % monitor average-of-rep-quantile relative to true cutoff
    qAvgOverTrue(k) = q_avg_sq / q2_true;

    fprintf(['n=%4d | sizeRatio: true=%.4f  pooled=%.4f  avg=%.4f  repwise=%.4f | ' ...
        'q_avg/q_true=%.4f\n'], n, sizeRatio_true(k), sizeRatio_pooled(k), ...
        sizeRatio_avg(k), sizeRatio_repwise(k), qAvgOverTrue(k));
end

% Pack results into table (no display)
ResultsTable = table(...
    n_vec(:), ...
    sizeRatio_true, ...
    sizeRatio_pooled, ...
    sizeRatio_avg, ...
    sizeRatio_repwise, ...
    qAvgOverTrue, ...
    'VariableNames', {'n','sizeRatio_true','sizeRatio_pooled','sizeRatio_avg','sizeRatio_repwise','q_avg_over_q_true'});
end
