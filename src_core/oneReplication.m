function [detRoot, covMat] = oneReplication(n, p, nu, alpha0, conflev, SigmaTrueInv)
% ONEREPLICATION  One Monte Carlo replication for determinant-bias estimation
%
% Generates one Student-t sample, computes the MCD covariance estimate,
% and returns the p-th root of the determinant ratio relative to the
% reference covariance.
%
% Inputs:
%   n, p, nu       Sample size, dimension, and Student-t degrees of freedom
%   alpha0         Trimming proportion passed to `mcd`
%   conflev        Confidence level passed to `mcd`
%   SigmaTrueInv    Inverse of the reference covariance used for scaling
%
% Outputs:
%   detRoot        p-th root of det(covMat * SigmaTrueInv)
%   covMat         MCD covariance estimate for the replication

X = randn(n, p) .* sqrt(nu ./ chi2rnd(nu, n, 1));

RAW = mcd(X, ...
    'modelT', nu, ...
    'bdp', alpha0, ...
    'conflev', conflev, ...
    'smallsamplecor', false, ...
    'nsamp', 500, ...
    'refsteps', 10, ...
    'plots', 0, ...
    'msg', 0, ...
    'nocheck', 1);

covMat = RAW.cov;
detRoot = det(covMat * SigmaTrueInv)^(1 / p);
end
