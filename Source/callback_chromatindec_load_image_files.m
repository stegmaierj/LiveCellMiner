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

global maskImagePatches;
global rawImagePatches;
global maskedImageCNNFeatures;

%% get the root directory of the projects to import
inputRootFolder = parameter.projekt.pfad;
if (~isfolder(inputRootFolder))
   inputRootFolder = uigetdir(); 
end
inputRootFolder = [inputRootFolder filesep];
[inputFolders, microscopeList, experimentList, positionList] = callback_chromatindec_get_valid_input_paths(inputRootFolder);

%% initialize the SciXMiner variables
numTotalCells = size(d_orgs, 1);
numFrames = size(d_orgs,2);

rawImagePatches = cell(numTotalCells, numFrames);
maskImagePatches = cell(numTotalCells, numFrames);
maskedImageCNNFeatures = cell(numTotalCells, numFrames);

%% resample the current image CNN prediction with a pretrained network
pretrainedNet = googlenet;
activationLayerName = 'loss3-classifier';
inputSize = pretrainedNet.Layers(1).InputSize;
newImageSize = inputSize(1);

%% import all projects contained in the root folder
currentCell = 1;
for i=1:length(inputFolders)
        
    %% get the current microscope
    currentInputFolder = inputFolders{i};
    
    splitString = strsplit(currentInputFolder(1:end-1), '/');
    microscopeName = splitString{end-2};
    experimentName = splitString{end-1};
    positionName = splitString{end};
    [microscopeId, experimentId, positionId] = callback_chromatindec_get_output_variables(microscopeList, experimentList, positionList, microscopeName, experimentName, positionName);
    
    %% load the current project
    projectName = [currentInputFolder experimentName '_' positionName '_SciXMiner.prjz'];
    if (~isfile(projectName)); continue; end
        
    load([currentInputFolder experimentName '_' positionName '_RawImagePatches.mat'], '-mat');
    load([currentInputFolder experimentName '_' positionName '_MaskImagePatches.mat'], '-mat');

    %% identify the number of cells
    numCells = size(finalRawImagePatches, 1);
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
                       
    %% fill the zgf_y_bez variable
    for k=1:numCells

        if (isempty(finalRawImagePatches{k, 1}))
            continue;
        end

        %% save the combined image patches
        for l=1:numFrames
            rawImagePatches{currentCell, l} = uint8(255 * double(finalRawImagePatches{k, l}) / max(double(finalRawImagePatches{k, l}(:))));
            maskImagePatches{currentCell, l} = uint8(finalMaskImagePatches{k, l} > 0);
            maskedImageCNNFeatures{currentCell, l} = finalMaskedImageCNNFeatures{k, l};
        end

        %% increase the cell counter
        currentCell = currentCell + 1;
    end
       
    fprintf('Successfully loaded image patches of experiment %s, plate %s.\n', experimentName, positionName);
end