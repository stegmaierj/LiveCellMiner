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

%% get time series and output variable indices
manualSychronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

%% get the export selection stored in variable "ind_auswahl_valid"
callback_livecellminer_get_export_selection;

ind_auswahl = ind_auswahl(rem(ind_auswahl,2) == 0);
aktparawin;

%% ask for export settings
prompt = {'Maximum Number of Cell Pairs per Position (> 0 for max. number or -1 to export all cells):', ...
          'Export Mode (1 = 2D Gallery per Cell; 2 = 3D Hyperstack per Cell)', ...
          'Random Selection (0 = Use first N cells per position; 1 = Use N random cells per position; 2 = Use N random cells per Oligo)', ...
          'Use Sub-Folders (0 = Save all images to output folder; 1 = create subfolders for each position)'};
dlgtitle = 'Input';
fieldsize = [1 45; 1 45; 1 45; 1 45];
definput = {'-1', '1', '0', '0'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

maxNumberOfCells = str2double(answer{1});
galleryExportMode = str2double(answer{2});
useRandomSelection = str2double(answer{3});
useSubFolders = str2double(answer{4});

ind_auswahl_valid = [];

%% select all cells for gallery generation
if (maxNumberOfCells < 0)
    ind_auswahl_valid = ind_auswahl;

%% select based on experiment and position
elseif (useRandomSelection == 0 || useRandomSelection == 1)

    uniqueExpPosIndices = unique(code_alle(:, [experimentOutputVariable, positionOutputVariable]), 'rows');
    
    for i=1:size(uniqueExpPosIndices)

        [tf, index] = ismember(code_alle(ind_auswahl, [experimentOutputVariable, positionOutputVariable]), uniqueExpPosIndices(i,:), 'rows');

        currentIndices = ind_auswahl(find(index));

        if (useRandomSelection == 0 && maxNumberOfCells < 0)
            ind_auswahl_valid = [ind_auswahl_valid; currentIndices];
        elseif (useRandomSelection == 0 && maxNumberOfCells >= 0)
            ind_auswahl_valid = [ind_auswahl_valid; currentIndices(1:min(maxNumberOfCells, length(currentIndices)))];
        elseif (useRandomSelection == 1 && maxNumberOfCells >= 0)
            randomIndices = currentIndices(randperm(length(currentIndices), min(length(currentIndices), maxNumberOfCells)));
            ind_auswahl_valid = [ind_auswahl_valid; currentIndices(1:min(maxNumberOfCells, length(currentIndices)))];
        end
    end

%% select based on the oligoid
elseif (useRandomSelection == 2 && oligoOutputVariable > 0)

    uniqueOligoIndices = unique(code_alle(:, oligoOutputVariable));

    for o=uniqueOligoIndices'

        currentIndices = ind_auswahl(find(code_alle(ind_auswahl, oligoOutputVariable) == o));

        randomIndices = currentIndices(randperm(length(currentIndices), min(length(currentIndices), maxNumberOfCells)));
        ind_auswahl_valid = [ind_auswahl_valid; currentIndices(1:min(maxNumberOfCells, length(currentIndices)))];
    end
else
    disp('Invalid selection mode, please use an appropriate value from {0, 1, 2}!');
    return;
end

%% add sister cells to each of the selected cells
ind_auswahl_valid = sort([ind_auswahl_valid; (ind_auswahl_valid - 1)]);

%% ask for the output path
outputPath = uigetdir(pwd, 'Please select the output directory for the galleries ...');
if (outputPath(end) ~= filesep)
    outputPath = [outputPath filesep];
end

%% initialize saving options
clear options;
options.overwrite = true;
options.compress = 'lzw';

%% loop through all selected cells and save them
for cell_id = ind_auswahl_valid'

    %% get image data of the current image
    imageDataBase = callback_livecellminer_get_image_data_base_filename(cell_id, parameter, code_alle, zgf_y_bez, bez_code);
    currentRawImage = h5read(imageDataBase, callback_livecellminer_create_hdf5_path(cell_id, code_alle, bez_code, zgf_y_bez, 'raw'));

    %% create the output path
    outputPathCurrentImage = outputPath;

    %% create subfolder if enabled
    if (useSubFolders == 1)
        for i=2:size(code_alle,2)
            outputPathCurrentImage = [outputPathCurrentImage zgf_y_bez(i, code_alle(cell_id, i)).name filesep];
        end
        
        if (~isfolder(outputPathCurrentImage))
            mkdir(outputPathCurrentImage);
        end
    end

    %% create file name
    for i=2:size(code_alle,2)
        outputPathCurrentImage = [outputPathCurrentImage zgf_y_bez(i, code_alle(cell_id, i)).name '_'];
    end

    %% export gallery for the current cells
    if (galleryExportMode == 1)

        %% assemble the gallery image
        numTimePoints = size(currentRawImage, 3);
        imageSize = size(currentRawImage);
        galleryImage = zeros(imageSize(1), numTimePoints*imageSize(2));

        for i=1:numTimePoints
            galleryImage(:, (imageSize(1)*(i-1)+1):(imageSize(1)*(i))) = currentRawImage(:,:,i);
        end        

        %% write result image to disk
        outputPathCurrentImage = [outputPathCurrentImage 'GalleryImage.tif'];
        imwrite(uint16(galleryImage), outputPathCurrentImage)


    %% export 3D stack for the current cells
    else
        
        %% write 3D image to disk
        outputPathCurrentImage = [outputPathCurrentImage 'HyperstackImage.tif'];
        saveastiff(uint16(currentRawImage), outputPathCurrentImage, options);
    end
    
    %% additionally save the synchronization information if it is available
    if (manualSychronizationIndex > 0)
        dlmwrite(strrep(outputPathCurrentImage, '.tif', '.csv'), d_orgs(cell_id, :, manualSychronizationIndex), ';');
    end
end