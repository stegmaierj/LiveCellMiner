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

%% remember the previous selection
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;
syncFeatureIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

if (isempty(next_function_parameter))
    prompt = {'Enter frames after MA:'};
    dlgtitle = 'Specify number of frames after MA to extract the single feature...';
    dims = [1 35];
    definput = {'10'};
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    numFrames = round(str2double(answer{1}));
else
    numFrames = next_function_parameter;
    next_function_parameter = [];
end

for f=selectedFeatures

    %% compute the Sister cell distance
    d_org(:,end+1) = 0; %#ok<SAGROW> 
    newFeatureIndex = size(d_org, 2);

    if (strcmp(kill_lz(dorgbez(end,:)), 'y'))
        dorgbez = char(dorgbez(1:end-1, :), sprintf('%s_%02dFramesAfterMA', kill_lz(var_bez(f,:)), numFrames));
    else
        dorgbez = char(dorgbez, sprintf('%s-%02dFramesAfterMA', kill_lz(var_bez(f,:)), numFrames));
    end

    %% update the time series
    aktparawin;

    %% process all data points and compute the Sister distances.
    for i=1:size(d_orgs,1)

        %% don't process the last entry of d_orgs
        if (i >= size(d_orgs,1))
            continue;
        end

        %% find the MA transition
        currentMATransition = find(d_orgs(i, :, syncFeatureIndex) == 3, 1, 'first');

        if (isempty(currentMATransition) || (currentMATransition+numFrames) > size(d_orgs,2))
            d_orgs(i, :, syncFeatureIndex) = -1; %#ok<SAGROW> 
            continue;
        end

        %% find normalization time point
        featureAfterAnaphaseOnset = squeeze(d_orgs(i,currentMATransition+numFrames,f));

        %% set the Sister distance feature
        d_org(i, newFeatureIndex) = featureAfterAnaphaseOnset;
    end
end