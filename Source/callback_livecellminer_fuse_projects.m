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

%% get the root directory of the projects to import
inputRootFolder = uigetdir();
if (inputRootFolder == 0)
   disp('Please select a valid input folder. Aborting ...');
   return;
end

%% import all subfolders
inputRootFolder = [inputRootFolder filesep];
[inputFolders, microscopeList, experimentList, positionList] = callback_livecellminer_get_valid_input_paths(inputRootFolder);

%% initialize the SciXMiner variables
numFrames = 90;
numFeatures = 28;
d_orgs_new = zeros(0, numFrames, numFeatures);
code_alle_new = zeros(0, 5);
zgf_y_bez_new = struct();
imageFiles = cell(0, 2);

%% import all projects contained in the root folder
currentCell = 1;
currentExperiment = 1;
currentMicroscope = 1;

for i=1:length(inputFolders)
        
    %% get the current microscope
    currentInputFolder = inputFolders{i};
    
    splitString = strsplit(currentInputFolder(1:end-1), '/');
    microscopeName = splitString{end-2};
    experimentName = splitString{end-1};
    positionName = splitString{end};
    [microscopeId, experimentId, positionId] = callback_livecellminer_get_output_variables(microscopeList, experimentList, positionList, microscopeName, experimentName, positionName);
    
    %% load the current project
    projectName = [currentInputFolder experimentName '_' positionName '_SciXMiner.prjz'];
    if (~isfile(projectName)); continue; end
    load(projectName, '-mat');

    %% identify the valid indices
    validIndices = find(squeeze(d_orgs(:,1,1)) > 0);
    numCells = length(validIndices);

    %% copy the current project to the complete project
    d_orgs_new(end+1:end+numCells, :, :) = d_orgs(validIndices, :, :);
    code_alle_new(end+1:end+numCells, :) = [ones(numCells, 1), microscopeId * ones(numCells, 1), experimentId * ones(numCells, 1), positionId * ones(numCells, 1), (1:numCells)'];

    %% fill the zgf_y_bez variable
    zgf_y_bez_new(1,1).name = 'All';
    zgf_y_bez_new(2, microscopeId).name = microscopeName;
    zgf_y_bez_new(3, experimentId).name = experimentName;
    zgf_y_bez_new(4, positionId).name = positionName;
    for k=1:numCells
        zgf_y_bez_new(5, k).name = sprintf('cell_id_%04d.tif', k);

        %% save the image file names to show the montages later on
        imageFiles{currentCell, 1} = [currentInputFolder 'Raw' filesep sprintf('cell_id_%04d.tif', k)];
        imageFiles{currentCell, 2} = [currentInputFolder 'Masks' filesep sprintf('mask_cell_id_%04d.tif', k)];

        %% increase the cell counter
        currentCell = currentCell + 1;
    end

    fprintf('Successfully imported experiment %s, plate %s.\n', experimentName, positionName);
end

%% save the final project
code = code_alle_new(:,1);
code_alle = code_alle_new;
d_orgs = d_orgs_new;
bez_code = char('All', 'Microscope', 'Experiment', 'Position', 'Cell');
zgf_y_bez = zgf_y_bez_new;
projekt.imageFiles = imageFiles;
save([inputRootFolder 'FusedProjects.prjz'], '-mat', 'd_orgs', 'var_bez', 'code', 'code_alle', 'zgf_y_bez', 'bez_code', 'projekt');

%% directly load the generated project
result = questdlg('Directly load generated project?', 'Load project?');
if (strcmp(result, 'Yes'))
    next_function_parameter = [inputRootFolder 'FusedProjects.prjz'];
    ldprj_g;
end
