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

function [] = callback_livecellminer_perform_detection_and_tracking(parameters)

    %% TODO: maybe replace seed detection with LoG again...
    [d_orgs, ~] = callback_livecellminer_perform_seed_detection(parameters);

    %% refine detected seeds based on the weighted centroid on the previous frame
    [d_orgs] = callback_livecellminer_refine_detected_seeds(d_orgs, parameters);

    %[d_orgs_new] = PerformTracking(d_orgs, settings);
    
    if (parameters.performSegmentationPropagationTracking == true)
        d_orgs = callback_livecellminer_perform_segmentation_based_tracking(parameters);
    else
        [d_orgs] = callback_livecellminer_perform_backwards_tracking(d_orgs, parameters);
    end
      
    
    save([parameters.outputFolder 'trackingProject.prjz'], '-mat', 'd_orgs', '-v7.3');

    %% plot the tracking results
    %PlotTrackingResults(d_orgs, settings);

    %% generate the candidate list of valid mitotic events with sufficient frames before and after the division
    [motherList, daughterList, motherDaughterList] = callback_livecellminer_candidate_list_generation(d_orgs, parameters);
    candidateList = [motherList; daughterList];

    if (isempty(candidateList))
        disp('No valid tracks were found! For instance, try to loosen the required tracking length constraint and run again ...');
        return;
    end

    %% Parameters for cell patch extraction
    [featureNames, featureMatrix, deletionIndices, rawImagePatches, maskImagePatches, rawImagePatches2] = callback_livecellminer_cell_patch_extraction(d_orgs, candidateList, parameters);

    %% combine the mother and daughter features to the final feature matrix
    [finalFeatureMatrix, originalIds, finalRawImagePatches, finalMaskImagePatches, finalRawImagePatches2] = callback_livecellminer_combine_mother_daughter_tracks(featureMatrix, motherList, daughterList, motherDaughterList, deletionIndices, rawImagePatches, maskImagePatches, rawImagePatches2, parameters);

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
    
    %% apply physical spacing to convert all pixel measures into microns
    xposID = callback_livecellminer_find_time_series(featureNames, 'xpos');
    yposID = callback_livecellminer_find_time_series(featureNames, 'ypos');
    minorAxisLenghtID = callback_livecellminer_find_time_series(featureNames, 'MinorAxisLength');
    majorAxisLengthID = callback_livecellminer_find_time_series(featureNames, 'MajorAxisLength');
    areaID = callback_livecellminer_find_time_series(featureNames, 'Area');
    finalFeatureMatrix(:,:,xposID) = finalFeatureMatrix(:,:,xposID) * parameters.micronsPerPixel; %% rescaling is not applied to the positions, thus they use the original pixel spacing
    finalFeatureMatrix(:,:,yposID) = finalFeatureMatrix(:,:,yposID) * parameters.micronsPerPixel; %% rescaling is not applied to the positions, thus they use the original pixel spacing
    finalFeatureMatrix(:,:,minorAxisLenghtID) = finalFeatureMatrix(:,:,minorAxisLenghtID) * parameters.patchRescaleFactor; %% as the image patches were rescaled with parameters.patchRescaleFactor
    finalFeatureMatrix(:,:,majorAxisLengthID) = finalFeatureMatrix(:,:,majorAxisLengthID) * parameters.patchRescaleFactor; %% as the image patches were rescaled with parameters.patchRescaleFactor
    finalFeatureMatrix(:,:,areaID) = finalFeatureMatrix(:,:,areaID) * (parameters.patchRescaleFactor^2); %% as the image patches were rescaled with parameters.patchRescaleFactor
    
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
    projekt.patchRescaleFactor = parameters.patchRescaleFactor;
    projekt.experimentName = parameters.experimentName;
    projekt.positionNumber = parameters.positionNumber;
    projekt.patchWidth = parameters.patchWidth;
    projekt.timeWindowDaughter = parameters.timeWindowDaughter;
    projekt.timeWindowMother = parameters.timeWindowMother;
    projekt.parameters = parameters;

    %% create the output file names for the current project
    outputNames = callback_livecellminer_generate_output_paths(parameters);
    save(outputNames.project, '-mat', 'd_orgs', 'code', 'var_bez', 'code_alle', 'projekt');
    save(outputNames.rawImagePatches, '-mat', 'finalRawImagePatches', '-v7.3');
    save(outputNames.maskImagePatches, '-mat', 'finalMaskImagePatches', '-v7.3');
    save(outputNames.maskedImageCNNFeatures, '-mat', 'finalMaskedImageCNNFeatures', '-v7.3');
    if (~isempty(finalRawImagePatches2))
        save(outputNames.rawImagePatches2, '-mat', 'finalRawImagePatches2', '-v7.3');
    end
    
    %% display success message
    writetable(struct2table(parameters), [parameters.outputFolder filesep parameters.experimentName '_' parameters.positionNumber '_Settings.csv']);
    disp(['Processing of input folder experiment ' parameters.experimentName ', position ' parameters.positionNumber ' was successful. Results saved in ' strcat(parameters.outputFolder, '/', parameters.experimentName, '_', parameters.positionNumber, '*')]);
end
