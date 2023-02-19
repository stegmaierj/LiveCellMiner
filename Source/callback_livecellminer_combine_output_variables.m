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

%% ask which output variables to combine
prompt = {'Output Variable 1:','Output Variable 2:'};
dlgtitle = 'Combine Output Variables';
dims = [1 35];
definput = {'Experiment','OligoID'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

outputVariable1 = callback_livecellminer_find_output_variable(bez_code, answer{1});
outputVariable2 = callback_livecellminer_find_output_variable(bez_code, answer{2});

%% cancel if invalid selection was performed
if (outputVariable1 == 0 || outputVariable2 == 0)
    disp('One or more output variables were not found. Double-check spelling! Aborting...');
    return;
end

%% create new output variable name
outputVariableName1 = kill_lz(bez_code(outputVariable1,:));
outputVariableName2 = kill_lz(bez_code(outputVariable2,:));
newOutputVariableName = [outputVariableName1 '-x-' outputVariableName2];

%% check if the oligoID output variable already exists to avoid creating another one
newOutputVariable = callback_livecellminer_find_output_variable(bez_code, newOutputVariableName);
if (newOutputVariable == 0)    
    code_alle(:,end+1) = 0;
    newOutputVariable = size(code_alle, 2);
    bez_code = char(bez_code, newOutputVariableName);
end

%% create new output variable
currentCode = 1;
for i=unique(code_alle(:,outputVariable1))'
    for j=unique(code_alle(:,outputVariable2))'

        currentIndices = find(code_alle(:, outputVariable1) == i & code_alle(:, outputVariable2) == j);
        code_alle(currentIndices, newOutputVariable) = currentCode;

        zgf_y_bez(newOutputVariable, currentCode).name = [zgf_y_bez(outputVariable1, i).name '-x-' zgf_y_bez(outputVariable2, j).name];

        currentCode = currentCode + 1;
    end
end

%% refresh GUI
aktparawin;