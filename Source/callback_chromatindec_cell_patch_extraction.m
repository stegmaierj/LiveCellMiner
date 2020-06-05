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
 
%% function to extract equally sized image snippets from the image sequence
%% for a given set of complete cell cycles specified in the candidate list

%% identify cells which fall in the candidate list and has valid Centroid, determined where RegProps doesnot equal NaN
function [featureNames, resultMatrix, deletionIndices, rawImagePatches, maskImagePatches] = callback_chromatindec_cell_patch_extraction(d_orgs, candidateList, settings)

	%% start timer
    tic;
    
    %% parse the input directories
    inputRawFiles = dir([settings.inputFolder settings.imageFilter]);
    if (~isempty(settings.maskFolder))
        maskImageFiles = dir([settings.maskFolder settings.maskFilter]);
    end
    
    patchWidth = settings.patchWidth;
    
    %% choose cell ids from candidate list
    numFrames = size(d_orgs, 2);
    numFeatures = 29;
    sortedList = sortrows(candidateList);
    cellIDs = sortedList(:,1);
    maxCellID = max(cellIDs);
    startTimePoints = sortedList(:,2);
    endTimePoints = sortedList(:,3);
    resultMatrix = zeros(maxCellID, numFrames, numFeatures);
    deletionIndices = [];
    rawImagePatches = cell(max(cellIDs), numFrames);
    maskImagePatches = cell(max(cellIDs), numFrames);

    %% Main loop to extract image snippets
    for i=1:numFrames
        
        %% read the current image and get the image size
        rawImage = imread([settings.inputFolder inputRawFiles(i).name]);
        [imgHeight, imgWidth] = size(rawImage);

        %% load the mask image if available
        if (~isempty(settings.maskFolder))
            maskImage = imread([settings.maskFolder maskImageFiles(i).name]);
        end
        
        %% extract centroids, pixel indices and bounding boxes from the labeled regions
        numLabels = max(max(max(d_orgs(:,i,settings.trackingIdIndex))));

        %% loop through all cells and extract the occurrence in the current frame
        for j=1:length(cellIDs)

            %% check if cell id is smaller than the maximum number of cells
            if cellIDs(j,1) <= min(maxCellID, numLabels)

                %% identify the current cell being tracked
                currentIndex = cellIDs(j, 1);
                currentCentroid = squeeze(d_orgs(currentIndex, i, settings.posIndices));

                %% check if cell is present in the frame
                if i >= (startTimePoints(j)+1) && i <= (endTimePoints(j)+1)

                    %% specify the coordinates of the image crop
                    centroid = currentCentroid;
                    topLeftCorner = ceil(centroid - ceil([patchWidth/2, patchWidth/2]));
                    rangeX = topLeftCorner(2):(topLeftCorner(2)+patchWidth-1);
                    rangeY = topLeftCorner(1):(topLeftCorner(1)+patchWidth-1);
                    maxX = max(rangeX(:));
                    maxY = max(rangeY(:));

                    %% create reject list for cells lying outside the border
                    if maxX >= imgHeight || maxY >= imgWidth || or(topLeftCorner(1) <= 0, topLeftCorner(2) <= 0) == 1
                        deletionIndices = [deletionIndices; currentIndex]; %#ok<AGROW>
                    end

                    %% ensure the current index is valid
                    if ~ismember(currentIndex, deletionIndices)

                        %% extract the copped image
                        croppedImage = uint16(rawImage(rangeX, rangeY));
                        rawImagePatches{currentIndex, i} = croppedImage;
                        
                        %% Segment the nuclues of cell
                        if (isempty(settings.maskFolder))
                            croppedMask = uint16(callback_chromatindec_segment_center_nucleus(croppedImage));
                        else
                            croppedMask = uint16(maskImage(rangeX, rangeY));
                            centerLabel = croppedMask(patchWidth/2, patchWidth/2);
                            
                            if (centerLabel > 0)
                                croppedMask = uint16(croppedMask == centerLabel);                    
                            else
                                croppedMask = uint16(callback_chromatindec_segment_center_nucleus(croppedImage)); 
                            end
                        end
                        maskImagePatches{currentIndex, i} = croppedMask;

                        %% create result matrix
                        [featureNames, features] = callback_chromatindec_extract_nucleus_features(croppedImage, croppedMask);
                        resultMatrix(currentIndex, i, 1:6) = [currentIndex, d_orgs(currentIndex, i, 2), d_orgs(currentIndex, i, 3), d_orgs(currentIndex, i, 4), 0, 1];
                        if length(features) == (numFeatures-6)
                            resultMatrix(currentIndex, i, 7:end) = features;  %only add those cells which have valid features
                        end
                    end
                end
            end
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
    featureNames = char('id', 'area', 'xpos', 'ypos', 'zpos', 'Tracking state', featureNames);
end
