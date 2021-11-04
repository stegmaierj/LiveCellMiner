%%
% LiveCellMiner.
% Copyright (C) 2021 D. Moreno-Andrés, A. Bhattacharyya, W. Antonin, J. Stegmaier
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

function [resultHeatMap] = callback_livecellminer_compute_aligned_heatmap(d_orgs, validIndices, synchronizationIndex, featureIndex, parameter)
    
    %% get the parameters from the GUI
    IPTransition = parameter.gui.livecellminer.IPTransition;
    MATransition = parameter.gui.livecellminer.MATransition;
    alignedLength = parameter.gui.livecellminer.alignedLength;
    timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;
    alignPlots = parameter.gui.livecellminer.alignPlots;

    %% create the current heat map
    if (alignPlots == false)
        resultHeatMap = zeros(length(validIndices), length(timeRange));
        for c=1:length(validIndices)
            resultHeatMap(c, :) = squeeze(d_orgs(validIndices(c), timeRange, featureIndex));
        end
    else
        resultHeatMap = nan(length(validIndices), alignedLength);
        for c=1:length(validIndices)
            currentStageTransitions = squeeze(d_orgs(validIndices(c), timeRange, synchronizationIndex));
            currentFeatureValues = squeeze(d_orgs(validIndices(c), timeRange, featureIndex));

            indicesIP = find(currentStageTransitions == 1);
            indicesPM = find(currentStageTransitions == 2);
            indicesMA = find(currentStageTransitions == 3);

            splitPoint = round(length(indicesPM) / 2);
            indicesPM1 = indicesPM(1:splitPoint);
            indicesPM2 = indicesPM((splitPoint+1):end);

            %% fill the values in an aligned fashion
            resultHeatMap(c, (IPTransition-length(indicesIP)+1):IPTransition) = currentFeatureValues(indicesIP);

            resultHeatMap(c, (IPTransition+1):(IPTransition+length(indicesPM1))) = currentFeatureValues(indicesPM1);
            resultHeatMap(c, (MATransition-length(indicesPM2)):(MATransition-1)) = currentFeatureValues(indicesPM2);

            resultHeatMap(c, MATransition:(MATransition+length(indicesMA)-1)) = currentFeatureValues(indicesMA);
        end

        %% trim the heat map in case any line exceeded the maximum length
        resultHeatMap = resultHeatMap(:, 1:alignedLength);
    end
end