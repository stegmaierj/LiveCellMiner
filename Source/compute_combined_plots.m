%%
% LiveCellMiner.
% Copyright (C) 2020 D. Moreno-Andres, A. Bhattacharyya, W. Antonin, J. Stegmaier
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the Liceense at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
% Please refer to the documentation for more information about the software
% as well as for installation instructions.
%
% If you use this application for your work, please cite the repository and one
% of the following publications:
%
% TBA
%
%%

%% compute the aligned heat map
currentHeatMap = callback_livecellminer_compute_aligned_heatmap(d_orgs, validIndices, synchronizationIndex, featureIndex, parameter);

%% visualize the current plate depending on the selected visualization mode
%% compute mean and std. curves 
meanCurve = nan(1, size(currentHeatMap, 2));
stdCurve = nan(1, size(currentHeatMap, 2));
stdErrCurve = nan(1, size(currentHeatMap, 2));
for i=1:size(currentHeatMap, 2)

    %% get the current valid indices
    validIndices = find(~isnan(currentHeatMap(:,i)));

    %% only compute mean and std if sufficient data points are available (here, minimum of 3 points)
    if (length(validIndices) > 2)
        meanCurve(i) = mean(currentHeatMap(validIndices, i));
        stdCurve(i) = std(currentHeatMap(validIndices, i));
        stdErrCurve(i) = stdCurve(i) / sqrt(length(validIndices));
    end
end

%% find intermediate region to suppress
invalidIndices = find(isnan(meanCurve) | isnan(stdCurve));
invalidIndicesStart = invalidIndices(invalidIndices <= IPTransition);
invalidIndicesMiddle = invalidIndices(invalidIndices > IPTransition & invalidIndices < MATransition);
invalidIndicesEnd = invalidIndices(invalidIndices >= MATransition);
if (isempty(invalidIndicesEnd))
    invalidIndicesEnd = length(meanCurve);
end
if (isempty(invalidIndicesStart))
    invalidIndicesStart = 1;
end

%% plot the lines and error bars (either completely if all data is present or piece-wise if intermediate part is missing.
if(isempty(invalidIndicesMiddle))

    %% plot the current mean curve
    plot(1:length(meanCurve), meanCurve, lineStyles{mod(currentCodeValue, 4)+1}, 'Color', colorMap(currentCodeValue, :));

    %% if enabled, plot error bars
    if (showErrorBars == true)
        errorbar(1:errorStep:length(meanCurve), meanCurve(1:errorStep:end), stdErrCurve(1:errorStep:end), '.r', 'Color', colorMap(currentCodeValue, :));
    end
else

    %% plot the current mean curve parts, skipping the intermediate void
    plot(max(invalidIndicesStart):min(invalidIndicesMiddle), meanCurve(max(invalidIndicesStart):min(invalidIndicesMiddle)), lineStyles{mod(currentCodeValue, 4)+1}, 'Color', colorMap(currentCodeValue, :));
    plot(max(invalidIndicesMiddle):min(invalidIndicesEnd), meanCurve(max(invalidIndicesMiddle):min(invalidIndicesEnd)), lineStyles{mod(currentCodeValue, 4)+1}, 'Color', colorMap(currentCodeValue, :));

    %% if enabled, plot error bars
    if (showErrorBars == true)
        errorbar(max(invalidIndicesMiddle):errorStep:min(invalidIndicesEnd), meanCurve(max(invalidIndicesMiddle):errorStep:min(invalidIndicesEnd)), stdErrCurve(max(invalidIndicesMiddle):errorStep:min(invalidIndicesEnd)), '.r', 'Color', colorMap(currentCodeValue, :));
        errorbar(max(invalidIndicesStart):errorStep:min(invalidIndicesMiddle), meanCurve(max(invalidIndicesStart):errorStep:min(invalidIndicesMiddle)), stdErrCurve(max(invalidIndicesStart):errorStep:min(invalidIndicesMiddle)), '.r', 'Color', colorMap(currentCodeValue, :));
    end
end

%% in the alignment mode, display the alignment time points
if (alignPlots == true)
    plot([IPTransition, IPTransition], [-1e10, 1e10], '--w', 'Color', markerColor, 'LineWidth', 2);
    plot([MATransition, MATransition], [-1e10, 1e10], '--w', 'Color', markerColor, 'LineWidth', 2);
end

%% compute the minimum and maximum values for proper axis scaling
maxValue = max(maxValue, max(meanCurve + stdErrCurve));
minValue = min(minValue, min(meanCurve - stdErrCurve));

%% assemble the name for the current plot entity
plotName = [zgf_y_bez(selectedOutputVariable,p).name];

%% set axis labels
if (visualizationMode ~= 1)
    %% set the axis labels
    xlabel('Frame Number');
    ylabel(strrep(kill_lz(var_bez(featureIndex,:)), '_', '\_'));
    box off;
end

plotName = strrep(plotName, '_', '\_');
if (currentCodeValue == 1)
    currentLegend = plotName;
else
    currentLegend = char(currentLegend, plotName);
end

%% optionally adjust x-axis with IP and MA relative frame numbers
if (parameter.gui.livecellminer.relativeFrameNumbers)
    callback_livecellminer_relative_frame_numbers;
end
