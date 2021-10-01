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

%% get the manual synchronization time series
syncFeatureIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
if (syncFeatureIndex <= 0)
    disp('Manual synchronization not found. Please run auto-sync or manually align the tracks.');
   return; 
end

%% get the selected features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;

for f=selectedFeatures'

    %% initialize a new feature and add a new specifier
    d_org(:,end+1) = 0;
    d_org(:,end+1) = 0;
    d_org(:,end+1) = 0;

    %% add the specifier for the new single feature
    newFeatureName1 = [kill_lz(var_bez(f,:)) '-intMean'];
    newFeatureName2 = [kill_lz(var_bez(f,:)) '-pmaMean'];
    newFeatureName3 = [kill_lz(var_bez(f,:)) '-atiMean'];
    if (size(d_org,2) == 1)
        dorgbez = char(newFeatureName1, newFeatureName2, newFeatureName3);
    else
        dorgbez = char(dorgbez, newFeatureName1, newFeatureName2, newFeatureName3);
    end
    intMeanFeatureIndex = callback_livecellminer_find_single_feature(dorgbez, newFeatureName1);
    pmaMeanFeatureIndex = callback_livecellminer_find_single_feature(dorgbez, newFeatureName2);
    atiMeanFeatureIndex = callback_livecellminer_find_single_feature(dorgbez, newFeatureName3);

    %% compute the number of frames between the IP and MA transition
    for i=1:size(d_orgs,1)
        intIndices = find(d_orgs(i,:,syncFeatureIndex) == 1);
        pmaIndices = find(d_orgs(i,:,syncFeatureIndex) == 2);
        atiIndices = find(d_orgs(i,:,syncFeatureIndex) == 3);

        d_org(i, intMeanFeatureIndex) = mean(squeeze(d_orgs(i, intIndices, f)));
        d_org(i, pmaMeanFeatureIndex) = mean(squeeze(d_orgs(i, pmaIndices, f)));
        d_org(i, atiMeanFeatureIndex) = mean(squeeze(d_orgs(i, atiIndices, f)));
    end

    %% update the GUI for the new time series to show up
    aktparawin;
end