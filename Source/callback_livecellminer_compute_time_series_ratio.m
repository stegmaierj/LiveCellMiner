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

%% find the required time series indices
syncFeature = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

if (syncFeature == 0)
    disp('Feature manualSynchronization was not found. Please run auto alignment first or provide a manual synchronization of the trajectories.');
    return;
end

if (length(parameter.gui.merkmale_und_klassen.ind_zr) < 2)
   disp('Select at least two time series to compute the ratio for. Note that the selection order is used to specify numerator and denominator.');
   return;
end
numeratorFeature = parameter.gui.merkmale_und_klassen.ind_zr(1);
denominatorFeature = parameter.gui.merkmale_und_klassen.ind_zr(2);
    
%% initialize a new feature and add a new specifier
d_orgs(:,:,end+1) = 0;

featureName = ['Ratio-' kill_lz(var_bez(numeratorFeature,:)) '-vs-' kill_lz(var_bez(denominatorFeature,:))];
if (var_bez(end,1) == 'y')
    var_bez = char(var_bez(1:end-1, :), featureName);
else
    var_bez = char(var_bez, featureName);
end

%% process all data points
for i=1:size(d_orgs,1)

    %% compute the ratio of minor vs. major axis for all time points
    ratioTimeSeries = d_orgs(i, :, numeratorFeature) ./ d_orgs(i, :, denominatorFeature);
    
    if (sum(isinf(ratioTimeSeries)) == 0 && sum(isnan(ratioTimeSeries)) == 0)
        d_orgs(i, :, end) = ratioTimeSeries;
    else
        disp(['Inf detected, removing cell ' num2str(i) ' from the valid cells!!']);
        d_orgs(i, :, syncFeature) = 0;
    end
end

%% update the time series
aktparawin;