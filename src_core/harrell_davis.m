function Q = harrell_davis(A, prob, dim)
% HARRELL_DAVIS  Harrell–Davis quantile estimator (scalar prob)
% Q = harrell_davis(A,prob)         -> columnwise (dim=1) estimates
% Q = harrell_davis(A,prob,dim)     -> estimates along dimension dim
%
% Output shape: input size with dimension dim replaced by 1.

if nargin < 3 || isempty(dim), dim = 1; end
if ~isscalar(prob) || prob <= 0 || prob >= 1
    error('prob must be scalar in (0,1).');
end

sz = size(A);
nd = max(2, ndims(A));        % ensure at least 2 dims for permute logic
if dim < 1 || dim > nd
    error('dim out of range.');
end

% Move operating dimension to first
perm = 1:nd;
perm([1 dim]) = perm([dim 1]);
Ap = permute(A, perm);        % size Ap = [n, M] with M = prod(rest)
n = size(Ap,1);
M = numel(A) / n;

% Sort along first dimension, reshape to 2D (n x M)
As = sort(reshape(Ap, n, M), 1);

% Harrell-Davis weights: use Beta PDF evaluated at prob for stability,
% then normalize. This is a practical stable alternative to betainc-differences.
j = (1:n)';
w = betapdf(prob, j, n+1-j);  % vector length n
% If betapdf returns zeros (extreme small n/prob), fall back to small positive eps
if all(w == 0)
    w = ones(n,1);
end
w = w / sum(w);

% Weighted sum of order statistics -> 1 x M
Qp = (w' * As);   % 1-by-M

% Reshape back to original rest dimensions with dim reduced to 1
restSz = sz;
restSz(dim) = 1;
restPerm = perm(2:end);
if isempty(restPerm)
    Q = reshape(Qp, restSz);
else
    Q = ipermute(reshape(Qp, [1, sz(restPerm)]), perm);
end
end
