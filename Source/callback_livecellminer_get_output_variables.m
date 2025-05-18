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

%% returns the id of specific output variables based on the respective names
function [experimentId, positionId] = callback_livecellminer_get_output_variables(experimentList, positionList, experimentName, positionName)

	%% initialize ids to 0
    experimentId = 0;
    positionId = 0;
    	
	%% try to find the experiment id
    for j=1:length(experimentList)
       if (strcmp(experimentList{j}, experimentName))
           experimentId = j;
           break;
       end
    end

	%% try to find the position id
    for j=1:length(positionList)
       if (strcmp(positionList{j}, positionName))
           positionId = j;
           break;
       end
    end
end