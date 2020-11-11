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

%% specify the default settings file
settingsFile = [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'chromatindec' filesep 'externalDependencies.txt'];

%% load previous path if it exists, otherwise request the paths from the user.
if (exist(settingsFile, 'file'))
    fileHandle = fopen(settingsFile, 'r');
    currentLine = fgets(fileHandle);
    splitString = strsplit(currentLine, ';');
    XPIWITPath = splitString{1};
    CELLPOSEPath = splitString{2};
    CELLPOSEEnvironment = splitString{3};
    fclose(fileHandle);
else
    callback_chromatindec_set_external_dependencies;
end

%% add external scripts to path
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'chromatindec' filesep 'toolbox' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'chromatindec' filesep 'toolbox' filesep 'haralick' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'chromatindec' filesep 'toolbox' filesep 'saveastiff_4.3' filesep]);

%% select the input root folder and identify the folders containing the plates
defaultSearchFolder = 'V:/';
inputRootFolder = uigetdir(defaultSearchFolder, 'Select the input directory ...');
if (inputRootFolder == 0)
    disp('No input folder selected. Aborting ...');
    return;
end

%% recursively find the valid input paths
[inputFolders, microscopeList, experimentList, positionList] = callback_chromatindec_get_valid_input_paths(inputRootFolder);

%% get the output path
outputRoot = uigetdir(defaultSearchFolder, 'Select the output directory ...');
outputRoot = [outputRoot filesep];
if (inputRootFolder == 0)
    disp('No output folder selected. Aborting ...');
    return;
end

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Additional settings:';
dims = [1 100];
additionalUserSettings = inputdlg({'Input Path Windows Prefix', 'Input Path IP-based Prefix (leave empty to ignore)', 'Use CNN-based segmentation (Cellpose)', 'Reprocess existing projects?'}, dlgtitle, dims, {defaultSearchFolder, '\\filesrv\Images\', '0', '0'});
if (isempty(additionalUserSettings))
    disp('No additional settings provided, stopping processing ...');
    return;
end

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Specify the physical spacing in mu for each project.';
dims = [1 100];
micronsPerPixel = inputdlg(experimentList, dlgtitle, dims);
if (isempty(micronsPerPixel))
    disp('No microns per pixel provided, stopping processing ...');
    return;
end

%% prepare question dialog to ask for the channel suffix the experiments
dlgtitle = 'Specify suffix to select the chromatin channel (e.g., *_c0001) or leave empty.';
dims = [1 100];
channelFilter = inputdlg(experimentList, dlgtitle, dims);
if (isempty(channelFilter))
    disp('No channel filter provided, stopping processing ...');
    return;
else
    dlgtitle = 'Specify suffix to select an additional channel (e.g., *_c0002) or leave empty.';
    dims = [1 100];
    channelFilter2 = inputdlg(experimentList, dlgtitle, dims);
end

for i=1:length(inputFolders)

    %% clear the temporary settings variable
    parameters = struct();
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% project-specific parameters and selection of algrithms to use for processing
    parameters.useCellpose = str2double(additionalUserSettings{3}) > 0; %% if enabled, the cellpose algorithm will be used for segmentation instead of the threshold/watershed default algorithm
    parameters.reprocessExistingProjects = str2double(additionalUserSettings{4}) > 0;
    parameters.seedBasedDetection = true;             %% if enabled, LoGSSMP seeds will be used. Otherwise, cell pose segmentation results will be used.
    parameters.writeImagePatches = false;             %% if enabled, small image patches will be written separately to disk
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% the following folder structure is assumed and used to later group the data:
    %% %MICROSCOPE%/%EXPERIMENT%/%POSITION%/%IMAGEFILES%.tif
    parameters.inputFolder = inputFolders{i};
    parameters.outputRoot = outputRoot;
    parameters.inputFolderCellpose = parameters.inputFolder;
    if (~isempty(additionalUserSettings{2}))
        parameters.inputFolderCellpose = strrep(parameters.inputFolderCellpose, additionalUserSettings{1}, additionalUserSettings{2});
    end

    %% extract project information
    splitString = strsplit(parameters.inputFolder(1:end-1), '/');
    parameters.microscopeName = splitString{end-2};
    parameters.experimentName = splitString{end-1};
    parameters.positionNumber = splitString{end};
    
    for j=1:length(experimentList)
        if (strcmp(experimentList{j}, parameters.experimentName))
            experimentIndex = j;
            break;
        end
    end
    
    parameters.channelFilter = channelFilter{experimentIndex};      %% select a specific channel for processing. Should be specific part of the file name
    parameters.channelFilter2 = channelFilter2{experimentIndex};    %% select an additional channel. This channel will only be used to extract the corresponding snippets as well for later processing.
    parameters.micronsPerPixel = str2double(micronsPerPixel{experimentIndex});  %% the physical spacing in microns. Note that the seed detection pipelines are selected with this string, so should have consistent number of digits that match the names of the XML pipelines.

    %% assemble and create the output folder
    parameters.outputFolder = [parameters.outputRoot parameters.microscopeName '/' parameters.experimentName '/' parameters.positionNumber '/'];
    if (~isfolder(parameters.outputFolder)); mkdir(parameters.outputFolder); end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% advanced parameters (usually no need for change)
    parameters.framesBeforeIP = 30;               %% the number of frames to extract before the division event
    parameters.framesAfterMA = 60;                %% the number of frames to extract after the division event
    parameters.timeWindowMother = 30;             %% the number of frames to extract before the division event
    parameters.timeWindowDaughter = 60;           %% the number of frames to extract after the division event
    parameters.patchWidth = 96;                   %% patch width used for extracting the image snippets
    parameters.patchRescaleFactor = 0.415;        %% use spacing of confocal images as reference, i.e., they remain unscaled whereas widefield images are enlarged to ideally have a single cell in the center
    parameters.maxRadius = 10;                    %% maximum radius to search for neighboring cells during tracking
    parameters.clusterRadiusIndex = 9;            %% index to the cluster radius feature
    parameters.trackingIdIndex = 10;              %% index to the tracking id
    parameters.predecessorIdIndex = 11;           %% index to the predecessor
    parameters.posIndices = 3:5;                  %% indices to the positions
    parameters.prevPosIndices = 6:8;              %% indices to the previous positions
    parameters.clusterCutoff = -1;                %% cluster cutoff (-1 for automatic detection based on the nearest neighbor distribution)
    parameters.numFrames = inf;                   %% number of frames in the entire sequence
    parameters.numRefinementSteps = 0;            %% if larger than 0, multiple rounds of centroid relocation to the weighted centroid are performed
    parameters.refinementRadius = 5;              %% radius for computing the weighted centroid
    parameters.debugFigures = false;              %% if enabled, debug figures will be shown
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% specify paths to the external processing tools XPIWIT and Cellpose (only has to be setup once for the entire system)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    parameters.XPIWITPath = XPIWITPath;
    parameters.XPIWITDetectionPipeline = [strrep(parameter.allgemein.pfad_gaitcad, '\', '/') '/application_specials/chromatindec/toolbox/XPIWITPipelines/CellDetection_micronsPerVoxel=' micronsPerPixel{experimentIndex} '.xml'];
    if (~exist(parameters.XPIWITDetectionPipeline, 'file'))
        disp(['ERROR: Couldn''t find processing pipeline ' parameters.XPIWITDetectionPipeline ' . Make sure the file exists or create a pipeline for the selected physical spacing!']);
    end

    parameters.CELLPOSEPath = CELLPOSEPath;
    parameters.CELLPOSEEnvironment = CELLPOSEEnvironment; %'/work/scratch/stegmaier/Software/Environments/cellpose/bin/python';
    parameters.CELLPOSEModelDir = [parameters.CELLPOSEPath 'models/'];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% skip processing if the project already exists
    [~, filesExist] = callback_chromatindec_generate_output_paths(parameters);
    if (~filesExist.project || ...
        ~filesExist.rawImagePatches || ...
        ~filesExist.maskImagePatches || ...
        ~filesExist.maskedImageCNNFeatures || ...
        parameters.reprocessExistingProjects)
    
        %% process current files if the project didn't exist
        callback_chromatindec_import_project(parameters);
    else
        disp(['Project file for ' parameters.inputFolder ' already exists, skipping processing (To reprocess, manually delete the *.prjz and *.mat files in the project directory).' ]);
    end
end