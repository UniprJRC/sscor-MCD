# sscor-MCD
Code to reproduce the figures of paper "Calibration of robust covariance estimation under heavy tails"

> **Note:** This repository contains code and instructions for replicating the results of a paper currently under peer review. Author information is intentionally omitted.

## Abstract
The Minimum Covariance Determinant (MCD) estimator is one of the most widely used high-breakdown estimators of multivariate location and scatter. Its practical success relies on suitable corrections, which remove the asymptotic and small-sample biases introduced by trimming. While explicit consistency factors are available under the multivariate normal distribution and, more recently, under multivariate Student-t models, these corrections only address the asymptotic behaviour of the estimator.

In the Gaussian case, \cite{pis+al:02} showed that the MCD also exhibits a non-negligible finite-sample bias, particularly for small sample sizes and relatively large dimensions. Such bias propagates to robust Mahalanobis distances and may affect subsequent procedures, including multivariate outlier detection and robust inference.

This paper investigates the finite-sample behaviour of the MCD estimator and of the related robust distances under multivariate Student-t distributions, a potentially relevant scenario in many application fields. Extensive Monte Carlo experiments are carried out over a broad range of sample sizes, dimensions, trimming levels and degrees of freedom. Based on these experiments, empirical correction factors are obtained and approximated by smooth functions of the sample size and trimming proportion, providing a computationally efficient calibration suitable for practical implementations to heavy-tailed data. The proposed corrections are developed and made available both for the scatter bias and the distance quantiles.

## Practical Impact: Unbiased Scatter Estimation and Accurate Outlier Testing

In finite samples, asymptotic consistency corrections alone are insufficient: they underestimate scatter and render standard outlier tests overly liberal, resulting in substantial rates of false alarms on heavy-tailed data. To solve this, this repository delivers practical finite-sample tools that (i) remove the systematic bias in the MCD scatter matrix via determinant-based correction factors $\hat{\delta}_n$, and (ii) provide calibrated cutoffs for squared robust distances that strictly control the empirical false-positive rate. Through precomputed calibration tables and smooth interpolation functions, practitioners can instantly apply accurate corrections to any combination of sample size $n$, dimension $p$, degrees of freedom $\nu$, and trimming proportion $\alpha_0$ in real-time, eliminating the need for expensive simulation studies.

## Integration in the mcd.m function of FSDA
The final interpolation results produced by an extended application of `s01` and `s02` are intended to support a future extension of FSDA’s `mcd.m` function. In particular, the precomputed small-sample correction factors for the MCD scatter estimator and robust-distance cutoff will be embedded into `mcd.m` as an automatic calibration layer. This would allow users to apply the finite-sample correction directly to real datasets for given `n`, `p`, `nu`, and `alpha0`. In this way, the present repository provides the empirical tables and interpolation models needed to make the corrected MCD procedure available in a standard FSDA workflow. Note that, optioanlly, `nu` will be also estimated, using the algorithm discussed in Barabesi et al. (2026).

## Key Bibliography

Barabesi, L., Cerioli, A., García-Escudero, L. A., Mayo-Iscar, A., Perrotta, D., & Torti, F. (2026). Robust distances and multivariate outlier detection under heavy tails. Statistics and Computing, 36, Article 89. https://doi.org/10.1007/s11222-026-10852-6

Barabesi, L., Cerioli, A., García-Escudero, L. A., & Mayo-Iscar, A. (2023). Consistency factor for the MCD estimator at the Student-t distribution. Statistics and Computing, 33, Article 132. https://https://doi.org/10.1007/s11222-023-10296-2

Cerioli, A., Riani, M., & Atkinson, A. C. (2009). Controlling the size of multivariate outlier tests with the MCD estimator of scatter. Statistics and Computing, 19(3), 341–353. 
https://doi.org/10.1007/s11222-008-9096-5 

Pison, G., Van Aelst, S., & Willems, G. (2002). Small sample corrections for LTS and MCD. Metrika, 55(2), 111–123. 
https://doi.org/10.1007/s001840200191

## Key computational tasks

There are two main scripts needed to replicate the simulations. 

-  `s01_mcdt_finite_sample_calibration.m` runs the Monte Carlo simulation, estimates the determinant-bias corrections, calibrates the MCD robust-distance cutoff, evaluates empirical size, and writes the main calibration database. The script explicitly documents this simulation/calibration role and its split between calibration and independent evaluation samples.
-  `s02_mcdt_interpolation_analysis.m` consumes the simulation results and performs the interpolation/approximation analysis for both $\hat\delta$ and $\kappa_{RD}^{\delta}$. In doing so, it compares three interpolation methods. 
- `s99_replicate_figures.m` reproduces all figures from the saved outputs, including the application example.

## FSDA and other dependencies

The MCD estimator, which is at the core of the paper, and few other useful
functions rely on the free MATLAB Add-On *FSDA* 
(see https://it.mathworks.com/matlabcentral/fileexchange/72999-fsda-flexible-statistics-data-analysis-toolbox). 
FSDA requires the Statistical and Machine Learning Toolbox. The Parallel 
Processing Toolbox is necessary if the reader needs to replicate the estimates, 
which take lot of time otherwise.

## Results replication: requirements and setup

This repository provides the MATLAB code and the data necessary to replicate the 
main figures and tables from both the main manuscript and the supplementary 
information document. These codes can be used in two modalities: 
- 1) In a standalone MATLAB licensed installation; 
- 2) In the license-free MATLAB Online: https://it.mathworks.com/products/matlab-online.html

### To prepare your local environment 
1. Clone this repository: `git clone https://github.com/UniprJRC/sscor-MCD.git`
2. Navigate to the repository directory: `cd <your path to tdist-MCD>
3. Install FSDA from "Install App" of the standard MATLAB distribution
4. Project folders src_srep, src_core, src_plots must be on the path 

### To use MATLAB Online
The free "MATLAB Online" platform can be used up to 20 hours a month, 
which are sufficient to replicate all results except the simulation 
of the KS and AD quantiles. For this, it is sufficient to click on the
link in the table below. Once you are in the MATLAB cloud environment,
go under the "Add Ons section" of the "Home tab" and install FSDA. 

### SCRIPTS DESCRIPTION

In the following: script s01_mcdt_finite_sample_calibration.m (s01 for short) generates the calibration database, s02_mcdt_interpolation_analysis.m (s02) builds the interpolation tools, and the resulting lookup tables are used in real applications where the final sample size and trimming level are not known in advance (like in s03_application.m).

## s01_mcdt_finite_sample_calibration.m

This is the simulation of MCD Robust-Distance Calibration Under Multivariate-t.
The purpose is to reproduce the Monte Carlo calibration results reported in the paper.

The script requires the user to specify:
- Simulation grid: n_vec, p_vec, nu_vec, alpha0_vec
- Monte Carlo size: B must be even, because it is split into calibration and evaluation halves
- Confidence level: conflev
- Bias-determinant workflow: biasDetMode (estimate-and-apply for a full run)
- Quantile method: q_method

The script:
- Estimates or loads determinant-bias correction factors.
- Runs the split-sample Monte Carlo simulation over the full (n, p, nu, alpha0) grid.
- Builds the final calibration table.
- Saves results and, if enabled, diagnostic plots.

Key expected output:
- A timestamped results folder under `out_s1s2s3/calibration_YYYY-mm-dd_HHMMSS/`
- `mcd_heavytails_RD_calibration_results.mat`
- `mcd_heavytails_RD_calibration.csv`

Optional diagnostics:
- `mcd_heavytails_RD_calibration_diagnostics.csv`
- `BiasDet_table.mat`
- PNG, EPS, and FIG diagnostic plots

## s02_mcdt_interpolation_analysis.m

This script takes as input the calibration output produced by s01_mcdt_finite_sample_calibration.m and produces in output a set of interpolation summaries and lookup tables for the quantities studied in the paper.

Required input files from the s01 results folder:
- `BiasDet_table_mean_root.csv` for the Section 5.4 analysis of delta_hat = 1 / BiasDet.
- `mcd_heavytails_RD_calibration.csv` for the Section 6 analysis of kappa_RD^delta.
- The script assumes the s01 CSV files already exist in `out_s1s2s3/<calibration_folder>/`

The script:
- Loads the s01 calibration tables.
- Computes interpolation comparisons for each target quantity.
- Evaluates three methods: scattered linear, 2D LOESS, and PCHIP-in-n + linear-in-alpha0.
- Saves dense lookup tables, summary tables, and optional diagnostic plots.

Key expected output:
- A timestamped folder under `out_s1s2s3/interpolation_YYYY-mm-dd_HHMMSS/`
- Separate subfolders for delta_interpolation and RD_interpolation. In each of these subfolder the script generates CSV summary tables, a .mat   file with the processed analysis and optional plot files if producePlots = true

## s03_application.m

This demonstrates the application of the finite-sample MCD-t calibration to a real dataset, Grass, and compares the asymptotic cutoff with the calibrated cutoff.

Main inputs:
- `datasets/Grass.prn` (or, if datatype = 2, an independent synthetic Student-t sample generated inside the script)
- Interpolation outputs from s02, specifically:
    `delta_interpolation/MCDt_delta_interpolation_analysis.mat`
    `RD_interpolation/MCDt_RD_interpolation_analysis.mat`
- Model settings fixed in the script for the Grass case are: 
-- nu0 = 8
-- alpha0 = 0.50
-- conflev0 = 0.95

The script:
- Loads the data.
- Computes the raw MCD robust distances.
- Loads the calibration factors from the interpolation results.
- Compares asymptotic vs calibrated outlier classifications.
- Produces diagnostic plots.

Expected output is a robust-distance index plot showing:
- regular observations,
- calibrated outliers,
- borderline observations flagged only by the asymptotic cutoff.
- A scatterplot matrix (spmplot) with the same grouping.
The output is primarily visual but the MATLAB Command Output reports relevant statistics.


## s99_replicate_figures.m

This script reproduces all figures in the paper and supplementary material from the precomputed outputs produced by `s01`, `s02`, and `s03`.

Main inputs:
- calibration outputs from `s01_mcdt_finite_sample_calibration.m`
- interpolation outputs from `s02_mcdt_interpolation_analysis.m`
- application outputs and plotting helpers used by `s03_application.m`

The script:
- loads the saved tables and lookup data;
- calls the plotting functions used throughout the project;
- reproduces the main paper figures and appendix figures in a single run.

This is the recommended entry point when the goal is figure replication only, without rerunning the Monte Carlo simulations.


### Reproducibility workflow summary

1. Run `s01_mcdt_finite_sample_calibration.m`.
   This creates a timestamped folder in `out_s1s2s3/`, for example: `calibration_YYYY-mm-dd_HHMMSS`

2. Copy that folder name into `s02_mcdt_interpolation_analysis.m`:
   ```matlab
   calibration_folder = 'calibration_YYYY-mm-dd_HHMMSS';

3. Run `s02_mcdt_interpolation_analysis.m`.
   - This writes a new timestamped folder in `out_s1s2s3/`, for example: `interpolation_YYYY-mm-dd_HHMMSS`
   - Keep these files for later use:
     - `delta_interpolation/MCDt_delta_interpolation_analysis.mat`
     - `RD_interpolation/MCDt_RD_interpolation_analysis.mat`

4. Use the interpolated calibration in your application, like it is done in script `s03_application.m`.
   - This loads the `.mat` files produced by `s02`.
   - For a new dataset, match the observed `n`, `p`, `nu`, and `alpha0` to the stored interpolation model.
   - Evaluate the interpolated `delta_hat` and `kappa_RD^delta`, then use them to calibrate the MCD robust-distance cutoff.
   - This is the practical step that makes the calibration usable in real applications, where the final sample size, dimension, tail parameter, and trimming level are not known in advance.
   - If the requested configuration lies outside the supported range, extend the grid and rerun `s01` and `s02`.

5. To reproduce all figures directly from the saved outputs, run `s99_replicate_figures.m`.

## Simulation setting summary

We ran two simulation campaigns: a dense grid and a light grid. The dense grid was used to explore the parameter space more finely, while the light grid used a smaller but representative set of settings to reduce computation time and support the figures that only require a few key cases. 

Dense grid:
- n = 50:10:500
- p = [2 3 4 5 6 7 8]
- nu = [3 4 5 6 7 8 9 10 15 20 30]
- alpha0 = [0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]

Light grid:
- n = 50:10:500
- p = [2 5]
- nu = [3 5 7]
- alpha0 = [0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]

