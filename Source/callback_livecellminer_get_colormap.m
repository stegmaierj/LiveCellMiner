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

%% returns a colormap based on a selected string in the livecellminer dialog
function colorMap = callback_livecellminer_get_colormap(colorMapID, numColors, parameter)
  
    %% identify the control element containing the color maps
    numControlElements = length(parameter.gui.control_elements);
    for i=1:numControlElements
    
        if (~strcmp(parameter.gui.control_elements(i).tag, 'CE_LiveCellMiner_ColorMap'))
            continue;
        end

        colorMapString = parameter.gui.control_elements(410).listen_werte;
        break;
    end

    %% match the selected id and the color map string
    colorMaps = strsplit(colorMapString, '|');
    selectedColorMap = colorMaps{colorMapID};
    
    %% evaluate the colormap function to return the values
    evalString = [selectedColorMap '(' num2str(numColors) ')'];
    colorMap = eval(evalString);
end