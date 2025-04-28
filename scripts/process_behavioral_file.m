function [actions, task_schedule_reshaped] = process_behavioral_file(subject)

% process_behavioral_file.m
% =========================================================================
% DESCRIPTION:
%   Load the latest raw CSV for one subject, extract choices & schedule.
%
% INPUTS:
%   - subject (string): Prolific ID to match in 'data/*_avatar_quest_3AFC*'.
%   - data/all_3afc_conds.csv: block‐wise definitions of Money/Control/Difficulty conditions.
%
% OUTPUTS:
%   - actions (3×N double): one‐hot choice matrix (rows=options) of participant choices.
%   - task_schedule_reshaped (9×N double): Describes the trial options.
        % Each column corresponds to a trial. First three rows correspond to option
        % 1, second three rows option 2, third three rows option 3.
        % Within each row, it goes money, control, difficulty



% Define folder where data is located
folder = '..\data\';
% Get matching files
pattern = fullfile(folder, ['*' subject '_avatar_quest_3AFC*']);
files = dir(pattern);
if isempty(files), error('No matching files found.'); end

% Get most recent file
[~, idx] = max([files.datenum]);
latestFile = fullfile(folder, files(idx).name);

% Read in the file (assuming CSV format)
data = readtable(latestFile);
% Pull out relevant rows
subdat1 = data(~isnan(data.trial_num),:);
% Remove instructional trials
subdat1 = subdat1(subdat1.trial_num > 3,:);
subdat2 = data(~cellfun('isempty', data.chosen_quest),:); 

% Select columns from subdat1
subdat1_vars = {'trial_num', 'move_resp_keys', 'move_resp_rt', ...
         'time_limit', 'completion_time', 'left_right_steps', ...
         'number_of_obsticle_blocks', 'number_of_tree_blocks', 'quest_complete'};

% Select columns from subdat2
subdat2_vars = {'chosen_quest', 'unchosen_quests', ...
         'choice_resp_3afc_keys', 'choice_resp_3afc_rt'};

% Combine selected columns from both tables
newdat = [subdat1(:, subdat1_vars), subdat2(:, subdat2_vars)];

% Actions
% Pull out choices (1=left,2=middle,3=right)
choices = strcmp(newdat.choice_resp_3afc_keys, 'left') + 2*strcmp(newdat.choice_resp_3afc_keys, 'down') + 3*strcmp(newdat.choice_resp_3afc_keys, 'right');
%actions = choices';
% Turn choices into a one-hot vector
actions = zeros(3, length(choices));
actions(sub2ind(size(actions), choices', 1:length(choices))) = 1;

% Read in schedule
schedule_file = '..\all_3afc_conds.csv';
opts = detectImportOptions(schedule_file, 'Delimiter', ',');
opts.VariableNamingRule = 'preserve';  % Keep original column names like 'BlockLabel1'
schedule_data = readtable(schedule_file, opts);

% Input
% Each option is represented as a 3x3 matrix
% Columns 1, 2, and 3 correspond to left, middle, right choices
% Rows 1, 2, and 3 correspond to money, control, and difficulty modalities
% Within each row, 1=no money, 2=with money, 1=brain slug/less control,
% 2=no brain slug, 1:3 = levels of difficulty

% Initialize a 3 (modalities) x3 (option sides) x132 (trials) double
task_schedule = nan(3,3,132);
for (trial_num=1:132)
    block_num = ceil(trial_num/12);
    for option = 1:3
        option_data = schedule_data(schedule_data.blockN==block_num,:).(['BlockLabel' num2str(option)]);
        % Assign money level
        task_schedule(1,option,trial_num) = contains(option_data{1}, 'With Money') + 1;
        % Assign control level
        task_schedule(2,option,trial_num) = contains(option_data{1}, 'No Brainslug') + 1;
        % Assign difficulty level
        if contains(option_data{1}, 'No Barriers')
            task_schedule(3,option,trial_num) = 1;
        elseif contains(option_data{1}, 'Difficult 1')
            task_schedule(3,option,trial_num) = 2;
        elseif contains(option_data{1}, 'Difficult 2')
            task_schedule(3,option,trial_num) = 3;
        end
    end
end

% Turn the 3x3x132 input into 9x132
task_schedule_reshaped = reshape(task_schedule, 9, 132);
% Each column corresponds to a trial. First three rows correspond to option
% 1, second three rows option 2, third three rows option 3.
% Within each row, it goes money, control, difficulty

% add a row corresponding to trial number
task_schedule_reshaped = [task_schedule_reshaped; nan(1,132); 1:132];
end
