function add_subject_id_to_beh_filename()
% add_subject_id_to_beh_filename.m
% =========================================================================
% DESCRIPTION:
%   Rename raw behavioral files by prepending each file’s Prolific ID.
%
% INPUTS:
%   - data_dir (string): path to folder containing CSVs named 
%       'avatar_quest_3AFC*' (no ID prefix).
%
% OUTPUTS:
%   - Files in data_dir are renamed to '<participantID>_avatar_quest_3AFC*.csv'.

% Remember to close all files before running script

data_dir = 'L:\rsmith\lab-members\cgoldman\avatar_quest_task\data';

% Get all files in the directory that START WITH avatar_quest_3AFC
% Since these files don't contain the prolific ID
files = dir(fullfile(data_dir, 'avatar_quest_3AFC*'));

% Loop through each file
for i = 1:length(files)
    % Full path to the file
    file_path = fullfile(data_dir, files(i).name);
    
    % Load the file (assuming it's a CSV or similar format)
    % Modify this line based on the file type you're working with
    data = readtable(file_path); 

    % Get the first entry from the 'participant' column
    participant = data.participant{1};  % Adjust this if the column name is different

    % Create the new filename
    [~, name, ext] = fileparts(files(i).name);
    new_filename = sprintf('%s_%s%s', participant, name, ext);

    % Full path for the new filename
    new_file_path = fullfile(data_dir, new_filename);

    % Rename the file
    movefile(file_path, new_file_path);
end

end