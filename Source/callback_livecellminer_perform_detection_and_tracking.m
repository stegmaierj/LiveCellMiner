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

    save([parameters.outputFolder 'trackingProject_DEBUG.prjz'], '-mat', 'd_orgs', 'parameters', '-v7.3');
    
    if (strcmp(parameters.trackingMethod, 'Segmentation Propagation'))
        d_orgs = callback_livecellminer_perform_segmentation_based_tracking(parameters);
    elseif (strcmp(parameters.trackingMethod, 'Ultrack'))

        inputPathRaw = parameters.inputFolder;
        inputPathCellpose = parameters.augmentedMaskFolder;
        outputPathTracking = [parameters.outputFolder 'TrackedMasks/'];

        overwriteTracking = '';
        if (parameters.reprocessTracking)
            overwriteTracking = ' --overwrite';
        end
        
        currentFileDir = fileparts(mfilename('fullpath'));

        pythonCommand = [parameters.ULTRACKPath ...
                         ' ' currentFileDir 'perform_tracking_ultrack.py' ...
                         ' --input_path_raw ' inputPathRaw ...
                         ' --input_path_cellpose ' inputPathCellpose ...
                         ' --output_path ' outputPathTracking ...
                         overwriteTracking];

        system(pythonCommand);

        [d_orgs] = callback_livecellminer_import_ultrack_results(outputPathTracking, parameters);
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
    %save(outputNames.rawImagePatches, '-mat', 'finalRawImagePatches', '-v7.3');
    %save(outputNames.maskImagePatches, '-mat', 'finalMaskImagePatches', '-v7.3');
    %save(outputNames.maskedImageCNNFeatures, '-mat', 'finalMaskedImageCNNFeatures', '-v7.3');
    %if (~isempty(finalRawImagePatches2))
    %    save(outputNames.rawImagePatches2, '-mat', 'finalRawImagePatches2', '-v7.3');
    %end

    %% HDF5 OUTPUT
    numCells = size(d_orgs,1);
    imageSize = size(finalRawImagePatches{1,1});
    hasSecondChannel = ~isempty(finalRawImagePatches2);
    outputFileName = [parameters.outputFolder projekt.experimentName '_' projekt.positionNumber  '_ImageData.h5'];
    if (isfile(outputFileName))
        delete(outputFileName);
    end


    outputTensorRaw = uint16(zeros(imageSize(1), imageSize(2), numFrames));
    outputTensorMask = uint8(zeros(imageSize(1), imageSize(2), numFrames));
    if (hasSecondChannel)
        outputTensorRaw2 = uint16(zeros(imageSize(1), imageSize(2), numFrames));
    end

    featureSize = size(finalMaskedImageCNNFeatures{1,1});
    outputTensorCNN = single(zeros(featureSize(1), numFrames));

    for c=1:numCells

        if (isempty(finalRawImagePatches{c,1}))
            continue;
        end

        parfor j=1:numFrames
            outputTensorRaw(:,:,j) = finalRawImagePatches{c,j};
    
            if (~isempty(finalRawImagePatches2{c,j}))
                outputTensorRaw2(:,:,j) = finalRawImagePatches2{c,j};
            end
    
            outputTensorMask(:,:,j) = finalMaskImagePatches{c,j};
        end


        for j=1:numFrames
            outputTensorCNN(:,j) = finalMaskedImageCNNFeatures{c,j};
        end

        % %% TODO: directly write all files to H5
        outputStringRaw = callback_livecellminer_create_hdf5_path_strings(projekt.experimentName, projekt.positionNumber, sprintf('cell_id_%04d', c), 'raw');
        outputStringRaw2 = callback_livecellminer_create_hdf5_path_strings(projekt.experimentName, projekt.positionNumber, sprintf('cell_id_%04d', c), 'raw2');
        outputStringMask = callback_livecellminer_create_hdf5_path_strings(projekt.experimentName, projekt.positionNumber, sprintf('cell_id_%04d', c), 'mask');
        outputStringCNNFeatures = callback_livecellminer_create_hdf5_path_strings(projekt.experimentName, projekt.positionNumber, sprintf('cell_id_%04d', c), 'cnn');

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
    end
    
    %% display success message
    callback_livecellminer_save_parameters_as_csv(parameters, [parameters.outputFolder filesep parameters.experimentName '_' parameters.positionNumber '_Settings.csv']);
    disp(['Processing of input folder experiment ' parameters.experimentName ', position ' parameters.positionNumber ' was successful. Results saved in ' strcat(parameters.outputFolder, '/', parameters.experimentName, '_', parameters.positionNumber, '*')]);
end
