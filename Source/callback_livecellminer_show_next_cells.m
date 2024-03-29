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

global parameters; %#ok<GVMIS> 
parameters.currentIdRange = parameters.currentIdRange + parameters.numVisualizedCells;

if (max(parameters.currentIdRange) > length(parameters.selectedCells))
    parameters.currentIdRange = (length(parameters.selectedCells) - parameters.numVisualizedCells+1):length(parameters.selectedCells);
    disp('Reached end of the selected cells. Select either more cells to proceed or stop annotating here...');
end

parameters.currentIdRange(parameters.currentIdRange <= 0) = [];
parameters.currentCells = parameters.selectedCells(parameters.currentIdRange);
parameters.dirtyFlag = true;
callback_livecellminer_update_visualization;