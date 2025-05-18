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
callback_livecellminer_get_external_dependencies;

%% add external scripts to path
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'haralick' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'saveastiff_4.3' filesep]);

if (~isempty(next_function_parameter))
    processingConfigurationFile = next_function_parameter;
    next_function_parameter = [];
else
    [file, location] = uigetfile({'*.mat'}, 'Select processing settings file or create one.');
    processingConfigurationFile = [location file];
end

if (processingConfigurationFile(1) == 0 || ~exist(processingConfigurationFile, 'file'))
    disp('No processing configuration selected, aborting!');
    return;
end

load(processingConfigurationFile);

inputRootFolders = '';

%% recursively find the valid input paths
[inputFolders, experimentList, positionList] = callback_livecellminer_get_valid_input_paths(configuration.inputFolders);
outputRoot = configuration.outputRoot;

%% open log file for saving the performance
performanceLog = fopen([outputRoot 'performanceLog.csv'], 'wb');

for i=1:length(inputFolders)

    %% clear the temporary settings variable
    parameters = struct();
       
    parameters.XPIWITPath = XPIWITPath;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% project-specific parameters and selection of algrithms to use for processing
    parameters.useCellpose = configuration.useCellpose; %% if enabled, the cellpose algorithm will be used for segmentation instead of the threshold/watershed default algorithm

    parameters.reprocessCellpose = configuration.reprocessCellpose;
    parameters.reprocessDetection = configuration.reprocessDetection;
    parameters.reprocessTracking = configuration.reprocessTracking;

    parameters.seedBasedDetection = configuration.seedBasedDetection;             %% if enabled, LoGSSMP seeds will be used. Otherwise, cell pose segmentation results will be used.
    parameters.useTWANG = configuration.useTWANG;                       %% if enabled, TWANG segmentation is used as a backup for cellpose (only during tracking!!)
    parameters.writeImagePatches = false;             %% if enabled, small image patches will be written separately to disk
    parameters.trackingMethod = configuration.trackingMethod;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% the following folder structure is assumed and used to later group the data:
    %% %EXPERIMENT%/%POSITION%/%IMAGEFILES%.tif
    parameters.inputFolder = inputFolders{i};
    parameters.outputRoot = outputRoot;
    parameters.inputFolderCellpose = parameters.inputFolder;

    %% extract project information
    splitString = strsplit(parameters.inputFolder(1:end-1), '/');
    parameters.experimentName = splitString{end-1};
    parameters.positionNumber = splitString{end};
    
    for j=1:length(experimentList)
        if (strcmp(experimentList{j}, parameters.experimentName))
            experimentIndex = j;
            break;
        end
    end

    parameters.frameInterval = configuration.experimentParameters{experimentIndex, 2};    %% the time interval between two successive frames in minutes
    parameters.micronsPerPixel = configuration.experimentParameters{experimentIndex, 3};  %% the physical spacing in microns. Note that the seed detection pipelines are selected with this string, so should have consistent number of digits that match the names of the XML pipelines.
    parameters.channelFilter = configuration.experimentParameters{experimentIndex, 4};    %% select a specific channel for processing. Should be specific part of the file name
    parameters.channelFilter2 = configuration.experimentParameters{experimentIndex, 5};   %% select an additional channel. This channel will only be used to extract the corresponding snippets as well for later processing.
    
    %% assemble and create the output folder
    parameters.outputFolder = [parameters.outputRoot '/' parameters.experimentName '/' parameters.positionNumber '/'];
    if (~isfolder(parameters.outputFolder)); mkdir(parameters.outputFolder); end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% advanced parameters (usually no need for change)
    parameters.framesBeforeIP = round(configuration.minutesBeforeMA / parameters.frameInterval);     %% the number of frames to extract before the division event
    parameters.framesAfterMA = round(configuration.minutesAfterMA / parameters.frameInterval);      %% the number of frames to extract after the division event
    parameters.timeWindowMother = round(configuration.minutesBeforeMA / parameters.frameInterval);   %% the number of frames to extract before the division event
    parameters.timeWindowDaughter = round(configuration.minutesAfterMA / parameters.frameInterval);  %% the number of frames to extract after the division event
    parameters.singleCellCCDisableRadius = 3;     %% the number of frames before/after the division time point where the single connected component segmentation is disabled (used for early ana segmentation)
    parameters.patchWidth = 96;                   %% patch width used for extracting the image snippets
    parameters.patchRescaleFactor = 0.415;        %% use spacing of confocal images as reference, i.e., they remain unscaled whereas widefield images are enlarged to ideally have a single cell in the center
    parameters.diameterCellpose = configuration.diameterCellpose;  %% diameter parameter used for the cellpose segmentation
    parameters.clusterRadiusIndex = 9;            %% index to the cluster radius feature
    parameters.trackingIdIndex = 10;              %% index to the tracking id
    parameters.predecessorIdIndex = 11;           %% index to the predecessor
    parameters.posIndices = 3:5;                  %% indices to the positions
    parameters.prevPosIndices = 6:8;              %% indices to the previous positions

    if (configuration.clusterCutoff > 0)
        parameters.clusterCutoff = configuration.clusterCutoff / parameters.micronsPerPixel; %% cluster cutoff (-1 for automatic detection based on 0.5 * average nearest neighbor distance of the 8 nearest neighbors)
    end
    parameters.forceNNLinking = configuration.forceNNLinking;
    parameters.maxRadius = configuration.maxRadius / parameters.micronsPerPixel;  %% maximum radius to search for neighboring cells during tracking
    parameters.numFrames = inf;                   %% number of frames in the entire sequence
    parameters.numRefinementSteps = 0;            %% if larger than 0, multiple rounds of centroid relocation to the weighted centroid are performed
    parameters.refinementRadius = 5;              %% radius for computing the weighted centroid
    parameters.allowedEmptyFrames = 2;            %% the maximum number of allowed empty frames. If an empty frame is encountered, the detections of the next frame are used.
    parameters.debugFigures = false;              %% if enabled, debug figures will be shown
    parameters.logMinSigma = 0.5*(configuration.minNucleusDiameter)/sqrt(2);
    parameters.logMaxSigma = 0.5*(configuration.maxNucleusDiameter)/sqrt(2);
    parameters.seedDetectionStdThreshold = configuration.seedDetectionStdThreshold; %% LoG-based seed detection uses only seeds that exceed the mean intensity + x*stdDev.
    parameters.XPIWITDetectionPipeline = callback_livecellminer_create_xpiwit_pipeline(parameters.logMinSigma, parameters.logMaxSigma, parameters.seedDetectionStdThreshold, parameters.micronsPerPixel);
    
    if (parameters.diameterCellpose < 0)
        parameters.diameterCellpose = 0.5 * ((configuration.minNucleusDiameter / parameters.micronsPerPixel) + (configuration.maxNucleusDiameter / parameters.micronsPerPixel));
    end

    if (~exist(parameters.XPIWITDetectionPipeline, 'file'))
        disp(['ERROR: Couldn''t find processing pipeline ' parameters.XPIWITDetectionPipeline ' . Make sure the file exists or create a pipeline for the selected physical spacing!']);
    end

    parameters.CELLPOSEEnvironment = CELLPOSEEnvironment; %'/work/scratch/stegmaier/Software/Environments/cellpose/bin/python';
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% TMP !!!! %%%%
    %parameters.reprocessTracking = true;
    %parameters.trackingMethod = 'Ultrack';
    %parameters.trackingMethod = 'Seed Clustering';
    %%% END TMP !!! %%%%


    %% skip processing if the project already exists
    [~, filesExist] = callback_livecellminer_generate_output_paths(parameters);
    if (~filesExist.project || ...
        parameters.reprocessDetection || ...
        parameters.reprocessCellpose || ...
        parameters.reprocessTracking)
    
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