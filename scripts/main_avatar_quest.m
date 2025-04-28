% Avatar Quest Task

clear all;
close all;
rng(23);
dbstop if error
fitting_procedure = 'SPM';% Specify fitting procedure:SPM or VBA


if ispc
    root = 'L:';
    subject_table = readtable('L:\rsmith\lab-members\cgoldman\avatar_quest_task\subject_IDs_avatar_quest.csv'); % Specify subjects to fit; one or multiple
    subjects = subject_table.ID;
    % subjects = {'carter_test'};  % Specify subjects to fit; one or multiple
    result_dir = 'L:\rsmith\lab-members\cgoldman\avatar_quest_task\fit_results\';
    % Specify parameters to fit
    field = {'money_sensitivity', 'difficulty_sensitivity2', 'difficulty_sensitivity3','control_sensitivity', 'unchosen_bonus', 'optimism_bias','inverse_temp'};
    evolution_params = field;
    observation_params = {};
else
    root = '/media/labs';
    subject = getenv('SUBJECT')
    result_dir = getenv('RESULTS')
    field = strsplit(getenv('FIELD'), ',')
end
timestamp = datetime('now','TimeZone','local','Format','d-MMM-y_HH_mm_ss');


% Note that the VBA package is required to fit this model
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/']);
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/utils/']);
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/demos/_models/']);
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/core/']);
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/core/diagnostics/']);
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/core/display/']);
addpath([root '/rsmith/all-studies/util/VBA-toolbox-master/modules/GLM/']);

% Note that the SPM package is also required (I utilize a few helper
% functions e.g., spm_vec)
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
    
    
    if strcmp(fitting_procedure,'SPM')
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

    elseif strcmp(fitting_procedure,'VBA')
        %%VBA Fitting is still in development
        options.inF.field = field;
        options.inF.evolution_params = evolution_params;
        options.inF.observation_params = observation_params;
        options.inF.params = params;

    
        f_fname = @f_learning_model_avatar_quest;
        g_fname = @g_observation_model_avatar_quest;
        
            
        
        dim = struct( ...
            'n', 3, ... number of hidden states (expected value of money, control, difficulty2, and added value of difficulty 3)
            'n_theta', length(evolution_params), ... number of evolution parameters (1: learning rate)
            'n_phi', length(observation_params) ... number of observation parameters (1: temperature)
           );
        
        
        options.priors.muX0 = [0; 0; 0]; % prior means for the latent states (initial expected value for each option)
        
        % Transform evolution params for fitting
        [prior_means_evolution_params, prior_sigmas_evolution_params] = transform_params_avatar_quest("transform", params,evolution_params);
        options.priors.muTheta = spm_vec(prior_means_evolution_params);
        options.priors.SigmaTheta = diag(spm_vec(prior_sigmas_evolution_params)');
        
        % Transform observation params for fitting
        [prior_means_observation_params, prior_sigmas_observation_params] = transform_params_avatar_quest("transform", params,observation_params);
        options.priors.muPhi = spm_vec(prior_means_observation_params);
        options.priors.SigmaPhi = diag(spm_vec(prior_sigmas_observation_params)');
        
        options.updateX0 = 0 ; % this prevents us from fitting the initial condition
        options.sources.type = 2; % Use source 2 for fitting multinomial data
        
        % split into sessions (blocks), parameters and the initial state are carried over 
        options.multisession.split = repmat([12],1,11); 
        % By default, all parameters are duplicated for each session. However, you
        % can fix some parameters so they remain constants across sessions.
        % ame evolution parameter in both sessions
        options.multisession.fixed.theta = 'all'; % <~ uncomment for fixing theta params
        % Same observation parameter in both sessions
        options.multisession.fixed.phi = 'all'; % <~ uncomment for fixing phi params
        % Same initial state in both sessions
        options.multisession.fixed.X0 = 1:dim.n; % <~ this has no effect, but because we are not fitting X0, we will still use the same X0 across sessions
        
        [posterior, out] = VBA_NLStateSpaceModel(actions, input, f_fname, g_fname, dim, options);
    end
    


end
disp(all_fits);
filename = ['all_fits_avatar_quest_' char(timestamp) '.csv'];
filepath = fullfile(result_dir, filename);
writetable(all_fits, filepath);

