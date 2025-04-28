function model_output = model_SPM_avatar_quest(params,actions, input, settings,simulate)
    % Computational model for the Avatar Quest Task

    % Initialize variable to store the probability that the model assigns to
    % each choice
    num_trials = size(actions,2);
    action_probs = nan(1,num_trials);
    action_prob_distribution = nan(3,num_trials);

    % actions: 3x132 double. Each column corresponds to a trial (will have less columns if participant did not
    % finish the game). 
    % One-hot vector where a one in row 1, 2, or 3 indicates that the left,
    % middle, or right option was chosen.


    % input: 11x132 double. Each column corresponds to a trial.
    % Row 1: Money level for the left option
    % Row 2: Control level for the left option
    % Row 3: Difficulty level for the left option
    % Row 4: Money level for the middle option
    % Row 5: Control level for the middle option
    % Row 6: Difficulty level for the middle option
    % Row 7: Money level for the right option
    % Row 8: Control level for the right option
    % Row 9: Difficulty level for the right option
    % Row 10: Placeholder
    % Row 11: Trial number



    % Initialize an array of 0s to track which combinations have been
    % previously seen
    % First dimension: No Money, Money
    % Second dimension: No Control (brainslug), Control
    % Third dimension: Difficulty1, Difficulty2, Difficulty3
    trial_types_observed = nan(2,2,3); 

    % Loop through each block
    for (block_num=1:11)
        % Initialize a counter to store the last time chosen each option
        last_chosen_left = 0;
        last_chosen_middle = 0;
        last_chosen_right = 0;
        % Loop through trials within a block
        for (trial_num=1:12)
            % Get trial number within the game
            trial_index = (block_num*12) - 12 + trial_num;
            % If the trial index is greater than the trials the subject
            % performed, exit the loop
            if trial_index > num_trials
                break;
            end


            % Get input for that trial
            trial_input = input(:,trial_index);
            % If you have observed this trial type for left, carry over learning 
            if ~isnan(trial_types_observed(trial_input(1),trial_input(2),trial_input(3)))
                left_exp_val = trial_types_observed(trial_input(1),trial_input(2),trial_input(3));
            else
                left_exp_val = params.optimism_bias;
            end
            % If you have observed this trial type for middle, carry over learning 
            if ~isnan(trial_types_observed(trial_input(4),trial_input(5),trial_input(6)))
                middle_exp_val = trial_types_observed(trial_input(4),trial_input(5),trial_input(6));
            else
                middle_exp_val = params.optimism_bias;
            end
            % If you have observed this trial type for right, carry over learning 
            if ~isnan(trial_types_observed(trial_input(7),trial_input(8),trial_input(9)))
                right_exp_val = trial_types_observed(trial_input(7),trial_input(8),trial_input(9));
            else
                right_exp_val = params.optimism_bias;
            end

            % Add a bonus to the unchosen options to account for bored
            % switching later in the game
            left_exp_val = left_exp_val + params.unchosen_bonus * (trial_num - (last_chosen_left+1));
            middle_exp_val = middle_exp_val + params.unchosen_bonus * (trial_num - (last_chosen_middle+1));
            right_exp_val = right_exp_val + params.unchosen_bonus * (trial_num - (last_chosen_right+1));

            % softmax over expected values to get distribution of action
            % probabilities
            action_prob_distribution(:,trial_index) = softmax_rows(params.inverse_temp * [left_exp_val middle_exp_val right_exp_val])';
            
            % SIMULATE
            if simulate
                u = rand(1,1);
               chosen_action = find(cumsum(action_prob_distribution(:,trial_index)) >= u, 1);
               actions(chosen_action,trial_index) = 1;
            else
            % FIT
            % Pull out probability that the model assigned to chosen
            % actions
                chosen_action = find(actions(:,trial_index));
                action_probs(trial_index) = action_prob_distribution(chosen_action,trial_index);
            end

            % Learn value of chosen option
            chosen_option_trial_type = trial_input((chosen_action*3 - 2):(chosen_action*3));
            chosen_action_value = 0;
            % If chosen option was a money trial
            if chosen_option_trial_type(1)==2
                chosen_action_value = chosen_action_value + params.money_sensitivity;
            end
            % If chosen option was a control trial (no brainslug)
            if chosen_option_trial_type(2)==2
                chosen_action_value = chosen_action_value + params.control_sensitivity;
            end
            % If chosen option was a difficulty2 trial, elsif difficulty3
            % trial
            if chosen_option_trial_type(3)==2
                chosen_action_value = chosen_action_value + params.difficulty_sensitivity2;
            elseif chosen_option_trial_type(3)==3
                chosen_action_value = chosen_action_value + params.difficulty_sensitivity3;
            end
            trial_types_observed(chosen_option_trial_type(1),chosen_option_trial_type(2),chosen_option_trial_type(3)) = chosen_action_value;

            % update last time chose this action
            if chosen_action ==1
                last_chosen_left = trial_num;
            elseif chosen_action ==2
                last_chosen_middle = trial_num;
            elseif chosen_action ==3
                last_chosen_right = trial_num;
            end
        end
    end

    if simulate
        model_output.simmed_actions = actions;
    else
        model_output.action_probs = action_probs;
    end
    model_output.action_prob_distribution = action_prob_distribution;



end

function matrix = softmax_rows(matrix)
    % Subtract the maximum value from each row for numerical stability
    matrix = bsxfun(@minus, matrix, max(matrix, [], 2));
    % Calculate the exponent of each element
    exponents = exp(matrix);
    % Calculate the sum of exponents for each row
    row_sums = sum(exponents, 2);
    % Divide each element by the sum of its row
    matrix = bsxfun(@rdivide, exponents, row_sums);
end