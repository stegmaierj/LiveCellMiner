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

%% get the experiment output variable
experimentId = callback_chromatindec_find_output_variable(bez_code, 'Experiment');
experiments = unique(code_alle(:, experimentId));

%% find the current experiment names
experimentNames = cell(length(experiments), 1);
combinedExperiments = cell(length(experiments), 1);
for i=1:length(experiments)
   experimentNames{i} = zgf_y_bez(experimentId, i).name;
   combinedExperiments{i} = num2str(i);
end

%% specify name for the new output variable and the new id
outputVariableName = 'ExperimentsCombined';
outputVariableId = size(code_alle, 2)+1;

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Assign corresponding repeats the same (unique!) ID.';
dims = [1 100];
combinedExperiments = inputdlg(experimentNames, dlgtitle, dims, combinedExperiments);

%% assemble the new output variable
code_alle_new(size(d_orgs,1),1) = 0;
for i=1:length(experiments)
    newOutputVariable = str2double(combinedExperiments{i});
    currentIndices = code_alle(:, experimentId) == i;
    code_alle_new(currentIndices) = newOutputVariable;
end
code_alle(:,outputVariableId) = code_alle_new;
bez_code = char(bez_code, outputVariableName);

%% add the names for the output variable to zgf_y_bez
for i=unique(code_alle_new)'
    
    %% get the experiments that should be fused
    associatedExperiments = unique(code_alle(code_alle_new == i,experimentId));
    
    %% show question prompt about the fused experiment name or directly add experiment name of only one is present
    if (length(associatedExperiments) > 1)
        prompt = {'Enter the name of the combined experiments:'};
        dlgtitle = 'Name for Combined Experiment';
        definput = {zgf_y_bez(experimentId, associatedExperiments(1)).name};
        combinedName = inputdlg(prompt,dlgtitle,[1 100],definput);
        
        zgf_y_bez(outputVariableId, i).name = combinedName{1};
    else
        zgf_y_bez(outputVariableId, i).name = zgf_y_bez(experimentId, associatedExperiments).name;
    end
end

%% update the parameter window
aktparawin;