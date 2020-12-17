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

%% skip if no single features are present
if (isempty(d_org))
    return;
end

%% identify the selected single features and select the first one
selectedSingleFeature = parameter.gui.merkmale_und_klassen.ind_em(1);

%% identify the minimum and maximum values
minimumValue = min(d_org(:,selectedSingleFeature));
maximumValue = max(d_org(:,selectedSingleFeature));

%% open input file dialog
prompt = {'Minimum Value:','Maximum Value:'};
dlgtitle = 'Define Feature Range for Data Point Selection';
dims = [1 35; 1 35];
definput = {num2str(minimumValue), num2str(maximumValue)};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if (isempty(answer))
    disp('No range selected! Canceling ...');
    return;
end

%% get the lower and upper limits
lowerLimit = str2double(answer{1});
upperLimit = str2double(answer{2});

%% perform the selection
ind_auswahl = find(d_org(:,selectedSingleFeature) >= lowerLimit & d_org(:,selectedSingleFeature) <= upperLimit);

if (isempty(ind_auswahl))
    disp('ERROR: No data point contained in range! Please select a valid feature range.');
    ind_auswahl = 1:size(d_org,1);
else
    disp(['Selected ' num2str(length(ind_auswahl)) ' / ' num2str(size(d_org,1)) ' data points using the single feature ' kill_lz(dorgbez(selectedSingleFeature,:)) ' with a data range [' num2str(lowerLimit) ', ' num2str(upperLimit) '].']);
end
aktparawin;
