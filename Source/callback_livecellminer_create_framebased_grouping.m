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

%% get time series indices for the sync and frame time series
syncIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
frameIndex = callback_livecellminer_find_time_series(var_bez, 'frameNumber');
if (syncIndex <= 0)
    disp('Error: no sync information present. Please perform auto or manual sync first!');
    return;
end
if (frameIndex <= 0)
    disp('Error: no frame information present. Please reimport project with the latest LCM version to add this feature!');
    return;
end

%% extract the minimum and maximum frames
minFrame = min(d_orgs(:,:,5), [], 'all');
maxFrame = max(d_orgs(:,:,5), [], 'all');

%% ask user for the desired interval spacings
prompt = {'Enter bin edges (defaults to 3 equally spaced edges, i.e., 4 bins):', 'Number of bins (ignored when set to -1):', 'Timepoint for grouping (IP = 0, MA = 1):'};
dlgtitle = 'Frame-dependent Output Variable';
fieldsize = [1 45; 1 45; 1 45];
definput = {sprintf('[%d, %d, %d, %d, %d]', 0, round(maxFrame*0.25), round(maxFrame*0.5), round(maxFrame*0.75), maxFrame), '-1', '1'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

%% find division indices
IPTimePoints = zeros(size(d_orgs,1), 2);
MATimePoints = zeros(size(d_orgs,1), 2);
for i=1:size(d_orgs,1)

    currentSyncIndices = find(diff(d_orgs(i, :, syncIndex)) > 0);

    if (isempty(currentSyncIndices))
        IPTimePoints(i) = -1;
        MATimePoints(i) = -1;
        continue;
    end

    IPTimePoints(i, :) = [currentSyncIndices(1), d_orgs(i, currentSyncIndices(1), frameIndex)];
    MATimePoints(i, :) = [currentSyncIndices(2), d_orgs(i, currentSyncIndices(2), frameIndex)];
end

%% select desired reference point (either IP or MA)
if (str2double(answer{3}) == 1)
    timePoints = MATimePoints(:,2);
else
    timePoints = IPTimePoints(:,2);
end

%% either take the specified custom bins or use equally distributed binning
if (str2double(answer{2}) < 0)
    binEdges = eval(answer{1});
else
    numBins = str2double(answer{2});
    binWidth = (maxFrame - minFrame) / numBins;

    binEdges = 0;
    for i=1:numBins
        binEdges = [binEdges, min(maxFrame, minFrame + i*binWidth)];
    end
end

%% fill the frame groups according to the specified bins
frameGrouping = -1 * ones(size(d_orgs,1), 1);
for i=1:size(d_orgs,1)
    for j=1:(length(binEdges)-1)
        if (timePoints(i) > binEdges(j) && timePoints(i) <= binEdges(j+1))
            frameGrouping(i) = j;
        end
    end
end

%% create new single feature in d_org
d_org(:, end+1) = frameGrouping;

featureName = sprintf('FrameGrouping_NumBins=%d_MA=%s_BinEdgeFrames=[', length(binEdges)-1, answer{3});
for i=1:length(binEdges)
    featureName = [featureName sprintf('%i', binEdges(i))];
    if (i < length(binEdges))
        featureName = [featureName '_'];
    end
end
featureName = [featureName ']'];

dorgbez = char(dorgbez, featureName);
aktparawin;
