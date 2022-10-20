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

%% specify the default settings file
settingsFile = [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'externalDependencies.txt'];

%% load previous path if it exists, otherwise request the paths from the user.
if (exist(settingsFile, 'file'))
    fileHandle = fopen(settingsFile, 'r');
    currentLine = fgets(fileHandle);
    splitString = strsplit(currentLine, ';');
    XPIWITPath = splitString{1};
    CELLPOSEEnvironment = splitString{2};
    fclose(fileHandle);
else
    callback_livecellminer_set_external_dependencies;
end

%% add external scripts to path
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'haralick' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'saveastiff_4.3' filesep]);

%% select the input root folder and identify the folders containing the plates
multiFolderSelection = true;
defaultSearchFolder = 'V:/';
if (multiFolderSelection == false)
    inputRootFolders = cell(1,1);
    inputRootFolders{1} = uigetdir(defaultSearchFolder, 'Select the input directory ...');
    if (inputRootFolders{1} == 0)
        disp('No input folder selected. Aborting ...');
        return;
    end
else
    inputRootFolders = uipickfiles();
end

if (inputRootFolders == 0)
    disp('No input folder selected. Aborting ...');
    return;
end

%% recursively find the valid input paths
[inputFolders, microscopeList, experimentList, positionList] = callback_livecellminer_get_valid_input_paths(inputRootFolders);

%% get the output path
outputRoot = uigetdir(defaultSearchFolder, 'Select the output directory ...');
if (outputRoot == 0)
    disp('No output folder selected. Aborting ...');
    return;
else
    outputRoot = [outputRoot filesep];
end

%% open log file for saving the performance
performanceLog = fopen([outputRoot 'performanceLog.csv'], 'wb');

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Additional settings:';
dims = [1 100];
additionalUserSettings = inputdlg({'Input Path Windows Prefix (e.g., V:/)', 'Input Path IP-based Prefix ((e.g., \\filesrv\Images\, leave empty to ignore)', 'Use CNN-based segmentation (Cellpose)', 'Reprocess existing projects?', 'Time Window Before Mitosis (min)', 'Time Window After Mitosis (min)', 'Diameter (Cellpose)', 'Tracking Method (0: Seed Clustering, 1: Segmentation Propagation)'}, dlgtitle, dims, {'', '', '0', '0', '150', '180', '30', '0'});
if (isempty(additionalUserSettings))
    disp('No additional settings provided, stopping processing ...');
    return;
end

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Specify the frame interval for each project in minutes (e.g., 3 for 3 minutes).';
dims = [1 100];
frameInterval = inputdlg(experimentList, dlgtitle, dims);
if (isempty(frameInterval))
    disp('No frame interval information provided, stopping processing ...');
    return;
end

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Specify the physical spacing in mu for each project (e.g., 0.415).';
dims = [1 100];
micronsPerPixel = inputdlg(experimentList, dlgtitle, dims);
if (isempty(micronsPerPixel))
    disp('No microns per pixel provided, stopping processing ...');
    return;
end

%% prepare question dialog to ask for the channel suffix the experiments
dlgtitle = 'Specify suffix to select the chromatin channel (e.g., _c0001) or leave empty.';
dims = [1 100];
channelFilter = inputdlg(experimentList, dlgtitle, dims);
if (isempty(channelFilter))
    disp('No channel filter provided, stopping processing ...');
    return;
else
    dlgtitle = 'Specify suffix to select an additional channel (e.g., _c0002) or leave empty.';
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
    parameters.useTWANG = true;                       %% if enabled, TWANG segmentation is used as a backup for cellpose (only during tracking!!)
    parameters.writeImagePatches = false;             %% if enabled, small image patches will be written separately to disk
    parameters.performSegmentationPropagationTracking = str2double(additionalUserSettings{8}) > 0;
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
    parameters.frameInterval = str2double(frameInterval{experimentIndex}); %% the time interval between two successive frames in minutes
    
    %% assemble and create the output folder
    parameters.outputFolder = [parameters.outputRoot parameters.microscopeName '/' parameters.experimentName '/' parameters.positionNumber '/'];
    if (~isfolder(parameters.outputFolder)); mkdir(parameters.outputFolder); end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% advanced parameters (usually no need for change)
    parameters.framesBeforeIP = round(str2double(additionalUserSettings{5}) / parameters.frameInterval);     %% the number of frames to extract before the division event
    parameters.framesAfterMA = round(str2double(additionalUserSettings{6}) / parameters.frameInterval);      %% the number of frames to extract after the division event
    parameters.timeWindowMother = round(str2double(additionalUserSettings{5}) / parameters.frameInterval);   %% the number of frames to extract before the division event
    parameters.timeWindowDaughter = round(str2double(additionalUserSettings{6}) / parameters.frameInterval);  %% the number of frames to extract after the division event
    parameters.singleCellCCDisableRadius = 3;     %% the number of frames before/after the division time point where the single connected component segmentation is disabled (used for early ana segmentation)
    parameters.patchWidth = 96;                   %% patch width used for extracting the image snippets
    parameters.patchRescaleFactor = 0.415;        %% use spacing of confocal images as reference, i.e., they remain unscaled whereas widefield images are enlarged to ideally have a single cell in the center
    parameters.maxRadius = 15;                    %% maximum radius to search for neighboring cells during tracking
    parameters.diameterCellpose = str2double(additionalUserSettings{7});  %% diameter parameter used for the cellpose segmentation
    parameters.clusterRadiusIndex = 9;            %% index to the cluster radius feature
    parameters.trackingIdIndex = 10;              %% index to the tracking id
    parameters.predecessorIdIndex = 11;           %% index to the predecessor
    parameters.posIndices = 3:5;                  %% indices to the positions
    parameters.prevPosIndices = 6:8;              %% indices to the previous positions
    parameters.clusterCutoff = -1;                %% cluster cutoff (-1 for automatic detection based on the nearest neighbor distribution)
    parameters.numFrames = inf;                   %% number of frames in the entire sequence
    parameters.numRefinementSteps = 0;            %% if larger than 0, multiple rounds of centroid relocation to the weighted centroid are performed
    parameters.refinementRadius = 5;              %% radius for computing the weighted centroid
    parameters.allowedEmptyFrames = 2;            %% the maximum number of allowed empty frames. If an empty frame is encountered, the detections of the next frame are used.
    parameters.debugFigures = false;              %% if enabled, debug figures will be shown
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% specify paths to the external processing tools XPIWIT and Cellpose (only has to be setup once for the entire system)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    parameters.XPIWITPath = XPIWITPath;
    parameters.XPIWITDetectionPipeline = [strrep(parameter.allgemein.pfad_gaitcad, '\', '/') '/application_specials/livecellminer/toolbox/XPIWITPipelines/CellDetection_micronsPerVoxel=' micronsPerPixel{experimentIndex} '.xml'];
    
    if (~exist(parameters.XPIWITDetectionPipeline, 'file'))
        fileIDTemplate = fopen([strrep(parameter.allgemein.pfad_gaitcad, '\', '/') '/application_specials/livecellminer/toolbox/XPIWITPipelines/CellDetection_Template.xml'], 'rb');
        fileID = fopen(parameters.XPIWITDetectionPipeline, 'wb');

        while ~feof(fileIDTemplate)
            currentLine = fgetl(fileIDTemplate);
            currentLine = strrep(currentLine, '%IMAGE_SPACING%', micronsPerPixel{experimentIndex});

            fprintf(fileID, '%s\n', currentLine);
        end

        fclose(fileIDTemplate);
        fclose(fileID);
    end
    
    if (~exist(parameters.XPIWITDetectionPipeline, 'file'))
        disp(['ERROR: Couldn''t find processing pipeline ' parameters.XPIWITDetectionPipeline ' . Make sure the file exists or create a pipeline for the selected physical spacing!']);
    end

    parameters.CELLPOSEEnvironment = CELLPOSEEnvironment; %'/work/scratch/stegmaier/Software/Environments/cellpose/bin/python';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% skip processing if the project already exists
    [~, filesExist] = callback_livecellminer_generate_output_paths(parameters);
    if (~filesExist.project || ...
        ~filesExist.rawImagePatches || ...
        ~filesExist.maskImagePatches || ...
        ~filesExist.maskedImageCNNFeatures || ...
        parameters.reprocessExistingProjects)
    
        %% reset the timer
        tic;

        %% process current files if the project didn't exist
        callback_livecellminer_import_project(parameters);

        %% write elapsed time to the performance log
        elapsedTime = toc;
        fprintf(performanceLog, '%s;%f;\n', parameters.inputFolder, elapsedTime);
    else
        disp(['Project file for ' parameters.inputFolder ' already exists, skipping processing (To reprocess, manually delete the *.prjz and *.mat files in the project directory).' ]);
    end
end

%% close the performance log file
fclose(performanceLog);