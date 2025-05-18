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

function [] = callback_livecellminer_import_project(parameters)

	%% get the input and output folders
    inputFolder = parameters.inputFolder;
    outputFolder = parameters.outputFolder;

    %% derived parameters
    parameters.imageFilter = ['*' parameters.channelFilter '*.tif'];        %% image filter to select only the image files
    parameters.imageFilter2 = ['*' parameters.channelFilter2 '*.tif'];        %% image filter to select only the image files
    parameters.detectionFilter = ['*' parameters.channelFilter '*.csv'];    %% detection filter to select only the CSV files corresponding to the detections
    parameters.twangSegFilter = ['*' parameters.channelFilter '*.tif'];    %% filter for the twang segmentations
    parameters.maskFilter = ['*' parameters.channelFilter '*.png'];         %% mask filter to select only the files corresponding to the masks
    
    parameters.imageFilter = strrep(parameters.imageFilter, '**', '*');
    parameters.imageFilter2 = strrep(parameters.imageFilter2, '**', '*');
    parameters.detectionFilter = strrep(parameters.detectionFilter, '**', '*');
    parameters.twangSegFilter = strrep(parameters.twangSegFilter, '**', '*');
    parameters.maskFilter = strrep(parameters.maskFilter, '**', '*');

    %% output directories for seeds and segmentation
    outputFolderSeeds = [outputFolder 'Detections/'];
    if (~isfolder(outputFolderSeeds)); mkdir(outputFolderSeeds); end
    
    %% result folders
    parameters.twangFolder = [outputFolderSeeds 'item_0006_TwangSegmentation/'];
    parameters.detectionFolder = [outputFolderSeeds 'item_0005_ExtractSeedBasedIntensityWindowFilter/'];
    parameters.detectionExtension = '_ExtractSeedBasedIntensityWindowFilter_.csv';
    
    %% setup output folders
    %parameters.maskFolder = [parameters.outputFolder 'Masks/'];
    %if (~isfolder(parameters.maskFolder)); mkdir(parameters.maskFolder); end

    parameters.augmentedMaskFolder = [parameters.outputFolder 'AugmentedMasks/'];
    if (~isfolder(parameters.augmentedMaskFolder)); mkdir(parameters.augmentedMaskFolder); end

    %% perform seed detection
    oldPath = pwd;
    cd(parameters.XPIWITPath);
    
    inputFiles = dir([inputFolder parameters.imageFilter]);
    numInputFiles = length(inputFiles);
    
    %% parfor seems to skip files occasionally, thus perform two consistency runs to be sure all files are present.
    for c=1:3
        parfor f=1:numInputFiles

            [~, ~, ext] = fileparts(inputFiles(f).name);        
            currentOutputFile = [parameters.detectionFolder strrep(inputFiles(f).name, ext, parameters.detectionExtension)]; %#ok<PFBNS> 

            if (isfile(currentOutputFile) && ~parameters.reprocessDetection)
                continue;
            end

            %% specify the XPIWIT command
            XPIWITCommand = ['./XPIWIT.sh --output "' outputFolderSeeds '" --input "0, ' inputFolder inputFiles(f).name ', 2, float" --xml "' parameters.XPIWITDetectionPipeline '" --seed 0 --lockfile off --subfolder "filterid, filtername" --outputformat "imagename, filtername" --end'];

            %% replace slashes by backslashes for windows systems
            if (ispc == true)
                XPIWITCommand = strrep(XPIWITCommand, './XPIWIT.sh', 'XPIWIT.exe');
                XPIWITCommand = strrep(XPIWITCommand, '\', '/');
            end
            system(XPIWITCommand);
        end
    end
    cd(oldPath);

    %% perform cell pose segmentation (optional)
    if (parameters.useCellpose == true)
        parameters.outputFolderCellPose = [outputFolder 'Cellpose/'];
        outputDataExists = true;
        if (~isfolder(parameters.outputFolderCellPose))
            mkdir(parameters.outputFolderCellPose);
            outputDataExists = false;
        else
            %% check if output images already exist
            if (~isempty(parameters.channelFilter))
                inputFiles = dir([inputFolder '*' parameters.channelFilter '*.tif']);
            else
                inputFiles = dir([inputFolder '*.tif']);
            end
            outputFiles = dir([parameters.outputFolderCellPose '*_cp_masks.png']);
            numInputFiles = length(inputFiles);
            numOutputFiles = length(outputFiles);
            
            if (numInputFiles > numOutputFiles || numOutputFiles == 0 || numInputFiles == 0)
                outputDataExists = false;
            else
                for i=1:length(inputFiles)
                    if (~strcmp(strrep(lower(inputFiles(i).name), '.tif', ''), strrep(lower(outputFiles(i).name), '_cp_masks.png', '')))
                        outputDataExists = false;
                        break;
                    end
                end
            end
        end
                
        %% only process if data does not exist yet
        if (outputDataExists == false || parameters.reprocessCellpose)
            parameters.maskFolder = parameters.outputFolderCellPose;

            CELLPOSEFilter = '';
            if (~isempty(parameters.channelFilter))
                CELLPOSEFilter = [' --img_filter ' parameters.channelFilter];
            end

            useMATLABCellpose = true;
            if (useMATLABCellpose == true)
                cellposeInstance = cellpose(Model='nuclei');

                %% check if output images already exist
                if (~isempty(parameters.channelFilter))
                    inputFiles = dir([inputFolder '*' parameters.channelFilter '*.tif']);
                else
                    inputFiles = dir([inputFolder '*.tif']);
                end

                numInputFiles = length(inputFiles);

                for f=1:numInputFiles
                    currentImage = imadjust(imread([inputFolder inputFiles(f).name]));
                    currentLabelImage = segmentCells2D(cellposeInstance, currentImage, ImageCellDiameter=parameters.diameterCellpose);
                    imwrite(uint16(currentLabelImage), [parameters.outputFolderCellPose strrep(inputFiles(f).name, '.tif', '_cp_masks.png')]);
                end
            else
                %% removed model_dir as parameter to just use the default location for the models where cell pose downloads it to "--model_dir ' parameters.CELLPOSEModelDir"
                %% if cellpose does not find the models or if downloading is not permitted, manually install the models to C:\Users\MY_USER_NAME\.cellpose\models
                %% Moreover, add environment variable "CELLPOSE_LOCAL_MODELS_PATH" pointing to the models directory "C:\Users\MY_USER_NAME\.cellpose\models"
                CELLPOSECommand = [parameters.CELLPOSEEnvironment ' -m cellpose --dir ' parameters.inputFolderCellpose ' --chan 0 ' CELLPOSEFilter ' --pretrained_model nuclei --savedir ' parameters.outputFolderCellPose ' --diameter ' num2str(parameters.diameterCellpose) ' --use_gpu --save_png --no_npy'];
                system(CELLPOSECommand);
            end
        end
    end

    %% perform feature extraction, tracking and project generation
    callback_livecellminer_perform_detection_and_tracking(parameters);
end