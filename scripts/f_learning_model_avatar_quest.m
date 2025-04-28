function  [fx] = f_learning_model_avatar_quest(x, P, u, in)
% initialize output variable
fx = nan(length(x),1);

% Pull out trial number
trial_num = u(11);



% Pull out parameters from vector P
for i = 1:numel(in.evolution_params)
    field_name = in.evolution_params{i}; % Extract the field name
    params.(field_name) = P(i); % Assign the value from P
end
% Transform parameters back to native space
if exist("params", "var")
    retrans_params = transform_params_avatar_quest("untransform", params,in.evolution_params);
else
    retrans_params = [];
end
% If retrans_params does not contain a parameter that is needed (i.e.,
% a parameter not fit), add it
for f = fieldnames(in.params)'
    if ~isfield(retrans_params, f{1})
        retrans_params.(f{1}) = in.params.(f{1});
    end
end


% If start of the block
if (mod(trial_num, 12) - 1)==0
    % Assign value of left choice
    if u(1)==2
        fx(1) = fx(1) + retrans_params.money_sensitivity;
    end
    if u(1)==2
        fx(1) = fx(1) + retrans_params.control_sensitivity;
    end
    if u(1)==2
        fx(1) = fx(1) + retrans_params.difficulty2_sensitivity;
    end
    if u(1)==3
        fx(1) = fx(1) + retrans_params.difficulty3_sensitivity;
    end
end



