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

%% get the export selection stored in variable "ind_auswahl_valid"
callback_livecellminer_get_export_selection;
selectedIndices = ind_auswahl;

%% get the output directory
outputRoot = uigetdir('', 'Please select a folder to export the data to ...');
if (outputRoot == 0)
    disp('No valid output directory selected. Please select a proper path where you have write permissions!');
    return;
end
outputRoot = [outputRoot filesep];

%% get the synchronization time series
manualSynchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

if (manualSynchronizationIndex <= 0)
    disp('No synchronization information was found! Please run the synchronization first, e.g., using LiveCellMiner -> Align -> Perform Auto Sync or via the manual synchronization GUI');
    return;
end

numFrames = size(d_orgs,2);

outputFolder = [outputRoot parameter.projekt.datei filesep];
if (~exist(outputFolder, 'dir')); mkdir(outputFolder); end

%% iterate over all selected indices and export them
for i=selectedIndices'
   
    if (sum(squeeze(d_orgs(i,:,manualSynchronizationIndex)) <= 0) > 0)
        continue;
    end

    %% specify filename for the image data base
    imageDataBase = callback_livecellminer_get_image_data_base_filename(i, parameter, code_alle, zgf_y_bez, bez_code);
    if (~exist(imageDataBase, 'file'))
        fprintf('Image database file %s not found. Starting the conversion script to have it ready next time. Please be patient!', imageDataBase);
        callback_livecellminer_convert_image_files_to_hdf5;
    end
   
    currentOutputFolderCSV = [outputFolder sprintf('cell_id=%05d', i) filesep sprintf('cell_id=%05d_Synchronization.csv', i)]; 
    currentOutputFolderRaw = [outputFolder sprintf('cell_id=%05d', i) filesep 'Raw' filesep];
    currentOutputFolderMask = [outputFolder sprintf('cell_id=%05d', i) filesep 'Mask' filesep];
    
    mkdir(currentOutputFolderMask);
    mkdir(currentOutputFolderRaw);

    currentRawImage = h5read(imageDataBase, callback_livecellminer_create_hdf5_path(i, code_alle, bez_code, zgf_y_bez, 'raw'));
    currentMaskImage = h5read(imageDataBase, callback_livecellminer_create_hdf5_path(i, code_alle, bez_code, zgf_y_bez, 'mask'));

    %% save images for each frame
    for j=1:numFrames
        
        currentImage = imresize(currentRawImage(:,:,j), [96, 96], 'bilinear');
        currentMask = imresize(currentMaskImage(:,:,j), [96, 96], 'nearest');
        
        outputPathImage = [currentOutputFolderRaw sprintf('cell_id=%05d_t=%03d_Raw.png', i, j)];
        outputPathMask = [currentOutputFolderMask sprintf('cell_id=%05d_t=%03d_Mask.png', i, j)];
        
        imwrite(uint16(currentImage), outputPathImage);
        imwrite(uint8(currentMask), outputPathMask);
        
    end
    
    %% save csv file with the stages
    dlmwrite(currentOutputFolderCSV, squeeze(d_orgs(i,:,manualSynchronizationIndex)), ';');

    sprintf('Finished exporting cell %i / %i', i, length(selectedIndices))
end