% Avatar Quest Task
% Clear all the environment variables
clear all;
% Close all the figures
close all;
% Set random number seed for reproducibility 
rng(23);
dbstop if error


if ispc
    root = 'L:';
    subject_table = readtable('L:\rsmith\lab-members\cgoldman\avatar_quest_task\subject_IDs_avatar_quest.csv'); % Specify subjects to fit; one or multiple
    subjects = subject_table.ID;
    % subjects = {'carter_test'};  % Specify subjects to fit; one or multiple
    result_dir = 'L:\rsmith\lab-members\cgoldman\avatar_quest_task\fit_results\';
    % Specify parameters to fit
    field = {'money_sensitivity', 'difficulty_sensitivity2', 'difficulty_sensitivity3','control_sensitivity', 'unchosen_bonus', 'optimism_bias','inverse_temp'};
else
    % Optional - set up script to run on an analysis cluster
    subject = getenv('SUBJECT')
    result_dir = getenv('RESULTS')
    field = strsplit(getenv('FIELD'), ',')
end
timestamp = datetime('now','TimeZone','local','Format','d-MMM-y_HH_mm_ss');


% Note that the SPM package is required to fit this model
% add the path to SPM12 and the toolbox/DEM folder
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

% Initialize empty tbale to hold fits
all_fits = table();
% Loop through subject list and fit
for subject_idx=1:length(subjects)
    subject = subjects{subject_idx};
    try
        [actions, input] = process_behavioral_file(subject);
    catch
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

    all_fits = [all_fits; combined_fits_and_mf]; % append row to table

end
disp(all_fits);
filename = ['all_fits_avatar_quest_' char(timestamp) '.csv'];
filepath = fullfile(result_dir, filename);
writetable(all_fits, filepath);

