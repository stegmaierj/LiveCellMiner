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

%% remember the previous selection
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;

%% find the manual synchronization feature
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'xpos', 'ypos'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
positionIndices = parameter.gui.merkmale_und_klassen.ind_zr;

%% restore the old selection
set(gaitfindobj('CE_Auswahl_ZR'), 'value', oldSelection);
aktparawin;

%% compute the Sister cell distance
d_orgs(:,:,end+1) = 0;
sisterDistanceFeature = size(d_orgs, 3);
var_bez = char(var_bez(1:end-1, :), 'SisterCellDistance');

%% process all data points and compute the Sister distances.
for i=1:2:size(d_orgs,1)

    %% don't process the last entry of d_orgs
    if (i >= size(d_orgs,1))
        continue;
    end
    
    %% find normalization time point
    sisterDistance = sqrt(sum((squeeze(d_orgs(i,:,positionIndices)) - squeeze(d_orgs(i+1,:,positionIndices))).^2, 2))';

    %% skip if no valid sync point was selected
    if (isempty(find(sisterDistance, 1)))
        continue;
    end

    %% set the Sister distance feature
    d_orgs(i, :, sisterDistanceFeature) = sisterDistance;
    d_orgs(i+1, :, sisterDistanceFeature) = sisterDistance;
end

%% update the time series
aktparawin;