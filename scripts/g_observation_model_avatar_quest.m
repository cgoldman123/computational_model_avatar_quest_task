function  [gx] = g_observation_model_avatar_quest(x, P, u, in)    
    % Pull out parameters from vector P
    for i = 1:numel(in.MDP.observation_params)
        field_name = in.MDP.observation_params{i}; % Extract the field name
        params.(field_name) = P(i); % Assign the value from P
    end
    % Transform parameters back to native space
    if exist("params","var")
        retrans_params = transform_params_SM("untransform", params,in.MDP.observation_params); 
    else
        retrans_params = [];
    end
    % If retrans_params does not contain a parameter that is needed (i.e.,
    % a parameter not fit), add it
    for f = fieldnames(in.MDP.params)'
        if ~isfield(retrans_params, f{1})
            retrans_params.(f{1}) = in.MDP.params.(f{1});
        end
    end



        

                

