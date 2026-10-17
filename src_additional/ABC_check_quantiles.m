% ABC_check_quantiles
%
% Compare MATLAB quantile options on three small benchmark datasets.
% The goal is to verify how the available quantile methods differ on
% known inputs and to check consistency with the custom Harrell-Davis
% implementation used elsewhere in the project.
%
% The script evaluates three sample sizes:
%   - n = 50
%   - n = 100
%   - n = 101
%
% For each dataset it computes the 50%, 95%, and 99% quantiles using:
%   - 'inclusive'
%   - 'exclusive'
%   - 'midpoint'
%   - 'approximate'
%   - Harrell-Davis

clc;
close all;
clear all;

projectRoot = '.';
addpath(fullfile(projectRoot, '../src_core'));

% Load the three test datasets used to compare quantile definitions.
X50  = readmatrix('ABC_Check_quantiles_n50.txt');
X100 = readmatrix('ABC_Check_quantiles_n100.txt');
X101 = readmatrix('ABC_Check_quantiles_n101.txt');

q_methods = {'inclusive', 'exclusive', 'midpoint', 'approximate', 'harrell_davis'};
quantiles = {'q50', 'q95', 'q99'};

numRows = numel(quantiles);
numCols = numel(q_methods);

%% Dataset n = 50
% Compute the selected quantiles under each MATLAB method.
T = NaN(numRows, numCols);
for i = 1:numel(q_methods) - 1
    q_method = q_methods{i};
    T(1, i) = quantile(X50, 0.50, Method = q_method);
    T(2, i) = quantile(X50, 0.95, Method = q_method);
    T(3, i) = quantile(X50, 0.99, Method = q_method);
end

% Compute the Harrell-Davis quantile estimates separately.
T(1, numCols) = harrell_davis(X50, 0.50, 1);
T(2, numCols) = harrell_davis(X50, 0.95, 1);
T(3, numCols) = harrell_davis(X50, 0.99, 1);

T50 = array2table(T, 'VariableNames', q_methods, 'RowNames', quantiles);

%% Dataset n = 100
% Repeat the same comparison for the second benchmark sample.
T = NaN(numRows, numCols);
for i = 1:numel(q_methods) - 1
    q_method = q_methods{i};
    T(1, i) = quantile(X100, 0.50, Method = q_method);
    T(2, i) = quantile(X100, 0.95, Method = q_method);
    T(3, i) = quantile(X100, 0.99, Method = q_method);
end

T(1, numCols) = harrell_davis(X100, 0.50, 1);
T(2, numCols) = harrell_davis(X100, 0.95, 1);
T(3, numCols) = harrell_davis(X100, 0.99, 1);

T100 = array2table(T, 'VariableNames', q_methods, 'RowNames', quantiles);

%% Dataset n = 101
% Repeat the comparison for an odd sample size.
T = NaN(numRows, numCols);
for i = 1:numel(q_methods) - 1
    q_method = q_methods{i};
    T(1, i) = quantile(X101, 0.50, Method = q_method);
    T(2, i) = quantile(X101, 0.95, Method = q_method);
    T(3, i) = quantile(X101, 0.99, Method = q_method);
end

T(1, numCols) = harrell_davis(X101, 0.50, 1);
T(2, numCols) = harrell_davis(X101, 0.95, 1);
T(3, numCols) = harrell_davis(X101, 0.99, 1);

T101 = array2table(T, 'VariableNames', q_methods, 'RowNames', quantiles);

%% Display results
% Print the comparison tables to inspect differences between methods.
disp('n50:');
disp(T50)

disp('n100:');
disp(T100)

disp('n101:');
disp(T101)
