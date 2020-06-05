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

%% add external scripts to path
addpath('toolbox/');
addpath('toolbox/haralick/');
addpath('toolbox/saveastiff_4.3/');

%% select the input root folder and identify the folders containing the plates
inputRootFolder = uigetdir();
outputRoot =  'I:/Projects/2020/CellTracking_MorenoAndresUKA/Processing/';
[inputFolders, microscopeList, experimentList, positionList] = callback_chromatindec_get_valid_input_paths(inputRootFolder);

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Specify the physical spacing in mu for each project.';
dims = [1 100];
micronsPerPixel = inputdlg(experimentList, dlgtitle, dims, micronsPerPixel);

%% prepare question dialog to ask for the physical spacing of the experiments
dlgtitle = 'Specify suffix to select a particular channel (e.g., c0002) or leave empty.';
dims = [1 100];
channelFilter = inputdlg(experimentList, dlgtitle, dims, channelFilter);

for i=1:length(inputFolders)

    %% clear the temporary settings variable
    settings = struct();
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% project-specific parameters and selection of algrithms to use for processing
    settings.useCellpose = true;                    %% if enabled, the cellpose algorithm will be used for segmentation instead of the threshold/watershed default algorithm
    settings.seedBasedDetection = true;             %% if enabled, LoGSSMP seeds will be used. Otherwise, cell pose segmentation results will be used.
    settings.writeImagePatches = false;             %% if enabled, small image patches will be written separately to disk
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% the following folder structure is assumed and used to later group the data:
    %% %MICROSCOPE%/%EXPERIMENT%/%POSITION%/%IMAGEFILES%.tif
    settings.inputFolder = inputFolders{i};
    settings.outputRoot = outputRoot;

    %% extract project information
    splitString = strsplit(settings.inputFolder(1:end-1), '/');
    settings.microscopeName = splitString{end-2};
    settings.experimentName = splitString{end-1};
    settings.positionNumber = splitString{end};
    
    for j=1:length(experimentList)
        if (strcmp(experimentList{j}, settings.experimentName))
            experimentIndex = j;
            break;
        end
    end
    
    settings.channelFilter = channelFilter{experimentIndex};      %% select a specific channel for processing. Should be specific part of the file name
    settings.micronsPerPixel = micronsPerPixel{experimentIndex};  %% the physical spacing in microns. Note that the seed detection pipelines are selected with this string, so should have consistent number of digits that match the names of the XML pipelines.

    %% assemble and create the output folder
    settings.outputFolder = [settings.outputRoot settings.microscopeName '/' settings.experimentName '/' settings.positionNumber '/'];
    if (~isfolder(settings.outputFolder)); mkdir(settings.outputFolder); end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% advanced parameters (usually no need for change)
    settings.framesBeforeIP = 30;               %% the number of frames to extract before the division event
    settings.framesAfterMA = 60;                %% the number of frames to extract after the division event
    settings.timeWindowMother = 30;             %% the number of frames to extract before the division event
    settings.timeWindowDaughter = 60;           %% the number of frames to extract after the division event
    settings.patchWidth = 90;                   %% patch width used for extracting the image snippets
    settings.maxRadius = 10;                    %% maximum radius to search for neighboring cells during tracking
    settings.clusterRadiusIndex = 9;            %% index to the cluster radius feature
    settings.trackingIdIndex = 10;              %% index to the tracking id
    settings.predecessorIdIndex = 11;           %% index to the predecessor
    settings.posIndices = 3:5;                  %% indices to the positions
    settings.prevPosIndices = 6:8;              %% indices to the previous positions
    settings.clusterCutoff = -1;                %% cluster cutoff (-1 for automatic detection based on the nearest neighbor distribution)
    settings.numFrames = inf;                   %% number of frames in the entire sequence
    settings.numRefinementSteps = 0;            %% if larger than 0, multiple rounds of centroid relocation to the weighted centroid are performed
    settings.refinementRadius = 5;              %% radius for computing the weighted centroid
    settings.debugFigures = false;              %% if enabled, debug figures will be shown
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% specify paths to the external processing tools XPIWIT and Cellpose (only has to be setup once for the entire system)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    settings.XPIWITPath = 'D:/Programming/XPIWIT/Release/2019/XPIWIT_Windows_x64/Bin/';
    settings.XPIWITDetectionPipeline = [strrep(parameter.allgemein.pfad_gaitcad, '\', '/') '/application_specials/chromatindec/toolbox/XPIWITPipelines/CellDetection_micronsPerVoxel=' num2str(settings.micronsPerPixel) '.xml'];
    if (~exist(settings.XPIWITDetectionPipeline, 'file'))
        disp(['ERROR: Couldn''t find processing pipeline ' settings.XPIWITDetectionPipeline ' . Make sure the file exists or create a pipeline for the selected physical spacing!']);
    end

    settings.CELLPOSEPath = 'I:/Software/Cellpose/';
    settings.CELLPOSEEnvironment = 'C:/Environments/cellpose/python.exe'; %'/work/scratch/stegmaier/Software/Environments/cellpose/bin/python';
    settings.CELLPOSEModelDir = [settings.CELLPOSEPath 'models/'];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% start the processing
    callback_chromatindec_import_project(settings);
end
