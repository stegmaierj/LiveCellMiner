%%
% LiveCellMiner.
% Copyright (C) 2022 D. Moreno-Andrés, A. Bhattacharyya, J. Stegmaier
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
% D. Moreno-Andres, A. Bhattacharyya, A. Scheufen, J. Stegmaier, "LiveCellMiner: A
% New Tool to Analyze Mitotic Progression", PLOS ONE, 17(7), e0270923, 2022.
%
%%

%% compute the aligned heat map
currentHeatMap = callback_livecellminer_compute_aligned_heatmap(d_orgs, validIndices, synchronizationIndex, featureIndex, parameter);

%% create a new subplot
subplot(numRows, numColumns, currentSubPlot); hold on;

%% visualize the current plate depending on the selected visualization mode
if (visualizationMode == 1)
    imagesc(currentHeatMap);
    ylabel(kill_lz(var_bez(featureIndex,:)));

    if (alignPlots == true)
        plot([IPTransition, IPTransition], [-10000, 10000], '--k', 'LineWidth', 2);
        plot([MATransition, MATransition], [-10000, 10000], '--k', 'LineWidth', 2);
    end
    colormap(callback_livecellminer_get_colormap(parameter.gui.livecellminer.colorMap, [], parameter));
    axis tight;
    maxValue = quantile(currentHeatMap(:), 0.95);
    minValue = quantile(currentHeatMap(:), 0.05);
else

    meanCurve = nan(1, size(currentHeatMap, 2));
    stdCurve = nan(1, size(currentHeatMap, 2));
    for i=1:size(currentHeatMap, 2)
        validIndices = find(~isnan(currentHeatMap(:,i)));

        if (length(validIndices) > 2)
            meanCurve(i) = mean(currentHeatMap(validIndices, i));
            stdCurve(i) = std(currentHeatMap(validIndices, i));
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

    if(isempty(invalidIndicesMiddle))
        shadedErrorBar(1:length(meanCurve), meanCurve, stdCurve, {'-g','markerfacecolor',[0.2,1,0.2]});
    else
        shadedErrorBar(max(invalidIndicesStart):min(invalidIndicesMiddle), meanCurve(max(invalidIndicesStart):min(invalidIndicesMiddle)), stdCurve(max(invalidIndicesStart):min(invalidIndicesMiddle)), {'-g','markerfacecolor',[0.2,1,0.2]});
        shadedErrorBar(max(invalidIndicesMiddle):min(invalidIndicesEnd), meanCurve(max(invalidIndicesMiddle):min(invalidIndicesEnd)), stdCurve(max(invalidIndicesMiddle):min(invalidIndicesEnd)), {'-g','markerfacecolor',[0.2,1,0.2]});
    end

    if (alignPlots == true)
        lineStyle = '--k';
        if (darkMode == true)
            lineStyle = '--w';
        end
        plot([IPTransition, IPTransition], [-1e10, 1e10], lineStyle, 'LineWidth', 2);
        plot([MATransition, MATransition], [-1e10, 1e10], lineStyle, 'LineWidth', 2);
    end

    maxValue = max(maxValue, max(meanCurve + stdCurve));
    minValue = min(minValue, min(meanCurve - stdCurve));

    ylabel(strrep(kill_lz(var_bez(featureIndex,:)), '_', '\_'));
    box off;
end

%% add legends to the figures
if (summarizeSelectedExperiments == false)
    title(strrep([zgf_y_bez(experimentId,e).name '_' zgf_y_bez(selectedOutputVariable,p).name], '_', '\_'));
else
    title(strrep(['CombinedExperiments_' zgf_y_bez(selectedOutputVariable,p).name], '_', '\_'));
end

xlabel('Frame Number');
if (parameter.gui.livecellminer.timeInMinutes)
    xlabel('Time (min)');
end

offsetPreIP = parameter.gui.zeitreihen.segment_start-1;
offsetPostMA = parameter.gui.livecellminer.alignedLength - (size(d_orgs,2) - parameter.gui.zeitreihen.segment_ende);
set(gca, 'XLim', [offsetPreIP, offsetPostMA])