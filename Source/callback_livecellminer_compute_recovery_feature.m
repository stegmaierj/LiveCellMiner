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

%% remember the previous selection
syncFeatureIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

%% find the manual synchronization feature
positionIndices = [3,4];
positionIndices(1) = callback_livecellminer_find_time_series(var_bez, 'xpos');
positionIndices(2) = callback_livecellminer_find_time_series(var_bez, 'ypos');

%% find the selected features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;
numFeatures = length(selectedFeatures);
if (numFeatures <= 0)
    disp('No valid features selected!');
    return;
end


%% compute the Sister cell distance
d_orgs(:,:,end+1) = 0;
recoveryFeatureIndex = size(d_orgs, 3);
if (strcmp(kill_lz(var_bez(end,:)), 'y') || var_bez(end,1) == 'y')
    var_bez = char(var_bez(1:end-1, :), 'RecoveryFeature');
else
    var_bez = char(var_bez, 'RecoveryFeature');
end
aktparawin;

%% process all data points and compute the Sister distances.
for i=1:size(d_orgs,1)

    %% don't process the last entry of d_orgs
    if (i >= size(d_orgs,1) || max(d_orgs(i,:,syncFeatureIndex)) <= 0)
        continue;
    end
    
    intIndices = find(d_orgs(i,:,syncFeatureIndex) == 1);
    pmaIndices = find(d_orgs(i,:,syncFeatureIndex) == 2);
    atiIndices = find(d_orgs(i,:,syncFeatureIndex) == 3);
    
    %% find normalization time point
    featureWeight = 1 / numFeatures;
    recoveryFeature = zeros(1, size(d_orgs,2));
    for j=selectedFeatures
        targetValue = mean(mean(d_orgs(i,intIndices, j)));
        recoveryFeature = recoveryFeature + featureWeight * (100*(abs(targetValue - d_orgs(i,:, j)) / targetValue));
    end
    recoveryFeature = 100 - recoveryFeature;
           
    %% set the Sister distance feature
    d_orgs(i, :, recoveryFeatureIndex) = recoveryFeature;
end