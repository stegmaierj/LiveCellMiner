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

function [] = callback_livecellminer_import_project(parameters)

	%% get the input and output folders
    inputFolder = parameters.inputFolder;
    outputFolder = parameters.outputFolder;

    %% derived parameters
    parameters.imageFilter = [parameters.channelFilter '*.tif'];        %% image filter to select only the image files
    parameters.imageFilter2 = [parameters.channelFilter2 '*.tif'];        %% image filter to select only the image files
    parameters.detectionFilter = [parameters.channelFilter '*.csv'];    %% detection filter to select only the CSV files corresponding to the detections
    parameters.maskFilter = [parameters.channelFilter '*.png'];         %% mask filter to select only the files corresponding to the masks

    %% output directories for seeds and segmentation
    outputFolderSeeds = [outputFolder 'Detections/'];
    if (~isfolder(outputFolderSeeds)); mkdir(outputFolderSeeds); end
    
    %% result folders
    parameters.detectionFolder = [outputFolderSeeds 'item_0005_ExtractSeedBasedIntensityWindowFilter/'];
    parameters.detectionExtension = '_ExtractSeedBasedIntensityWindowFilter_.csv';
    parameters.maskFolder = '';

    %% perform seed detection
    oldPath = pwd;
    cd(parameters.XPIWITPath);
    
    inputFiles = dir([inputFolder '*.tif']);
    numInputFiles = length(inputFiles);
    
    parfor f=1:numInputFiles
        
        [~, ~, ext] = fileparts(inputFiles(f).name);        
        currentOutputFile = [parameters.detectionFolder strrep(inputFiles(f).name, ext, parameters.detectionExtension)];
        
        if (isfile(currentOutputFile))
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
    
    cd(oldPath);

    %% perform cell pose segmentation (optional)
    if (parameters.useCellpose == true)
        parameters.outputFolderCellPose = [outputFolder 'Cellpose/'];
        outputDataExists = true;
        if (~isfolder(parameters.outputFolderCellPose))
            mkdir(parameters.outputFolderCellPose); 
        else
            %% check if output images already exist
            inputFiles = dir([inputFolder '*.tif']);
            outputFiles = dir([parameters.outputFolderCellPose '*_cp_masks.png']);
            numInputFiles = length(inputFiles);
            numOutputFiles = length(outputFiles);
            
            if (numInputFiles > numOutputFiles)
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
        if (outputDataExists == false)
            parameters.maskFolder = parameters.outputFolderCellPose;
            cd(parameters.CELLPOSEPath);

            CELLPOSEFilter = '';
            if (~isempty(parameters.channelFilter))
                CELLPOSEFilter = [' --img_filter ' parameters.channelFilter];
            end

            CELLPOSECommand = [parameters.CELLPOSEEnvironment ' -m cellpose --dir ' parameters.inputFolderCellpose ' --chan 0 --model_dir ' parameters.CELLPOSEModelDir CELLPOSEFilter ' --pretrained_model nuclei --output_dir ' parameters.outputFolderCellPose ' --diameter 30 --use_gpu --save_png'];
            system(CELLPOSECommand);
        end
    end

    %% perform feature extraction, tracking and project generation
    callback_livecellminer_perform_detection_and_tracking(parameters);
end