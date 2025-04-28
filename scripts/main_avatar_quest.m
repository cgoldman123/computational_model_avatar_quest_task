% main_avatar_quest.m
% =========================================================================
% DESCRIPTION:
%   Top-level script to run the full Avatar Quest pipeline.
%
% INPUTS:
%   - data/subject_IDs_avatar_quest.csv: list of subject IDs (column “ID”).
%   - data/all_3afc_conds.csv: task schedule.
%   - scripts/: supporting .m functions (process, fit, invert, model, plot).
%   - SPM12 + DEM toolbox must be on MATLAB’s path.
%
% OUTPUTS:
%   - CSV: 'all_fits_avatar_quest_<timestamp>.csv' in fit_results/.
%   - DCM MAT files and plot PNGs written under fit_results/.


% Clear all the environment variables
clear all;
% Close all the figures
close all;
% Set random number seed for reproducibility 
rng(23);
dbstop if error


if ispc
    root = 'L:'; % Set the root directory. Will have to change this to match your file system.
    subject_table = readtable('..\subject_IDs_avatar_quest.csv'); % Read in subject IDs to fit. Will have to add subject IDs to this file as more data comes in.
    subjects = subject_table.ID;
    result_dir = '..\fit_results\';
    field = {'money_sensitivity', 'difficulty_sensitivity2', 'difficulty_sensitivity3','control_sensitivity', 'unchosen_bonus', 'optimism_bias','inverse_temp'};  % Specify parameters to fit
else
    % Optional - set up script to run on an analysis cluster
end
% Get the current datetime
timestamp = datetime('now','TimeZone','local','Format','d-MMM-y_HH_mm_ss');


% Note that the SPM package is required to fit this model
% Download SPM and add the path to SPM12 and the toolbox/DEM folder. Change
% this to match where you have the package.
addpath([root '/rsmith/all-studies/util/spm12/']);
addpath([root '/rsmith/all-studies/util/spm12/toolbox/DEM/']);

% Specify priors or fixed parameter values
params.money_sensitivity = 0; % Unbounded
params.difficulty_sensitivity2 = 0; % Unbounded
params.difficulty_sensitivity3 = 0; % Unbounded
params.control_sensitivity = 0; % Unbounded
params.unchosen_bonus = 0; % Unbounded
params.optimism_bias = 0; % Log transformed
params.inverse_temp = 1;

% Initialize empty table to hold fits
all_fits = table();
% Loop through subject list and fit
for subject_idx=1:length(subjects)
    subject = subjects{subject_idx};
    try
        % Try processing behavioral file for this subject
        [actions, input] = process_behavioral_file(subject);
    catch
        % If data processing did not work for this subject, add their
        % subject ID to the dataframe with NaN values in the columns.
        fprintf('Behavioral file could not be processed for: %s\n', subject);
        % Add an empty row to the results dataframe
        new_row = array2table(nan(1, width(all_fits)), 'VariableNames', all_fits.Properties.VariableNames);
        empty_row.id = subject;
        % Append the new row to the table
        all_fits = [all_fits; new_row];
        continue;
    end
    
    settings.field = field;
    settings.params = params;
    settings.id = subject;
    settings.timestamp = timestamp;
    settings.result_dir = result_dir;
    fit_results = fit_avatar_quest(actions,input,settings);
    fit_table = struct2table(fit_results);
    fit_table = addvars(fit_table, {subject}, 'Before', 1, 'NewVariableNames', 'id');

    mf_results = model_free_avatar_quest(actions,input);
    combined_fits_and_mf = [fit_table struct2table(mf_results)];

    all_fits = [all_fits; combined_fits_and_mf]; % append computational and descriptive results to table

end
disp(all_fits);
filename = ['all_fits_avatar_quest_' char(timestamp) '.csv'];
filepath = fullfile(result_dir, filename);
writetable(all_fits, filepath); % save the table

