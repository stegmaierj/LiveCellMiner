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

function d_orgs_new = callback_livecellminer_perform_backwards_tracking(d_orgs, parameters)

    %% get the number of frames
    numFrames = size(d_orgs, 2);

    maskImageFiles = [];
    if (isfield(parameters, 'augmentedMaskFolder') && ~isempty(parameters.augmentedMaskFolder))
        maskImageFiles = dir([parameters.augmentedMaskFolder parameters.maskFilter]);
    else
        disp('The selected tracking method (backwards tracking) only works with segmentation enabled. Make sure the intermediate folder AugmentedMasks exists and is filled with reasonable images');
        return;
    end

    %% perform the tracking by clustering
    d_orgs_new = zeros(80000, size(d_orgs,2), size(d_orgs,3));
    objectRadii = ones(size(d_orgs,2),1);
    currentTrackId = 1;
    for i=numFrames:-1:1

        if (~isempty(maskImageFiles))
            currentMaskImage = imread([parameters.augmentedMaskFolder maskImageFiles(i).name]);
            currentRegionProps = regionprops(currentMaskImage, 'Centroid');
        end

        %% get the valid locations at the current position
        validIndices = squeeze(d_orgs(:,i,3)) > 0;
        validPositions = squeeze(d_orgs(validIndices, i, :));

        if (parameters.seedBasedDetection == true)
                    
            kdtree = KDTreeSearcher(validPositions(:,3:4));
            [nnIndices, nnDistances] = knnsearch(kdtree, validPositions(:,3:4), 'K', 8);

            %% perform automatic cluster cutoff calculation
            if (parameters.clusterCutoff < 0)
                
                distances = mean(nnDistances(:,3:end), 2);

                %currentClusterCutoff = min(0.33 * mean(distances), parameters.maxRadius);
                currentClusterCutoff = 0.5 * mean(distances);
            else
                currentClusterCutoff = parameters.clusterCutoff;
            end
        else
            currentClusterCutoff = mean(validPositions(:, parameters.clusterRadiusIndex));
        end

        %% set the object radii for later segmentation
        objectRadii(i) = currentClusterCutoff;

        %% cluster nearby seeds
        Z = linkage(validPositions(:,3:4), 'ward');
        clusterIndices = cluster(Z, 'cutoff', currentClusterCutoff, 'criterion', 'distance');

        %% find outliers that are forming a cluster of size 1.
        numCells = length(validIndices);
        numForcedLinks = 0;

        if (parameters.forceNNLinking == true && i < numFrames)
            for j=unique(clusterIndices)'
                currentClusterIndices = find(clusterIndices == j);
                
                if (length(currentClusterIndices) == 1 && parameters.maxRadius >= nnDistances(currentClusterIndices, 2) && validPositions(currentClusterIndices, parameters.trackingIdIndex) > 0)


                    clusterIndices(currentClusterIndices) = clusterIndices(nnIndices(currentClusterIndices,2));
                    numForcedLinks = numForcedLinks + 1;
                end
            end
        end

        %% initialize track ids at the last frame
        %% propagate seeds to the previous frame using optical flow
        %% cluster seeds in the previous frame
        %% case 1: one of the seeds in a cluster has a tracking id -> assign tracking id to all other points
        %% case 2: none of the seeds in a cluster has a tracking id -> assign new tracking id (#current tracks + 1)
        %% case 3: two or more of the seeds have a tracking id -> introduce merge and add new seed with new tracking id (#current tracks + 1)
        %% special case if only one tracked location resides in a cluster -> potential dead end, i.e., apply intensity heuristic or fuse to nearest neighbor
        for j=unique(clusterIndices)'
            currentIndices = find(clusterIndices == j); %% object indices in the current cluster
            trackingIds = unique(validPositions(currentIndices, parameters.trackingIdIndex)); %% tracking ids of objects of the current cluster

            %% propagate tracking id if it already exists
            if (sum(trackingIds > 0) == 0)
                d_orgs_new(currentTrackId, i, :) = mean(validPositions(currentIndices, :), 1);
                d_orgs_new(currentTrackId, i, parameters.trackingIdIndex) = currentTrackId;
                currentTrackId = currentTrackId + 1;

            %% if a single tracking id exists already, use it
            elseif (sum(trackingIds > 0) == 1)
                existingTrackingId = max(validPositions(currentIndices, parameters.trackingIdIndex));
                
                untrackedIndices = (validPositions(currentIndices, parameters.trackingIdIndex) == 0);
                
                d_orgs_new(existingTrackingId, i, :) = mean(validPositions(currentIndices(untrackedIndices), :), 1);



                d_orgs_new(existingTrackingId, i, parameters.trackingIdIndex) = existingTrackingId;
                if (i<numFrames)
                    d_orgs_new(existingTrackingId, i+1, parameters.predecessorIdIndex) = existingTrackingId;
                end

                %% indicator that there's probably a dead end
                if (length(currentIndices) == 1)
                    d_orgs_new(existingTrackingId, i, :) = 0;
                    %d_orgs_new(existingTrackingId, i+1, trackingIdIndex) = 0;
                end

            %% if multiple ids larger than zero exist, perform a merge
            else

                %% detect if there are multiple segments hit by the current merge candidates
                %% initialize arrays for the non-zero detections and the associated labels
                nonZeroDetectionIDs = [];
                matchedSegmentLabels = [];

                %figure(5); clf;
                %imagesc(currentMaskImage); hold on;
                %plot(validPositions(currentIndices, 3), validPositions(currentIndices, 4), '*r');

                %% loop through all objects of the current cluster
                for k=currentIndices'

                    %% get current position clamped by the image extents
                    currentPosition = [max(1, min(size(currentMaskImage,1), round(validPositions(k, 4)))), ...
                                       max(1, min(size(currentMaskImage,2), round(validPositions(k, 3))))];

                    %% get label of the current detection
                    currentLabel = currentMaskImage(currentPosition(1), currentPosition(2));

                    %% if non-zero, save the label and the corresponding object index
                    if (currentLabel > 0)
                        nonZeroDetectionIDs = [nonZeroDetectionIDs; k];
                        matchedSegmentLabels = [matchedSegmentLabels; currentLabel];
                    end
                end
            
                %% if only one segment is present, use the centroid of this segment for merging
                if (length(unique(matchedSegmentLabels)) == 1)
                    
                    %% use object information of the non-zero object (i.e., the one that sits on the segment) and replace position with the centroid of the segment
                    d_orgs_new(currentTrackId, i, :) = validPositions(nonZeroDetectionIDs(1), :);
                    d_orgs_new(currentTrackId, i, 3:4) = round(currentRegionProps(matchedSegmentLabels(1)).Centroid); 
                    d_orgs_new(currentTrackId, i, parameters.trackingIdIndex) = currentTrackId;
                    %plot(d_orgs_new(currentTrackId, i, 3), d_orgs_new(currentTrackId, i, 4), 'ok');
    
                    %% update the successors
                    for k=trackingIds(trackingIds>0)
                        d_orgs_new(k, i+1, parameters.predecessorIdIndex) = currentTrackId;
                    end
    
                    currentTrackId = currentTrackId + 1;

                %% if multiple segments are present, preserve the segments and assign unmatched positions to the closest segment
                else

                    %% save segment label of the closest segment for each detection of the current cluster
                    closestSegmentLabels = [];

                    %% loop through all detections and find closest segment
                    for s=currentIndices'

                        %% initialize min distance and min label
                        minDistance = inf;
                        minLabel = 0;

                        %% compute distance of the current object to the available segmentations
                        for t=matchedSegmentLabels'

                            %% compute current distance
                            currentDistance = norm(validPositions(s, 3:4) - currentRegionProps(t).Centroid);

                            %% update label and index of the current matched segmentation
                            if (currentDistance < minDistance)
                                minDistance = currentDistance;
                                minLabel = t;
                            end
                        end

                        %% add the respective closest segment labels
                        closestSegmentLabels = [closestSegmentLabels; minLabel];
                    end

                    %% perform merges for all unqiue segments
                    uniqueSegmentLabels = unique(matchedSegmentLabels);

                    %% loop though the existing segments and handle merges
                    for s=uniqueSegmentLabels'

                        %% get object indices that are associated with the current segment
                        currentSegmentIndices = nonZeroDetectionIDs(matchedSegmentLabels == s);

                        %% get tracking ids of all current objects and use the smallest one
                        existingTrackingIDs = validPositions(currentSegmentIndices, parameters.trackingIdIndex);
                        existingTrackingId = min(existingTrackingIDs(existingTrackingIDs>0));

                        %% check if tracking id needs to be increased (in case of appearances of an untracked object)
                        increaseTrackingId = false;
                        if (isempty(existingTrackingId))
                            existingTrackingId = currentTrackId;
                            increaseTrackingId = true;
                        end

                        %% update d_orgs with the first objects properties and replace position with the centroid of the region
                        d_orgs_new(existingTrackingId, i, :) = validPositions(currentSegmentIndices(1), :);
                        d_orgs_new(existingTrackingId, i, 3:4) = round(currentRegionProps(s).Centroid); 
                        d_orgs_new(existingTrackingId, i, parameters.trackingIdIndex) = existingTrackingId;

                        %plot(d_orgs_new(existingTrackingId, i, 3), d_orgs_new(existingTrackingId, i, 4), 'ok');
    
                        %% update the non-zero successors
                        for k=existingTrackingIDs(existingTrackingIDs>0)  %currentSegmentIndices(currentSegmentIndices>0)
                            d_orgs_new(k, i+1, parameters.predecessorIdIndex) = existingTrackingId;
                        end

                        %% if the continuous track counter was used, increase it        
                        if (increaseTrackingId == true)
                            currentTrackId = currentTrackId + 1;
                        end
                    end
                end
            end

            %% extend d_orgs_new if more than the preinitialized number of tracks is found
            if (currentTrackId >= size(d_orgs_new, 1))
                d_orgs_new(currentTrackId + 50000, :, :) = 0;
            end
        end

%         figure(2); clf; hold on; axis tight; colormap gray;
%         inputDir = '/Users/jstegmaier/Downloads/InputFolder/016/P0001/';
%         inputFiles = dir([inputDir '*.tif']);
% 
%         imagesc(imadjust(imread([inputDir inputFiles(i).name])));
%         plot(d_orgs_new(:, i, 3), d_orgs_new(:, i, 4), '*g');
%         plot(d_orgs(:, i, 3), d_orgs(:, i, 4), '.r');
% 
%         colorMap = lines(1000);
% 
%         for mytrack = 1:(currentTrackId-1)
%             validIndices = find(d_orgs_new(mytrack, :, 1) > 0);
% 
%             plot(d_orgs_new(mytrack, validIndices, 3), d_orgs_new(mytrack, validIndices, 4), '-r', 'LineWidth', 2, 'Color', colorMap(mytrack,:));
% 
%             text(d_orgs_new(mytrack, i, 3), d_orgs_new(mytrack, i, 4), sprintf('Label %i', mytrack));
%         end
        

        %% propagate tracked seeds backwards in time using optical flow
        if (i > 1)

            %% extract the previous, current and next positions
            valindIndices = find(squeeze(d_orgs_new(:,i,3) > 0));
            currentIndex = find(squeeze(d_orgs(:,i-1,3) > 0), 1, 'last') + 1;

            for j=valindIndices'

                currentPosition = round(squeeze(d_orgs_new(j, i, :)));

                %% TODO: potentially estimate weighted centroid of a small region to optimize localization
                %previousDirection = [0,0,0];

                %% add the seeds and the seed predictions to the seed frames
                previousPosition = currentPosition(parameters.prevPosIndices);

                %% write seed candidates to the result image
                d_orgs(currentIndex, i-1, :) = currentPosition;
                d_orgs(currentIndex, i-1, 3:5) = previousPosition;
                currentIndex = currentIndex + 1;
            end
        end

        %% display progress
        fprintf('Finished tracking for frame %i (%.2f %%)\n', i, 100*(numFrames-i)/numFrames);
    end

    %% prune the result structure to only valid tracks
    d_orgs_new(currentTrackId:end, :, :) = [];
end