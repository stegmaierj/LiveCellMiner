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


if (isfield(parameter.projekt, 'timeWindowMother') && ...
        isfield(parameter.projekt, 'timeWindowDaughter'))
    parameter.gui.livecellminer.IPTransition = parameter.projekt.timeWindowMother;
    parameter.gui.livecellminer.MATransition = parameter.projekt.timeWindowMother + 30;
    parameter.gui.livecellminer.alignedLength = parameter.projekt.timeWindowMother + parameter.projekt.timeWindowDaughter + 30;
end

%% add path to distinguishable_colors script and the custom luts path
lutPath = [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'luts' filesep];
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'distinguishable_colors']);
addpath(lutPath);

addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'struct2File']);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'getarg']);


%% find valid lut files
lutFiles = dir([lutPath '*.m']);

%% add the luts to the dropdown menu if not contained yet
if (~isempty(lutFiles))

    %% find the combobox control element
    numControlElements = length(parameter.gui.control_elements);
    for i=1:numControlElements

        %% ignore all other control elements
        if (~strcmp(parameter.gui.control_elements(i).tag, 'CE_LiveCellMiner_ColorMap'))
            continue;
        end

        %% add available lut scripts to the dropdown box
        for j=1:length(lutFiles)

            %% get the current file name
            [~, currentLutName, ~] = fileparts(lutFiles(j).name);

            %% get the previous lut string
            lutStrings = parameter.gui.control_elements(i).listen_werte;

            %% append the new function
            if (~contains(lutStrings, currentLutName))
                lutStrings = [lutStrings '|' currentLutName];
            end

            %% update the control element
            parameter.gui.control_elements(i).listen_werte = lutStrings;
            parameter.gui.control_elements(i).handle.String = char(strsplit(lutStrings, '|'));
        end
    end
end

return;