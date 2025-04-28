    
function varargout = transform_params_avatar_quest(trans_or_untrans, params_struct,params_field)
    if isempty(params_field)
        params = [];
        prior_sigma = [];
    else
        prior_variance = 1/2;
        if strcmp(trans_or_untrans,"transform")
            for i = 1:length(params_field)
                field = params_field{i};
                % transform the parameters that we fit
                if ismember(field, {'money_sensitivity', 'control_sensitivity', 'difficulty_sensitivity2', 'difficulty_sensitivity3','unchosen_bonus','optimism_bias'})
                    params.(field) = params_struct.(field); 
                    prior_sigma.(field) = prior_variance;
                elseif any(strcmp(field,{'inverse_temp'})) 
                    params.(field) = log(params_struct.(field));               % in log-space (to keep positive)
                    prior_sigma.(field) = prior_variance;
                else   
                    disp(field);
                    error("Param not proparamsrly transformed");
                end
            end
        elseif strcmp(trans_or_untrans,"untransform")
            prior_sigma = [];
            for i = 1:length(params_field)
                field = params_field{i};
                if ismember(field,{'money_sensitivity', 'control_sensitivity', 'difficulty_sensitivity2', 'difficulty_sensitivity3','unchosen_bonus','optimism_bias'})
                    params.(field) = params_struct.(field);
                elseif any(strcmp(field,{'inverse_temp'}))
                    params.(field) = exp(params_struct.(field));     
                else 
                    disp(field);
                    error("Param not propertly transformed");
                end
            end
        end
    end
    varargout{1} = params;
    varargout{2} = prior_sigma;