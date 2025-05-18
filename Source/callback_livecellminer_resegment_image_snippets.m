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

compressionLevel = 0;

%% add external scripts to path
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'haralick' filesep]);
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'saveastiff_4.3' filesep]);

%% get the root directory of the projects to import
inputRootFolder = cell(1,1);
inputRootFolder{1} = parameter.projekt.pfad;
if (~isfolder(inputRootFolder{1}))
    inputRootFolder{1} = uigetdir();
end
inputRootFolder{1} = [inputRootFolder{1} filesep];

experimentOutputVariable = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
positionOutputVariable = callback_livecellminer_find_output_variable(bez_code, 'Position');

%% check if current input folder is part of the project
experimentIDs = unique(code_alle(:,experimentOutputVariable));
positionIDs = unique(code_alle(:,positionOutputVariable));

answer = questdlg('Select single-cell segmentation method to be applied to the image snippets.', 'Segmentation Method?', 'Cellpose', 'Watershed', 'Cancel', 'Cancel');
if (strcmp(answer, 'Cellpose') || strcmp(answer, 'Watershed'))
    reprocessSegmentation = true;
    useCellpose = strcmp(answer, 'Cellpose');
else
    return;
end

if (reprocessSegmentation == true)
    recomputedFeatureIds = [];
    if (useCellpose == true)
        cp = cellpose(Model='nuclei');
    end

    pretrainedNet = googlenet;
    activationLayerName = 'loss3-classifier';
    inputSize = pretrainedNet.Layers(1).InputSize;
    newImageSize = inputSize(1);
    featureSize = pretrainedNet.Layers(end).OutputSize;
end

clear inputFolders;
currentFolder = 1;

for e=experimentIDs'
    for p=positionIDs'
        experimentName = zgf_y_bez(experimentOutputVariable,e).name;
        positionName = zgf_y_bez(positionOutputVariable,p).name;

        inputFolders{currentFolder} = callback_livecellminer_find_position_folder(inputRootFolder{1}, experimentName, positionName);

        if (isnumeric(inputFolders{currentFolder}) == 0 && isfolder(inputFolders{currentFolder}))
            currentFolder = currentFolder+1;
        end
    end
end


%% import all projects contained in the root folder
f = waitbar(0, 'Initializing ...', 'Name', 'Converting cells ...');
currentCellId = 1;
totalNumCells = size(d_orgs,1);
tic;

for i=1:length(inputFolders)

    fprintf('Attempting to convert image data base %s ...\n', inputFolders{i});

    %% get the current input folder
    currentInputFolder = inputFolders{i};   

    if (isnumeric(currentInputFolder))
        continue;
    end
    
    %% identify experiment and position names
    splitString = strsplit(currentInputFolder(1:end-1), '/');
    experimentName = splitString{end-1};
    positionName = splitString{end};

    experimentIDs = unique(code_alle(:,experimentOutputVariable));
    positionIDs = unique(code_alle(:,positionOutputVariable));
    
    experimentId = 0;
    positionId = 0;
    
    for e=experimentIDs'
        for p=positionIDs'
            
            if (strcmp(zgf_y_bez(experimentOutputVariable,e).name, experimentName) && ...
                strcmp(zgf_y_bez(positionOutputVariable,p).name, positionName))
                experimentId = e;
                positionId = p;
            end
        end
    end

    %% perform consistency check
    currentIndices = find(code_alle(:,experimentOutputVariable) == experimentId & code_alle(:,positionOutputVariable) == positionId);

    if (isempty(currentIndices))
        continue;
    end

    %% construct the output name based on the current project name
    outputFileName = callback_livecellminer_get_image_data_base_filename(currentIndices(1), parameter, code_alle, zgf_y_bez, bez_code);
    
    % if (exist(outputFileName, 'file'))
    %     if (reprocessSegmentation == true)
    %         delete(outputFileName);
    %     else
    %         fprintf('File %s already exists, skipping recreation. To force recreation, manually delete  the file!\n', outputFileName);
    %         continue;
    %     end
    % end

    %% identify the number of cells
    numCells = length(currentIndices);
    numFrames = size(d_orgs,2);
    recomputedFeatures = zeros(numFrames, 22);
    [recomputedFeatureNames, ~] = callback_livecellminer_extract_nucleus_features(zeros(96,96), zeros(96,96)); 

    
    for c=1:numCells

        imageDataBase = callback_livecellminer_get_image_data_base_filename(currentIndices(c), parameter, code_alle, zgf_y_bez, bez_code);

        currRawImage = double(h5read(imageDataBase, callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'raw')));
        prevMaskImage = h5read(imageDataBase, callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'mask'));
        prevCNNFeatures = h5read(imageDataBase, callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'cnn'));

        nextMaskImage = zeros(size(prevMaskImage));
        nextCNNFeatures = zeros(size(prevCNNFeatures));

        imageSize = [size(prevMaskImage,1), size(prevMaskImage,2)];

        parfor j=1:numFrames

            if (j== 25)
                test = 1;
            end

            %% perform cellpose segmentation on the raw patch of channel 1
            if (useCellpose == true)
                currentSegmentation = cp.segmentCells2D(imadjust(uint16(currRawImage(:,:,j))));
            else
                currentSegmentation = callback_livecellminer_segment_center_nucleus(imadjust(uint16(currRawImage(:,:,j))), true);
            end

            %% identify label that maximally overlaps with the previous segmentation
            [counts, labels] = groupcounts(currentSegmentation(prevMaskImage(:,:,j) > 0));
            [maxValue, maxIndex] = max(counts);
            maxLabel = labels(maxIndex);
            previousArea = sum(prevMaskImage(:,:,j) > 0, 'all');
            newArea = sum(currentSegmentation(:) == maxLabel);

            %% combine previous and current segmentation or fall back to previous one if cellpose failed
            if (isempty(find(currentSegmentation > 0, 1)) || newArea < (0.5*previousArea))
                currentSegmentation = prevMaskImage(:,:,j);
            elseif (maxLabel == 0) %% centroid not located on one of the daughters. In this case, just pick one daughter!
                
                currentRegionProps = regionprops(currentSegmentation, 'Centroid');

                minDistance = inf;
                minIndex = 0;

                for k=1:length(currentRegionProps)
                    centroidDistance = norm(currentRegionProps(k).Centroid - (imageSize / 2));

                    if (centroidDistance < minDistance)
                        minDistance = centroidDistance;
                        minIndex = k;
                    end
                end

                currentSegmentation = uint16(currentSegmentation == minIndex);
            else
                currentSegmentation = uint16(currentSegmentation == maxLabel | prevMaskImage(:,:,j));
            end

            %% extract nucleus features
            [featureNames, featureVector] = callback_livecellminer_extract_nucleus_features(uint16(currRawImage(:,:,j)), currentSegmentation); 
            recomputedFeatures(j,:) = featureVector;
                
            % figure(2);
            % subplot(1,3,1);
            % imagesc(finalRawImagePatches{c,j});
            % 
            % subplot(1,3,2);
            % imagesc(finalMaskImagePatches{c,j});
            % 
            % subplot(1,3,3);
            % imagesc(currentSegmentation);

            nextMaskImage(:,:,j) = currentSegmentation;
            
        end

        toc

        %% update the entries in d_orgs
        if (reprocessSegmentation == true)
            if (isempty(recomputedFeatureIds))
                for j=1:size(recomputedFeatureNames, 1)
                    for k=1:size(var_bez,1)
                        if (strcmp(kill_lz(recomputedFeatureNames(j,:)), kill_lz(var_bez(k,:))))
                            recomputedFeatureIds = [recomputedFeatureIds, k];
                            break;
                        end
                    end
                end
            end

            d_orgs(currentIndices(c), :, recomputedFeatureIds) = recomputedFeatures;
        end

        %% load CNN features or create them if not existing yet/if segmentation was recomputed
        if (reprocessSegmentation == true)
            
            %% assemble the training image for all frames
            currentImage = currRawImage .* nextMaskImage;
            currentImageResized = imresize3(currentImage, [newImageSize, newImageSize, numFrames], 'linear');
            
            %% create a 3-channel image containing the resized image patches for each frame
            trainingImages = ones(newImageSize, newImageSize, 3, numFrames);
            trainingImages(:,:,1,:) = currentImageResized;
            trainingImages(:,:,2,:) = currentImageResized;
            trainingImages(:,:,3,:) = currentImageResized;
            
            %% compute the CNN features
            nextCNNFeatures = activations(pretrainedNet, trainingImages, activationLayerName, 'OutputAs', 'rows')';
        end
    
        outputStringRaw = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'raw');
        outputStringRaw2 = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'raw2');
        outputStringMask = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'mask');
        outputStringCNNFeatures = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, bez_code, zgf_y_bez, 'cnn');
    
        %h5create(outputFileName, outputStringRaw, size(outputTensorRaw), 'Datatype', 'uint16'); %% , 'ChunkSize', size(outputTensorRaw), 'Deflate', compressionLevel
        %h5write(outputFileName, outputStringRaw, outputTensorRaw);
    
        %if (hasSecondChannel)
        %    h5create(outputFileName, outputStringRaw2, size(outputTensorRaw2), 'Datatype', 'uint16'); %% , 'ChunkSize', size(outputTensorRaw2), 'Deflate', compressionLevel
        %    h5write(outputFileName, outputStringRaw2, outputTensorRaw2);
        %end
    
        %h5create(outputFileName, outputStringMask, size(outputTensorMask), 'Datatype', 'uint8'); %% , 'ChunkSize', size(outputTensorMask), 'Deflate', compressionLevel
        h5write(outputFileName, outputStringMask, uint8(nextMaskImage > 0));
    
        %h5create(outputFileName, outputStringCNNFeatures, size(outputTensorCNN), 'Datatype', 'single'); %% , 'ChunkSize', size(outputTensorCNN), 'Deflate', compressionLevel
        h5write(outputFileName, outputStringCNNFeatures, single(nextCNNFeatures));
    
        if (mod(c,100) == 1)
            fprintf('Finished converting %i / %i cells to the HDF5 file ...\n', c, numCells);
        end

        currentCellId = currentCellId + 1;

        elapsedTime = toc;
        timePerCell = elapsedTime / currentCellId / 60;
        remainingTime = timePerCell * (totalNumCells - currentCellId);

        f = waitbar(currentCellId/totalNumCells, f, sprintf('Processing cell %i / %i (about %.2f minutes left ...)', currentCellId, totalNumCells, remainingTime), 'Name', 'Converting cells ...');
    end

    
    %% success message
    fprintf('Converted image data base saved to %s\n', outputFileName);
    fprintf('Successfully converted image patches of experiment %s, plate %s.\n', experimentName, positionName);
end

%% apply physical spacing to convert all pixel measures into microns
%% all images are scaled upon import to spacing of 0.415 (spacing of the confocal).
%% thus, using this scale factor for length and area measurements fits all projects.
if (reprocessSegmentation == true)
    
    minorAxisLenghtID = callback_livecellminer_find_time_series(var_bez, 'MinorAxisLength');
    majorAxisLengthID = callback_livecellminer_find_time_series(var_bez, 'MajorAxisLength');
    areaID = callback_livecellminer_find_time_series(var_bez, 'Area');
    d_orgs(:,:,minorAxisLenghtID) = d_orgs(:,:,minorAxisLenghtID) * parameter.projekt.patchRescaleFactor; %% as the image patches were rescaled with parameters.patchRescaleFactor
    d_orgs(:,:,majorAxisLengthID) = d_orgs(:,:,majorAxisLengthID) * parameter.projekt.patchRescaleFactor; %% as the image patches were rescaled with parameters.patchRescaleFactor
    d_orgs(:,:,areaID) = d_orgs(:,:,areaID) * (parameter.projekt.patchRescaleFactor^2); %% as the image patches were rescaled with parameters.patchRescaleFactor
end

%% close the progress bar
close(f);

if (reprocessSegmentation == true)
    next_function_parameter = [parameter.projekt.pfad filesep parameter.projekt.datei '_RecomputedSegmentation.prjz'];
    disp(['Saving project with reprocessed segmentation at ' next_function_parameter]);
    saveprj_g;

    answer = questdlg('Directly load new project?');
    if (strcmp(answer, 'Yes'))
        next_function_parameter = [parameter.projekt.pfad filesep parameter.projekt.datei '.prjz'];
        ldprj_g;
    end
end