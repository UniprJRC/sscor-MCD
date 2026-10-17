function BiasDetTable = estimateBiasDetFactors(n_vec, p_vec, nu_vec, alpha0_vec, B_est, useParfor_est, saveFile, conflev)
% =========================================================================
% estimateBiasDetFactors
% =========================================================================
%
% Full call chain:
%   s01_mcdt_finite_sample_calibration.m
%       -> estimateBiasDetFactors.m
%
% Estimate the determinant-based finite-sample correction factors used by
% the MCD-t calibration workflow under multivariate Student-t data.
%
% For each combination of (n, p, nu, alpha0), the function runs a Monte
% Carlo experiment and computes:
%
%   1. mean_root:
%      the average across replications of the p-th root of the determinant
%      ratio det(covHat * SigmaTrueInv)
%
%   2. root_mean_cov:
%      the p-th root of the determinant ratio computed from the average
%      covariance matrix across replications
%
% Inputs:
%   n_vec         Vector of sample sizes
%   p_vec         Vector of dimensions
%   nu_vec        Vector of Student-t degrees of freedom
%   alpha0_vec    Vector of trimming proportions
%   B_est         Number of Monte Carlo replications per configuration
%   useParfor_est Logical flag controlling parallel execution
%   saveFile      MAT-file used to save the resulting struct and CSV tables
%   conflev       Confidence level passed to `mcd`
%
% Output:
%   BiasDetTable   Struct with two tables:
%                  - BiasDetTable.mean_root
%                  - BiasDetTable.root_mean_cov
%
% Notes:
%   - The function logs progress once per configuration.
%   - If `saveFile` is nonempty, both tables are written to disk.
%   - The simulation uses a Student-t reference covariance with
%     SigmaTrue = (nu / (nu - 2)) * I_p.
% =========================================================================

if nargin < 8 || isempty(conflev)
    conflev = 0.95;
end

if nargin < 7
    saveFile = '';
end

if nargin < 6 || isempty(useParfor_est)
    useParfor_est = false;
end

% Preallocate one output row per (n, p, nu, alpha0) combination.
nConfigs = numel(n_vec) * numel(p_vec) * numel(nu_vec) * numel(alpha0_vec);

alpha0Out = nan(nConfigs, 1);
nOut      = nan(nConfigs, 1);
pOut      = nan(nConfigs, 1);
nuOut     = nan(nConfigs, 1);

biasMeanRootOut    = nan(nConfigs, 1);
biasRootMeanCovOut = nan(nConfigs, 1);

cfg = 0;

for ip = 1:numel(p_vec)
    p = p_vec(ip);

    for iu = 1:numel(nu_vec)
        nu = nu_vec(iu);

        % Reference covariance under the multivariate t model.
        % For Student-t data with df nu, the covariance is proportional to I_p.
        %SigmaTrue    = (nu/(nu-2)) * eye(p);   % matches paper's simulation design (§4.1)
        %SigmaTrueInv = inv(SigmaTrue);
        SigmaTrueInv = ((nu - 2) / nu) * eye(p);

        for ia = 1:numel(alpha0_vec)
            alpha0 = alpha0_vec(ia);

            for in = 1:numel(n_vec)
                n = n_vec(in);
                cfg = cfg + 1;

                % Estimate both bias-determinant constructions for this setting.
                [biasMeanRoot, biasRootMeanCov] = estimateOneConfiguration( ...
                    n, p, nu, alpha0, B_est, useParfor_est, conflev, SigmaTrueInv);

                alpha0Out(cfg) = alpha0;
                nOut(cfg)      = n;
                pOut(cfg)      = p;
                nuOut(cfg)     = nu;

                biasMeanRootOut(cfg)    = biasMeanRoot;
                biasRootMeanCovOut(cfg) = biasRootMeanCov;

                fprintf(['Estimated BiasDet for n=%d p=%d nu=%d alpha0=%.3g: ' ...
                    'mean_root=%.6g root_mean_cov=%.6g\n'], ...
                    n, p, nu, alpha0, biasMeanRoot, biasRootMeanCov);
            end
        end
    end
end

% Build the table for the mean-of-root construction.
BiasDetTable_meanroot = table( ...
    alpha0Out, nOut, pOut, nuOut, biasMeanRootOut, ...
    'VariableNames', {'alpha0', 'n', 'p', 'nu', 'BiasDet'});

% Build the table for the root-of-mean-covariance construction.
BiasDetTable_rootmeancov = table( ...
    alpha0Out, nOut, pOut, nuOut, biasRootMeanCovOut, ...
    'VariableNames', {'alpha0', 'n', 'p', 'nu', 'BiasDet'});

% Package both tables in a single struct for downstream use.
BiasDetTable = struct();
BiasDetTable.mean_root = BiasDetTable_meanroot;
BiasDetTable.root_mean_cov = BiasDetTable_rootmeancov;

% Optionally save the results to MAT and CSV files.
if ~isempty(saveFile)
    save(saveFile, 'BiasDetTable', '-v7.3');

    [saveFolder, saveBase] = fileparts(saveFile);
    writetable(BiasDetTable_meanroot, ...
        fullfile(saveFolder, [saveBase '_mean_root.csv']));
    writetable(BiasDetTable_rootmeancov, ...
        fullfile(saveFolder, [saveBase '_root_mean_cov.csv']));
end

end

function [biasMeanRoot, biasRootMeanCov] = estimateOneConfiguration( ...
    n, p, nu, alpha0, B_est, useParfor_est, conflev, SigmaTrueInv)

detRootVals = nan(B_est, 1);
covSum = zeros(p, p);

if useParfor_est
    parfor b = 1:B_est
        [detRootVals(b), covMat] = oneReplication( ...
            n, p, nu, alpha0, conflev, SigmaTrueInv);
        covSum = covSum + covMat;
    end
else
    for b = 1:B_est
        [detRootVals(b), covMat] = oneReplication( ...
            n, p, nu, alpha0, conflev, SigmaTrueInv);
        covSum = covSum + covMat;
    end
end

biasMeanRoot = mean(detRootVals);

SigmaMean = covSum / B_est;
biasRootMeanCov = det(SigmaMean * SigmaTrueInv)^(1 / p);

end

%{

    function [biasMeanRoot, biasRootMeanCov] = estimateOneConfiguration( ...
        n, p, nu, alpha0, B_est, useParfor_est, conflev, SigmaTrueInv)
    
    % Store one value per Monte Carlo replication.
    detRootVals = nan(B_est, 1);
    covCells    = cell(B_est, 1);
    
    if useParfor_est
        % Parallel replication loop: collect results only, no logging here.
        parfor b = 1:B_est
            [detRootVals(b), covCells{b}] = oneReplication( ...
                n, p, nu, alpha0, conflev, SigmaTrueInv);
        end
    else
        % Serial fallback: same computation, no per-replication progress output.
        for b = 1:B_est
            [detRootVals(b), covCells{b}] = oneReplication( ...
                n, p, nu, alpha0, conflev, SigmaTrueInv);
        end
    end
    
    % Average of the replication-wise determinant ratios.
    biasMeanRoot = mean(detRootVals);
    
    % Average covariance across replications, then take determinant ratio.
    SigmaMean = zeros(p, p);
    for b = 1:B_est
        SigmaMean = SigmaMean + covCells{b};
    end
    SigmaMean = SigmaMean / B_est;
    
    biasRootMeanCov = det(SigmaMean * SigmaTrueInv)^(1 / p);
    
    end

%}
