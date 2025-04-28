function DCM = inversion_avatar_quest(actions,input,settings)
% MDP inversion using Variational Bayes
% FORMAT [DCM] = spm_dcm_mdp(DCM)


%
% Expects:
%--------------------------------------------------------------------------
% DCM.MDP   % MDP structure specifying a generative model
% DCM.field % parameter (field) names to optimise
% DCM.U     % cell array of outcomes (stimuli)
% DCM.Y     % cell array of responses (action)
%
% Returns:
%--------------------------------------------------------------------------
% DCM.M     % generative model (DCM)
% DCM.Ep    % Conditional means (structure)
% DCM.Cp    % Conditional covariances
% DCM.F     % (negative) Free-energy bound on log evidence
% 
% This routine inverts (cell arrays of) trials specified in terms of the
% stimuli or outcomes and subsequent choices or responses. It first
% computes the prior expectations (and covariances) of the free parameters
% specified by DCM.field. These parameters are log scaling parameters that
% are applied to the fields of DCM.MDP. 
%
% If there is no learning implicit in multi-trial games, only unique trials
% (as specified by the stimuli), are used to generate (subjective)
% posteriors over choice or action. Otherwise, all trials are used in the
% order specified. The ensuing posterior probabilities over choices are
% used with the specified choices or actions to evaluate their log
% probability. This is used to optimise the MDP (hyper) parameters in
% DCM.field using variational Laplace (with numerical evaluation of the
% curvature).
%
%__________________________________________________________________________
% Copyright (C) 2005 Wellcome Trust Centre for Neuroimaging

% Karl Friston
% $Id: spm_dcm_mdp.m 7120 2017-06-20 11:30:30Z spm $

% OPTIONS
%--------------------------------------------------------------------------
ALL = false;

% prior expectations and covariance
%--------------------------------------------------------------------------
prior_variance = 1/2;

global params_old;
params_old = [];

% transform the parameters that we fit

[pE, pC_vec] = transform_params_avatar_quest("transform", settings.params,settings.field);
pC_unvec = spm_vec(pC_vec);
pC_diag      = spm_diag(pC_unvec);
pC = spm_cat(pC_diag);

% model specification
%--------------------------------------------------------------------------
M.L     = @(P,M,U,Y)spm_mdp_L(P,M,U,Y);  % log-likelihood function
M.pE    = pE;                            % prior means (parameters)
M.pC    = pC;                            % prior variance (parameters)
M.settings = settings;              % includes fixed and fitted params

% Variational Laplace
%--------------------------------------------------------------------------
[Ep,Cp,F] = spm_nlsi_Newton(M,input,actions);

% Store posterior densities and log evidnce (free energy)
%--------------------------------------------------------------------------
DCM.M   = M;
DCM.Ep  = Ep;
DCM.Cp  = Cp;
DCM.F   = F;


return

function L = spm_mdp_L(P,M,U,Y)
    global params_old;
    
    if ~isstruct(P); P = spm_unvec(P,M.pE); end

    % Re-transform parameters back to native spaces
    field = fieldnames(M.pE);

    params = transform_params_avatar_quest("untransform", P,field);


    % Check for significant parameter changes
    if ~isempty(params_old)
        any_significant_changes = false;
        for i = 1:length(field)
            f = field{i};
            if abs(params.(f) - params_old.(f)) > 0.1
                any_significant_changes = true;
                break;
            end
        end
        % Print out significant changes
        if any_significant_changes
            fprintf('\nParameter values:\n');
            for i = 1:length(field)
                f = field{i};
                fprintf('%s: %.4f\n', f, params.(f));
            end
            fprintf('\n');
        end
    end
    % Update params_old for next comparison
    params_old = params;

    simulate = 0;
    model_output = model_SPM_avatar_quest(params,Y, U, M.settings,simulate);
    log_probs = log(model_output.action_probs+eps);
    L = sum(log_probs);
    


fprintf('LL: %f \n',L)


