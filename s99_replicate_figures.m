projectRoot = '.';
addpath(fullfile(projectRoot, 'src_srep'));
addpath(fullfile(projectRoot, 'src_core'));
addpath(fullfile(projectRoot, 'src_plots'));


%% Figure 1

filename = fullfile(projectRoot, "out_article", ...
    "BiasDet_table_mean_root.csv");
T_mean_root = readtable(filename);

T_root_mean_cov = [];
p = 5; alpha0Plot = 0.5; nuFilter   = 3;
hf = plotDeterminantBiasDiagnostics(T_mean_root, T_root_mean_cov, p, alpha0Plot,nuFilter);


%% Figure 2


