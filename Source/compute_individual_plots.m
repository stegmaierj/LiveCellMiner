%%
% ChromatinDec.
% Copyright (C) 2020 A. Bhattacharyya, D. Moreno-Andres, J. Stegmaier
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

%% create the current heat map
if (alignPlots == false)
    currentHeatMap = zeros(length(validIndices), length(timeRange));
    for c=1:length(validIndices)
        currentHeatMap(c, :) = squeeze(d_orgs(validIndices(c), timeRange, f));
    end
else
    currentHeatMap = nan(length(validIndices), alignedLength);
    for c=1:length(validIndices)
        currentStageTransitions = squeeze(d_orgs(validIndices(c), timeRange, synchronizationIndex));
        currentFeatureValues = squeeze(d_orgs(validIndices(c), timeRange, f));

        indicesIP = find(currentStageTransitions == 1);
        indicesPM = find(currentStageTransitions == 2);
        indicesMA = find(currentStageTransitions == 3);

        splitPoint = round(length(indicesPM) / 2);
        indicesPM1 = indicesPM(1:splitPoint);
        indicesPM2 = indicesPM((splitPoint+1):end);

        %% fill the values in an aligned fashion
        currentHeatMap(c, (IPTransition-length(indicesIP)+1):IPTransition) = currentFeatureValues(indicesIP);

        currentHeatMap(c, (IPTransition+1):(IPTransition+length(indicesPM1))) = currentFeatureValues(indicesPM1);
        currentHeatMap(c, (MATransition-length(indicesPM2)):(MATransition-1)) = currentFeatureValues(indicesPM2);

        currentHeatMap(c, MATransition:(MATransition+length(indicesMA)-1)) = currentFeatureValues(indicesMA);
    end

    %% trim the heat map in case any line exceeded the maximum length
    currentHeatMap = currentHeatMap(:, 1:alignedLength);
end

%% create a new subplot
subplot(numRows, numColumns, currentSubPlot); hold on;

%% visualize the current plate depending on the selected visualization mode
if (visualizationMode == 1)
    imagesc(currentHeatMap);
    ylabel(kill_lz(var_bez(f,:)));

    if (alignPlots == true)
        plot([IPTransition, IPTransition], [0, length(validIndices)], '--k', 'LineWidth', 2);
        plot([MATransition, MATransition], [0, length(validIndices)], '--k', 'LineWidth', 2);
    end
    colormap jet;
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
        plot([IPTransition, IPTransition], [0, max(meanCurve + stdCurve)], lineStyle, 'LineWidth', 2);
        plot([MATransition, MATransition], [0, max(meanCurve + stdCurve)], lineStyle, 'LineWidth', 2);
    end

    maxValue = max(maxValue, max(meanCurve + stdCurve));
    minValue = min(minValue, min(meanCurve - stdCurve));

    ylabel(strrep(kill_lz(var_bez(f,:)), '_', '\_'));
    box off;
end

%% add legends to the figures
if (summarizeSelectedExperiments == false)
    title(strrep([zgf_y_bez(experimentId,e).name '_' zgf_y_bez(selectedOutputVariable,p).name], '_', '\_'));
else
    title(strrep(['CombinedExperiments_' zgf_y_bez(selectedOutputVariable,p).name], '_', '\_'));
end
xlabel('Frame Number');