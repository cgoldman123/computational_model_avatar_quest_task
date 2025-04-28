# Avatar Quest Task Repository of Modeling and Analysis Code

**This repository provides a complete MATLAB and R pipeline for preprocessing, computational modeling, and analysis of behavioral data from the Avatar Quest Task. Use the main script (scripts/main_avatar_quest.m) to fit the data!**  
**Note:** SPM12 (with the DEM toolbox) is required to run the DCM inversion scripts.

- **subject_IDs_avatar_quest.csv**  
  List of participant Prolific IDs to include when running the pipeline.  
- **all_3afc_conds.csv**  
  Master 3-AFC task schedule

## Data
**This folder contains raw data from the Avatar Quest Task.**

## Scripts
1. **scripts/add_subject_id_to_beh_filename.m**  
   Renames raw behavioral files by prepending the subject’s Prolific ID (reads the `participant` column and renames each file).
2. **scripts/main_avatar_quest.m**  
   Orchestrates the full pipeline: loops over each subject ID, calls preprocessing, fits both the DCM (SPM12) and model-free routines, and saves results and plots.
3. **scripts/process_behavioral_file.m**  
   Loads the most recent behavioral file for a subject, extracts choice actions, and reshapes the task schedule into the `actions` and `input` matrices.
4. **scripts/fit_avatar_quest.m**  
   Takes `actions`/`input`, runs the variational inversion, transforms parameters, computes fit metrics, generates recoverability simulations, and saves a summary table and plot.
5. **scripts/inversion_avatar_quest.m**  
   Wraps SPM12’s fitting routines to perform Variational Laplace inversion (calls `spm_nlsi_Newton`, returns posterior means and covariances for free parameters).
6. **scripts/model_SPM_avatar_quest.m**  
   Implements the computational model: given parameters, computes trial-by-trial action probability distributions for computing data likelihood.
7. **scripts/model_free_avatar_quest.m**  
   Calculates simple model-free metrics (choice ratios for money, control, and difficulty trials) from the `actions` and `input` matrices.
8. **scripts/plot_avatar_quest.m**  
   Visualizes action-probability heatmaps and overlays actual choices across blocks for each participant.

## Analysis
- **analysis/avatar_quest_analysis.Rmd**  
  R Markdown script for downstream data analysis: reads fitted results, generates summary figures, and performs statistical tests.

## Output
- **fit_results/**  
  Contains CSVs of fitting results for all subjects (files named `all_fits_*`), plus DCM MAT files and diagnostic plots for individual fits.
