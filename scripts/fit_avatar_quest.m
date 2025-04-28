function fit_results = fit_avatar_quest(actions,input,settings)

    DCM = inversion_avatar_quest(actions,input,settings);

    % Retransform params
    field = settings.field;
    % get fitted and fixed params
    fit_results.num_trials_performed = length(actions);
    params = transform_params_avatar_quest("untransform", DCM.Ep,field);

    simulate = 0;
    model_output = model_SPM_avatar_quest(params,actions, input, settings,simulate);
    fit_results.average_action_prob = mean(model_output.action_probs);
    fit_results.model_acc = sum(model_output.action_probs > .5)/length(model_output.action_probs);
    for i=1:length(field)
        fit_results.(field{i}) = params.(field{i}); % load in posterior param
        fit_results.(['prior_' field{i}]) = settings.params.(field{i}); % load in prior param
        
    end

    plot_avatar_quest(params,actions,input,model_output);
    plot_file = fullfile(settings.result_dir, sprintf('plot_%s_%s.png', settings.id, settings.timestamp));
    saveas(gcf, plot_file);

    % Simulate parameters for recoverability
    simulate = 1;
    actions = zeros(3,132);
    simmed_model_output = model_SPM_avatar_quest(params,actions, input, settings,simulate);
    simfit_DCM = inversion_avatar_quest(simmed_model_output.simmed_actions,input,settings);
    % Re-transform sim-fitted params
    simfit_params = transform_params_avatar_quest("untransform", simfit_DCM.Ep,field);
    for i=1:length(field)
        fit_results.(['simfit_' field{i}]) = simfit_params.(field{i});
    end

    DCMs = {DCM, simfit_DCM}; 
    mat_file  = fullfile(settings.result_dir, sprintf('DCMs_%s_%s.mat', settings.id, settings.timestamp));
    save(mat_file, 'DCMs');

end