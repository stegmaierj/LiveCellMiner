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

function [] = callback_chromatindec_perform_detection_and_tracking(parameters)

    %% setup output folders
    parameters.outputRawFolder = [parameters.outputFolder 'Raw'];
    parameters.outputMaskFolder = [parameters.outputFolder 'Masks'];
    if (~isfolder(parameters.outputRawFolder)); mkdir(parameters.outputRawFolder); end
    if (~isfolder(parameters.outputMaskFolder)); mkdir(parameters.outputMaskFolder); end

    %% TODO: maybe replace seed detection with LoG again...
    [d_orgs, ~] = callback_chromatindec_perform_seed_detection(parameters);

    %% refine detected seeds based on the weighted centroid on the previous frame
    [d_orgs] = callback_chromatindec_refine_detected_seeds(d_orgs, parameters);

    %[d_orgs_new] = PerformTracking(d_orgs, settings);
    [d_orgs] = callback_chromatindec_perform_backwards_tracking(d_orgs, parameters);

    %% plot the tracking results
    %PlotTrackingResults(d_orgs, settings);

    %% generate the candidate list of valid mitotic events with sufficient frames before and after the division
    [motherList, daughterList, motherDaughterList] = callback_chromatindec_candidate_list_generation(d_orgs, parameters);
    candidateList = [motherList; daughterList];

    %% Parameters for cell patch extraction
    [featureNames, featureMatrix, deletionIndices, rawImagePatches, maskImagePatches] = callback_chromatindec_cell_patch_extraction(d_orgs, candidateList, parameters);

    %% combine the mother and daughter features to the final feature matrix
    [finalFeatureMatrix, originalIds, finalRawImagePatches, finalMaskImagePatches] = callback_chromatindec_combine_mother_daughter_tracks(featureMatrix, motherList, daughterList, motherDaughterList, deletionIndices, rawImagePatches, maskImagePatches, parameters);

    %% compute the CNN features for LSTM-based synchronization
    finalMaskedImageCNNFeatures = cell(size(finalRawImagePatches));
    
    %% resample the current image CNN prediction with a pretrained network
    pretrainedNet = googlenet;
    activationLayerName = 'loss3-classifier';
    inputSize = pretrainedNet.Layers(1).InputSize;
    newImageSize = inputSize(1);
    numFrames = size(finalRawImagePatches,2);
    
    %% process all cells
    for i=1:size(finalRawImagePatches,1)
        
        %% stop as soon as there are no valid cells present anymore
        if (isempty(finalRawImagePatches{i,1}) || isempty(finalMaskImagePatches{i,1}))
           break; 
        end
        
        %% assemble the training image for all frames
        currentImage = zeros(parameters.patchWidth, parameters.patchWidth, numFrames);
        for j=1:numFrames
            currentImage(:,:,j) = finalRawImagePatches{i,j} .* finalMaskImagePatches{i,j};
        end
        currentImageResized = imresize3(currentImage, [newImageSize, newImageSize, numFrames], 'linear');

        %% creaet a 3-channel image containing the resized image patches for each frame
        trainingImages = ones(newImageSize, newImageSize, 3, numFrames);
        trainingImages(:,:,1,:) = currentImageResized;
        trainingImages(:,:,2,:) = currentImageResized;
        trainingImages(:,:,3,:) = currentImageResized;
        
        %% compute the CNN features
        currentActivations = activations(pretrainedNet, trainingImages, activationLayerName, 'OutputAs', 'rows')';
        for j=1:numFrames
           finalMaskedImageCNNFeatures{i,j} = currentActivations(:,j); 
        end
        
        disp(['Finished extracting CNN features for ' num2str(i) ' / ' num2str(size(finalRawImagePatches,1)) '...']);
    end
    
    %% write the results as SciXMiner project
    d_orgs = finalFeatureMatrix;
    var_bez = featureNames;
    code = ones(size(d_orgs,1),1);
    code_alle = code;
    projekt.originalIds = originalIds;
    projekt.motherList = motherList;
    projekt.daughterList = daughterList;
    projekt.motherDaughterList = motherDaughterList;
    projekt.candidateList = candidateList;
    projekt.micronsPerPixel = parameters.micronsPerPixel;
    projekt.experimentName = parameters.experimentName;
    projekt.positionNumber = parameters.positionNumber;
    projekt.patchWidth = parameters.patchWidth;
    projekt.timeWindowDaughter = parameters.timeWindowDaughter;
    projekt.timeWindowMother = parameters.timeWindowMother;
    save(strcat(parameters.outputFolder, '/', parameters.experimentName, '_', parameters.positionNumber, '_SciXMiner.prjz'), '-mat', 'd_orgs', 'code', 'var_bez', 'code_alle', 'projekt');
    save(strcat(parameters.outputFolder, '/', parameters.experimentName, '_', parameters.positionNumber, '_RawImagePatches.mat'), '-mat', 'finalRawImagePatches');
    save(strcat(parameters.outputFolder, '/', parameters.experimentName, '_', parameters.positionNumber, '_MaskImagePatches.mat'), '-mat', 'finalMaskImagePatches');
    save(strcat(parameters.outputFolder, '/', parameters.experimentName, '_', parameters.positionNumber, '_MaskedImageCNNFeatures.mat'), '-mat', 'finalMaskedImageCNNFeatures');
end
