function mf_results = model_free_avatar_quest(actions,input)
    % Determine the number of played trials
    num_trials = size(actions, 2);
    % Get the chosen option for each trial. Since actions is one-hot, the max gives the chosen row.
    [~, chosenOptions] = max(actions, [], 1);
    
    % Extract money levels for each option for played trials.
    % Row 1 for option 1, row 4 for option 2, and row 7 for option 3.
    money = input([1, 4, 7], 1:num_trials);
    % Identify trials where money is variable (not all options have the same money level)
    varTrials = find(~( (money(1,:) == money(2,:)) & (money(1,:) == money(3,:)) ));

    
    % For the variable-money trials, extract the money level of the chosen option.
    % Use sub2ind to index into the money matrix.
    chosen_money = money(sub2ind(size(money), chosenOptions(varTrials), varTrials));
    
    % Calculate the ratio of trials where the chosen money value equals 2.
    money_ratio = sum(chosen_money == 2) / numel(varTrials);

    % Extract control levels for each option for played trials.
    % Row 2 for option 1, row 5 for option 2, and row 8 for option 3.
    control = input([2, 5, 8], 1:num_trials);
    % Identify trials where money is variable (not all options have the same money level)
    varTrials = find(~((control(1,:) == control(2,:)) & (control(1,:) == control(3,:)) ));
    
    % For the control-money trials, extract the control level of the chosen option.
    % Use sub2ind to index into the control matrix.
    chosen_control = control(sub2ind(size(control), chosenOptions(varTrials), varTrials));
    
    % Calculate the ratio of trials where the chosen control value equals 2.
    control_ratio = sum(chosen_control == 2) / numel(varTrials);



    % Extract diff levels for each option for played trials.
    % Row 3 for option 1, row 6 for option 2, and row 9 for option 3.
    difficulty = input([3, 6, 9], 1:num_trials);
    % Identify trials where money is variable (not all options have the same money level)
    varTrials = find(~( (difficulty(1,:) == difficulty(2,:)) & (difficulty(1,:) == difficulty(3,:)) ));
    
    % For the variable-money trials, extract the money level of the chosen option.
    % Use sub2ind to index into the money matrix.
    chosen_diff = difficulty(sub2ind(size(difficulty), chosenOptions(varTrials), varTrials));
    
    % Calculate the ratio of trials where the chosen money value equals 2.
    diff2_ratio = sum(chosen_diff == 2) / numel(varTrials);
    % Calculate the ratio of trials where the chosen money value equals 3.
    diff3_ratio = sum(chosen_diff == 3) / numel(varTrials);

    mf_results.money_ratio= money_ratio;
    mf_results.control_ratio = control_ratio;
    mf_results.diff2_ratio = diff2_ratio;
    mf_results.diff3_ratio = diff3_ratio;
    
end