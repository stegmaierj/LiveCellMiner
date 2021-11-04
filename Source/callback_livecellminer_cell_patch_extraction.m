%%
% LiveCellMiner.
% Copyright (C) 2021 D. Moreno-Andrés, A. Bhattacharyya, W. Antonin, J. Stegmaier
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

%% function to extract equally sized image snippets from the image sequence
%% for a given set of complete cell cycles specified in the candidate list

%% identify cells which fall in the candidate list and has valid Centroid, determined where RegProps doesnot equal NaN
function [featureNames, resultMatrix, deletionIndices, rawImagePatches, maskImagePatches, rawImagePatches2] = callback_livecellminer_cell_patch_extraction(d_orgs, candidateList, parameters)

    %% start timer
    tic;

    %% parse the input directories
    inputRawFiles = dir([parameters.inputFolder parameters.imageFilter]);

    inputRawFiles2 = [];
    if (~isempty(parameters.channelFilter2))
        inputRawFiles2 = dir([parameters.inputFolder parameters.imageFilter2]);
    end

    maskImageFiles = [];
    if (~isempty(parameters.maskFolder))
        maskImageFiles = dir([parameters.maskFolder parameters.maskFilter]);
    end

    patchWidth = parameters.patchWidth;

    %% choose cell ids from candidate list
    numFrames = size(d_orgs, 2);
    numFeatures = 28;
    scaleFactor = parameters.micronsPerPixel / parameters.patchRescaleFactor;
    sortedList = sortrows(candidateList);
    cellIDs = sortedList(:,1);
    maxCellID = max(cellIDs);
    startTimePoints = sortedList(:,2);
    endTimePoints = sortedList(:,3);

    rawImagePatches = cell(maxCellID, numFrames);
    rawImagePatches2 = cell(maxCellID, numFrames);
    maskImagePatches = cell(maxCellID, numFrames);
    resultMatrix = zeros(maxCellID, numFrames, numFeatures);
    deletionIndices = [];

    for i=1:numFrames

        %% read the current image and get the image size
        rawImage = imread([parameters.inputFolder inputRawFiles(i).name]);
        [imgHeight, imgWidth] = size(rawImage);

        %% load the second channel image if available
        if (~isempty(parameters.channelFilter2))
            rawImage2 = imread([parameters.inputFolder inputRawFiles2(i).name]);
        else
            rawImage2 = [];
        end

        %% load the mask image if available
        maskImage = [];
        if (~isempty(parameters.maskFolder) && ~isempty(maskImageFiles) && isfile([parameters.maskFolder maskImageFiles(i).name]))
            maskImage = imread([parameters.maskFolder maskImageFiles(i).name]);
        end

        %% extract centroids, pixel indices and bounding boxes from the labeled regions
        numLabels = max(max(max(d_orgs(:,i,parameters.trackingIdIndex))));

        %% loop through all cells and extract the occurrence in the current frame
        currentDOrgs = squeeze(d_orgs(:, i, :));
        threadedResults = cell(maxCellID,1);
        parfor j=1:length(cellIDs)

            size(rawImage);
            size(maskImage);
            size(parameters);
            size(currentDOrgs);
            currentResults = struct();
            currentResults.deletionIndices = [];
            currentResults.validCell = false;

            %% check if cell id is smaller than the maximum number of cells
            if cellIDs(j,1) <= min(maxCellID, numLabels)

                %% identify the current cell being tracked
                currentIndex = cellIDs(j, 1);
                currentCentroid = currentDOrgs(currentIndex, parameters.posIndices(1:2));
                currentResults.currentIndex = currentIndex;

                %% check if cell is present in the frame
                if i >= (startTimePoints(j)+1) && i <= (endTimePoints(j)+1)

                    singleCenterCC = true;
                    currentDuration = endTimePoints(j) - startTimePoints(j) + 1;
                    if ((currentDuration == parameters.timeWindowMother && i >= (startTimePoints(j)+parameters.timeWindowMother-parameters.singleCellCCDisableRadius)) || ...
                            (currentDuration == parameters.timeWindowDaughter && i <= (startTimePoints(j)+parameters.singleCellCCDisableRadius)))
                        singleCenterCC = false;
                    end

                    %% specify the coordinates of the image crop
                    centroid = currentCentroid;
                    scaledPatchWidth = round(patchWidth / scaleFactor);
                    topLeftCorner = round(centroid - round([scaledPatchWidth/2, scaledPatchWidth/2]));
                    rangeX = topLeftCorner(2):(topLeftCorner(2)+scaledPatchWidth-1);
                    rangeY = topLeftCorner(1):(topLeftCorner(1)+scaledPatchWidth-1);
                    maxX = max(rangeX(:));
                    maxY = max(rangeY(:));

                    %% create reject list for cells lying outside the border
                    if maxX >= imgHeight || maxY >= imgWidth || or(topLeftCorner(1) <= 0, topLeftCorner(2) <= 0) == 1
                        currentResults.deletionIndices = currentIndex;
                    end

                    %% ensure the current index is valid
                    if ~ismember(currentIndex, currentResults.deletionIndices)

                        currentResults.validCell = true;

                        %% extract the copped image
                        croppedImage = uint16(rawImage(rangeX, rangeY));

                        %% scale and crop the image snippet depending on the physical pixel size
                        croppedImage = imresize(croppedImage, [patchWidth, patchWidth], 'bilinear');
                        %rawImagePatches{currentIndex, i} = croppedImage;
                        currentResults.rawImagePatch = croppedImage;

                        if (~isempty(rawImage2))
                            croppedImage2 = uint16(rawImage2(rangeX, rangeY));
                            croppedImage2 = imresize(croppedImage2, [patchWidth, patchWidth], 'bilinear');
                            %rawImagePatches2{currentIndex, i} = croppedImage2;
                            currentResults.rawImagePatch2 = croppedImage2;
                        end

                        %% Segment the nuclues of cell
                        if (isempty(parameters.maskFolder))
                            croppedMask = uint16(callback_livecellminer_segment_center_nucleus(croppedImage, singleCenterCC));
                        else
                            croppedMask = uint16(maskImage(rangeX, rangeY));
                            croppedMask = imresize(croppedMask, [patchWidth, patchWidth], 'nearest');
                            centerLabel = croppedMask(patchWidth/2, patchWidth/2);

                            if (centerLabel > 0)
                                croppedMask = uint16(croppedMask == centerLabel);
                            else
                                croppedMask = uint16(callback_livecellminer_segment_center_nucleus(croppedImage, singleCenterCC));
                            end
                        end
                        %maskImagePatches{currentIndex, i} = croppedMask;
                        currentResults.maskImagePatch = croppedMask;

                        %% create result matrix
                        [currentResults.featureNames, features] = callback_livecellminer_extract_nucleus_features(croppedImage, croppedMask);
                        currentResults.resultMatrix = [currentIndex, currentDOrgs(currentIndex, 2), currentDOrgs(currentIndex, 3), currentDOrgs(currentIndex, 4), 0, 1];
                        if length(features) == (numFeatures-6)
                            currentResults.resultMatrix = [currentResults.resultMatrix, features];  %only add those cells which have valid features
                        end
                    end
                end
            end

            threadedResults{j} = currentResults;
        end

        for j=1:length(cellIDs)
            if (~threadedResults{j}.validCell)
                deletionIndices = [deletionIndices; threadedResults{j}.deletionIndices]; %#ok<AGROW>
                continue;
            end

            currentIndex = threadedResults{j}.currentIndex;
            featureNames = threadedResults{j}.featureNames;
            rawImagePatches{currentIndex,i} = threadedResults{j}.rawImagePatch;

            if (isfield(threadedResults{j}, 'rawImagePatch2'))
                rawImagePatches2{currentIndex,i} = threadedResults{j}.rawImagePatch2;
            end
            maskImagePatches{currentIndex,i} = threadedResults{j}.maskImagePatch;
            resultMatrix(currentIndex, i, :) = threadedResults{j}.resultMatrix;
        end

        %% show progress and elapsed time
        t = toc;
        disp(['Extracting cell patch features ' num2str(i) ' / ' num2str(numFrames), ' Time elapsed: ' num2str(t) ' s']);
    end

    %% adjust the last entry of the tracking state
    for i=1:size(resultMatrix,1)
        validIndices = find(squeeze(resultMatrix(i,:,6)) > 0);
        if (~isempty(validIndices))
            resultMatrix(i,validIndices(end),6) = 0;
        end
    end

    %% add a few default features for id, area and location
    featureNames = char('id', 'scale', 'xpos', 'ypos', 'zpos', 'Tracking state', featureNames);
end