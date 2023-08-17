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

%% get the root directory of the projects to import
inputRootFolder = cell(1,1);
inputRootFolder{1} = parameter.projekt.pfad;
if (~isfolder(inputRootFolder{1}))
    inputRootFolder{1} = uigetdir();
end
inputRootFolder{1} = [inputRootFolder{1} filesep];

%% check if current input folder is part of the project
microscopeIDs = unique(code_alle(:,2));
experimentIDs = unique(code_alle(:,3));
positionIDs = unique(code_alle(:,4));

clear inputFolders;
currentFolder = 1;

for m=microscopeIDs'
    for e=experimentIDs'
        for p=positionIDs'
            microscopeName = zgf_y_bez(2,m).name;
            experimentName = zgf_y_bez(3,e).name;
            positionName = zgf_y_bez(4,p).name;

            inputFolders{currentFolder} = callback_livecellminer_find_position_folder(inputRootFolder{1}, microscopeName, experimentName, positionName);
    
%             inputFolders{currentFolder} = strrep(inputRootFolder{1}, '\', '/');
%     
%             isInMicroscopeFolder = contains(parameter.projekt.pfad, microscopeName);
%             isInExperimentFolder = contains(parameter.projekt.pfad, experimentName);
% 
%             if (~isInMicroscopeFolder)
%                 inputFolders{currentFolder} = [inputFolders{currentFolder} microscopeName filesep];
%             end
% 
%             if (~isInExperimentFolder)
%                 inputFolders{currentFolder} = [inputFolders{currentFolder} experimentName filesep];
%             end
%     
%             inputFolders{currentFolder} = strrep([inputFolders{currentFolder} positionName filesep], '\', '/');
    
            if (isfolder(inputFolders{currentFolder}))
                currentFolder = currentFolder+1;
            end
        end
    end
end

%% import all projects contained in the root folder
for i=1:length(inputFolders)

    fprintf('Attempting to convert image data base %s ...\n', inputFolders{i});

    %% get the current microscope
    currentInputFolder = inputFolders{i};    
    
    %% identify microscope, experiment and position names
    splitString = strsplit(currentInputFolder(1:end-1), '/');
    microscopeName = splitString{end-2};
    experimentName = splitString{end-1};
    positionName = splitString{end};

    microscopeIDs = unique(code_alle(:,2));
    experimentIDs = unique(code_alle(:,3));
    positionIDs = unique(code_alle(:,4));
    
    microscopeId = 0;
    experimentId = 0;
    positionId = 0;
    
    for m=microscopeIDs'
        for e=experimentIDs'
            for p=positionIDs'
                
                if (strcmp(zgf_y_bez(2,m).name, microscopeName) && ...
                    strcmp(zgf_y_bez(3,e).name, experimentName) && ...
                    strcmp(zgf_y_bez(4,p).name, positionName))
                    microscopeId = m;
                    experimentId = e;
                    positionId = p;
                end
            end
        end
    end

    %%[microscopeId, experimentId, positionId] = callback_livecellminer_get_output_variables(microscopeList, experimentList, positionList, microscopeName, experimentName, positionName);
    
    %% load the image patches
    load([currentInputFolder experimentName '_' positionName '_RawImagePatches.mat'], '-mat');
    load([currentInputFolder experimentName '_' positionName '_RawImagePatches2.mat'], '-mat');
    load([currentInputFolder experimentName '_' positionName '_MaskImagePatches.mat'], '-mat');
    
    %% perform consistency check
    currentIndices = find(code_alle(:,3) == experimentId & code_alle(:,4) == positionId);
    
    numCells = 0;
    for k=1:size(finalRawImagePatches, 1)
        if (~isempty(finalRawImagePatches{k, 1}))
            numCells = numCells+1;
        else
            test = 1;
        end
    end
    
    if (numCells ~= length(currentIndices))
        disp(['Mismatch in number of image patches vs. number of cells detected for ' experimentName '_' positionName ', ' num2str(numCells) ' vs. ' num2str(length(currentIndices)) ' !!']);
    end

    %% identify the number of cells
    numCells = length(currentIndices);
    patchWidth = size(finalRawImagePatches{1,1}, 1);
    
    %% load CNN features or create them if not existing yet
    cnnFeatureName = [currentInputFolder experimentName '_' positionName '_MaskedImageCNNFeatures.mat'];
    if (exist(cnnFeatureName, 'file'))
        load(cnnFeatureName, '-mat');
    else
        finalMaskedImageCNNFeatures = cell(numCells, numFrames);
        
        f = waitbar(0, ['Computing CNN features for ' experimentName '_' positionName ' ...']);
        for k=1:numCells
            
            %% skip empty cells
            if (isempty(finalRawImagePatches{k,1}))
                continue;
            end
            
            %% assemble the training image for all frames
            currentImage = zeros(patchWidth, patchWidth, numFrames);
            for l=1:numFrames
                currentImage(:,:,l) = finalRawImagePatches{k,l} .* finalMaskImagePatches{k,l};
            end
            currentImageResized = imresize3(currentImage, [newImageSize, newImageSize, numFrames], 'linear');
            
            %% creaet a 3-channel image containing the resized image patches for each frame
            trainingImages = ones(newImageSize, newImageSize, 3, numFrames);
            trainingImages(:,:,1,:) = currentImageResized;
            trainingImages(:,:,2,:) = currentImageResized;
            trainingImages(:,:,3,:) = currentImageResized;
            
            %% compute the CNN features
            currentActivations = activations(pretrainedNet, trainingImages, activationLayerName, 'OutputAs', 'rows')';
            for l=1:numFrames
                finalMaskedImageCNNFeatures{k,l} = currentActivations(:,l);
            end
            
            f = waitbar(k/numCells, f, ['Computing CNN features for ' experimentName '_' positionName ' ...']);
        end
        close(f);
        
        %% save computed features to disk to avoid recomputations in the future
        save(cnnFeatureName, '-mat', 'finalMaskedImageCNNFeatures');
    end
    
    %% write hdf5 file for current position
    %% construct the output name based on the current project name
    outputFileName = callback_livecellminer_get_image_data_base_filename(currentIndices(1), parameter, code_alle, zgf_y_bez, bez_code);
    
    if (exist(outputFileName, 'file'))
        fprintf('File %s already exists, skipping recreation. To force recreation, manually delete  the file!\n', outputFileName);
        continue;
    end
        
    imageSize = size(finalRawImagePatches{1,1});
    featureSize = size(finalMaskedImageCNNFeatures{1,1});
    numFrames = size(d_orgs,2);
    hasSecondChannel = ~isempty(finalRawImagePatches2{1,1});
    
    outputTensorRaw = uint16(zeros(imageSize(1), imageSize(2), numFrames));
    outputTensorMask = uint8(zeros(imageSize(1), imageSize(2), numFrames));
    outputTensorCNN = single(zeros(featureSize(1), numFrames));
    if (hasSecondChannel)
        outputTensorRaw2 = uint16(zeros(imageSize(1), imageSize(2), numFrames));
    end
    
    for c=1:numCells

        if (isempty(finalRawImagePatches{c,1}))
            continue;
        end

        for j=1:numFrames
            outputTensorRaw(:,:,j) = finalRawImagePatches{c,j};
    
            if (~isempty(finalRawImagePatches2{c,j}))
                outputTensorRaw2(:,:,j) = finalRawImagePatches2{c,j};
            end
            outputTensorMask(:,:,j) = finalMaskImagePatches{c,j};
            outputTensorCNN(:,j) = finalMaskedImageCNNFeatures{c,j};
        end
    
        outputStringRaw = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, zgf_y_bez, 'raw');
        outputStringRaw2 = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, zgf_y_bez, 'raw2');
        outputStringMask = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, zgf_y_bez, 'mask');
        outputStringCNNFeatures = callback_livecellminer_create_hdf5_path(currentIndices(c), code_alle, zgf_y_bez, 'cnn');
    
        h5create(outputFileName, outputStringRaw, size(outputTensorRaw), 'Datatype', 'uint16'); %% , 'ChunkSize', size(outputTensorRaw), 'Deflate', compressionLevel
        h5write(outputFileName, outputStringRaw, outputTensorRaw);
    
        if (hasSecondChannel)
            h5create(outputFileName, outputStringRaw2, size(outputTensorRaw2), 'Datatype', 'uint16'); %% , 'ChunkSize', size(outputTensorRaw2), 'Deflate', compressionLevel
            h5write(outputFileName, outputStringRaw2, outputTensorRaw2);
        end
    
        h5create(outputFileName, outputStringMask, size(outputTensorMask), 'Datatype', 'uint8'); %% , 'ChunkSize', size(outputTensorMask), 'Deflate', compressionLevel
        h5write(outputFileName, outputStringMask, outputTensorMask);
    
        h5create(outputFileName, outputStringCNNFeatures, size(outputTensorCNN), 'Datatype', 'single'); %% , 'ChunkSize', size(outputTensorCNN), 'Deflate', compressionLevel
        h5write(outputFileName, outputStringCNNFeatures, outputTensorCNN);
    
        if (mod(c,100) == 1)
            fprintf('Finished converting %i / %i cells to the HDF5 file ...\n', c, numCells);
        end
    end
    
    %% success message
    fprintf('Converted image data base saved to %s\n', outputFileName);
    fprintf('Successfully converted image patches of experiment %s, plate %s.\n', experimentName, positionName);
end