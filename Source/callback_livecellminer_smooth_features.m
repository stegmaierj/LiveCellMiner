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

%% callback to smooth the selected features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;

%% remove dummy 'y' specifier
var_bez = var_bez(1:end-1,:);

%% process all selected time series
for f=generate_rowvector(selectedFeatures)
    
    %% get the raw time series
    rawFeatureValues = squeeze(d_orgs(:,:,f));
    
    %% smooth the selected time series
    smoothedFeatureValues = zeros(size(rawFeatureValues));
    parfor j=1:size(d_orgs,1)
        smoothedFeatureValues(j,:) = smooth(rawFeatureValues(j,:), parameter.gui.livecellminer.SmoothingWindow, parameter.gui.livecellminer.SmoothingMethod);
    end
    
    %% add the smoothed feature values to d_orgs and add a new specifier
    d_orgs(:,:,end+1) = smoothedFeatureValues;
    var_bez = char(var_bez, [kill_lz(var_bez(f,:)) '_smoothed']);
end

aktparawin;