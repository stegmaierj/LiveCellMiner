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

%% get the root directory of the projects to import
inputRootFolders = uipickfiles();
if (~iscell(inputRootFolders) && inputRootFolders == 0)
   disp('Please select a valid input folder. Aborting ...');
   return;
end

%% import all subfolders
[inputFolders, experimentList, positionList] = callback_livecellminer_get_valid_input_paths(inputRootFolders);

%% initialize scixminer project variables
numFeatures = 28;
d_orgs_new = [];
code_alle_new = zeros(0, 4);
zgf_y_bez_new = struct();
clear projekt_new;

%% import all projects contained in the root folder
currentCell = 1;
currentExperiment = 1;

for i=1:length(inputFolders)
        
    %% get the current folder
    currentInputFolder = inputFolders{i};
    
    splitString = strsplit(currentInputFolder(1:end-1), '/');
    experimentName = splitString{end-1};
    positionName = splitString{end};
    [experimentId, positionId] = callback_livecellminer_get_output_variables(experimentList, positionList, experimentName, positionName);
    
    %% load the current project
    projectName = [currentInputFolder experimentName '_' positionName '_SciXMiner.prjz'];
    if (~isfile(projectName)); continue; end
    load(projectName, '-mat');

    if (isempty(d_orgs_new))
        numFrames = size(d_orgs, 2);
        d_orgs_new = zeros(0, numFrames, numFeatures);
        projekt_new = projekt;
    end

    if (size(d_orgs,2) ~= numFrames)
        disp('Project fusion not possible for projects with numbers of frames! Please make sure to only select projects that have the same number of frames.');
    end

    projekt_new.originalProjectInfo{i} = projekt;

    %% identify the valid indices
    validIndices = find(squeeze(d_orgs(:,1,1)) > 0);
    numCells = length(validIndices);

    %% copy the current project to the complete project
    d_orgs_new(end+1:end+numCells, :, :) = d_orgs(validIndices, :, :);
    code_alle_new(end+1:end+numCells, :) = [ones(numCells, 1), experimentId * ones(numCells, 1), positionId * ones(numCells, 1), (1:numCells)'];

    projekt_new.originalProjectInfo{i}.newIDs = ((size(d_orgs_new,1))-numCells+1):(size(d_orgs_new,1));

    %% fill the zgf_y_bez variable
    zgf_y_bez_new(1,1).name = 'All';
    zgf_y_bez_new(2, experimentId).name = experimentName;
    zgf_y_bez_new(3, positionId).name = positionName;
    for k=1:numCells
        zgf_y_bez_new(4, k).name = sprintf('cell_id_%04d', k);

        %% increase the cell counter
        currentCell = currentCell + 1;
    end

    fprintf('Successfully imported experiment %s, plate %s.\n', experimentName, positionName);
end

%% save the final project
code = code_alle_new(:,1);
code_alle = code_alle_new;
d_orgs = d_orgs_new;
bez_code = char('All', 'Experiment', 'Position', 'Cell');
zgf_y_bez = zgf_y_bez_new;
projekt = projekt_new;
%projekt.imageFiles = imageFiles;

[file,path] = uiputfile('*.prjz', 'Specify the name of the fused project', 'FusedProjects.prjz');
outputFileName = [path file];
save(outputFileName, '-mat', 'd_orgs', 'var_bez', 'code', 'code_alle', 'zgf_y_bez', 'bez_code', 'projekt');

%% directly load the generated project
result = questdlg('Directly load generated project?', 'Load project?');
if (strcmp(result, 'Yes'))
    next_function_parameter = outputFileName;
    ldprj_g;
end
