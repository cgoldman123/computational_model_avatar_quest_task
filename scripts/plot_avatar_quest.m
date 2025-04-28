function plot_avatar_quest(params, actions, input, model_output)
% plot_avatar_quest.m
% =========================================================================
% DESCRIPTION:
%   Visualize action-probability heatmaps and overlay actual choices.
%
% INPUTS:
%   - params (struct): model parameters (for title or annotations).
%   - actions (3×N double): actual choice data.
%   - input (9×N double): task schedule for annotations.
%   - model_output (struct) with action_prob_distribution (3×N).
%
% OUTPUTS:
%   - Figure displayed showing probability heatmap by block + choice markers.
%   - Darker shading indicates that the choices were more probable under the model.

    % Determine number of trials and blocks.
    nTrials = size(actions, 2);
    nBlocks = ceil(nTrials / 12);
    
    % Create a matrix to hold the probability values for plotting.
    % Each block has 3 rows and 12 columns.
    plotMatrix = nan(nBlocks*3, 12);
    
    % Fill plotMatrix with the action probability distribution values.
    for trial = 1:nTrials
        block = floor((trial - 1) / 12) + 1;
        trialInBlock = mod(trial - 1, 12) + 1;
        for option = 1:3
            rowIndex = (block - 1)*3 + option;
            plotMatrix(rowIndex, trialInBlock) = model_output.action_prob_distribution(option, trial);
        end
    end

    % Create a skinny figure with a custom figure size.
    figure('Position', [100, 100, 1200, 600]);
    imagesc(plotMatrix);
    colormap(flipud(gray));  % 1 becomes black, 0 becomes white.
    colorbar;
    
    % Ensure that cell centers align with integer ticks.
    axis equal tight;
    set(gca, 'YDir', 'reverse');  % Block 1 at the top.
    
    hold on;
    
    % Overlay a dot for each trial at the chosen action location.
    for trial = 1:nTrials
        block = floor((trial - 1) / 12) + 1;
        trialInBlock = mod(trial - 1, 12) + 1;
        chosenOption = find(actions(:, trial));
        if isempty(chosenOption)
            continue;
        end
        rowIndex = (block - 1)*3 + chosenOption;
        plot(trialInBlock, rowIndex, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
    end
    
    % Draw horizontal lines between blocks.
    for block = 1:(nBlocks-1)
        y = block * 3 + 0.5;
        plot([0.5, 12.5], [y, y], 'k-', 'LineWidth', 2);
    end
    
    % Set x-axis ticks to indicate trial numbers within a block.
    set(gca, 'XTick', 1:12);
    xlabel('Trial in Block');
    
    % Set y-axis ticks to the center of each block and label with block numbers.
    % y_ticks = ((1:nBlocks)-1)*3 + 2;
    % set(gca, 'YTick', y_ticks, 'YTickLabel', 1:nBlocks);
    set(gca, 'YTick', []);
    % ylabel('Block Number');
    
    % Add a title with a subtitle explaining the abbreviations.
    title({'Avatar Quest: Action Probabilities and Choices per Block', ...
           'M: Money, C: Control, D: Difficulty'});
    
    % Annotate each row with the input levels.
    % For each block, use the first trial of that block (since within-block input is constant)
    % Place these annotations further left by using an x-coordinate of -0.1 (and disable clipping).
    for block = 1:nBlocks
        trialIdx = (block - 1)*12 + 1; % first trial of the block
        
        % Option 1 annotation (input rows 1,2,3)
        money   = input(1, trialIdx);
        control = input(2, trialIdx);
        diff    = input(3, trialIdx);
        annotationStr = sprintf('M=%d, C=%d, D=%d', money, control, diff);
        text(-0.1, (block-1)*3 + 1, annotationStr, 'HorizontalAlignment', 'right', ...
             'VerticalAlignment', 'middle', 'FontSize', 10, 'Color', 'b', 'Clipping', 'off');
         
        % Option 2 annotation (input rows 4,5,6)
        money   = input(4, trialIdx);
        control = input(5, trialIdx);
        diff    = input(6, trialIdx);
        annotationStr = sprintf('M=%d, C=%d, D=%d', money, control, diff);
        text(-0.1, (block-1)*3 + 2, annotationStr, 'HorizontalAlignment', 'right', ...
             'VerticalAlignment', 'middle', 'FontSize', 10, 'Color', 'b', 'Clipping', 'off');
         
        % Option 3 annotation (input rows 7,8,9)
        money   = input(7, trialIdx);
        control = input(8, trialIdx);
        diff    = input(9, trialIdx);
        annotationStr = sprintf('M=%d, C=%d, D=%d', money, control, diff);
        text(-0.1, (block-1)*3 + 3, annotationStr, 'HorizontalAlignment', 'right', ...
             'VerticalAlignment', 'middle', 'FontSize', 10, 'Color', 'b', 'Clipping', 'off');
    end
    
    hold off;
end
