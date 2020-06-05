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

function [] = callback_chromatindec_import_project(settings)

	%% get the input and output folders
    inputFolder = settings.inputFolder;
    outputFolder = settings.outputFolder;

    %% derived parameters
    settings.imageFilter = [settings.channelFilter '*.tif'];        %% image filter to select only the image files
    settings.detectionFilter = [settings.channelFilter '*.csv'];    %% detection filter to select only the CSV files corresponding to the detections
    settings.maskFilter = [settings.channelFilter '*.png'];         %% mask filter to select only the files corresponding to the masks

    %% output directories for seeds and segmentation
    outputFolderSeeds = [outputFolder 'Detections/'];
    if (~isfolder(outputFolderSeeds)); mkdir(outputFolderSeeds); end

    %% result folders
    settings.detectionFolder = [outputFolderSeeds 'item_0005_ExtractSeedBasedIntensityWindowFilter/'];
    settings.maskFolder = '';

    %% perform seed detection
    oldPath = pwd;
    cd(settings.XPIWITPath);
    
    %% specify the XPIWIT command
    XPIWITCommand = ['./XPIWIT.sh --output "' outputFolderSeeds '" --input "0, ' inputFolder ', 2, float" --xml "' settings.XPIWITDetectionPipeline '" --seed 0 --lockfile off --subfolder "filterid, filtername" --outputformat "imagename, filtername" --end'];

    %% replace slashes by backslashes for windows systems
    if (ispc == true)
        XPIWITCommand = strrep(XPIWITCommand, './XPIWIT.sh', 'XPIWIT.exe');
        XPIWITCommand = strrep(XPIWITCommand, '\', '/');
    end
    system(XPIWITCommand);
    cd(oldPath);

    %% perform cell pose segmentation (optional)
    if (settings.useCellpose == true)
        outputFolderCellpose = [outputFolder 'Cellpose/'];
        if (~isfolder(outputFolderCellpose)); mkdir(outputFolderCellpose); end
        settings.maskFolder = outputFolderCellpose;
        cd(settings.CELLPOSEPath);
        
        CELLPOSEFilter = '';
        if (~isempty(settings.channelFilter))
            CELLPOSEFilter = [' --img_filter ' settings.channelFilter];
        end
        
        CELLPOSECommand = ['python -m cellpose --dir ' inputFolder ' --chan 0 --model_dir ' settings.CELLPOSEModelDir CELLPOSEFilter ' --pretrained_model nuclei --output_dir ' outputFolderCellpose ' --diameter 30 --use_gpu --save_png'];
        system(CELLPOSECommand);
    end

    %% perform feature extraction, tracking and project generation
    callback_chromatindec_perform_detection_and_tracking(settings);
end