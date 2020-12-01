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

function d_orgs_new = PerformBackwardsTracking(d_orgs, parameters)

    %% get segmentation images if available
    if (parameters.seedBasedDetection == false)
        inputRawFiles = dir([parameters.rawImageFolder parameters.inputFilter]);
        detectionFiles = dir([parameters.detectionFolder parameters.detectionFilter]);
    end

    numFrames = size(d_orgs, 2);

	%% perform the tracking by clustering
	d_orgs_new = zeros(80000, size(d_orgs,2), size(d_orgs,3));
	objectRadii = ones(size(d_orgs,2),1);
	currentTrackId = 1;
	for i=numFrames:-1:1

		%% get the valid locations at the current position
		validIndices = find(squeeze(d_orgs(:,i,3) > 0));
		validPositions = squeeze(d_orgs(validIndices, i, :));

        if (parameters.seedBasedDetection == true)
            %% perform automatic cluster cutoff calculation
            if (parameters.clusterCutoff < 0)
                kdtree = KDTreeSearcher(validPositions(:,3:5));

                [~, nnDistances] = knnsearch(kdtree, validPositions(:,3:5), 'K', 8);
                distances = mean(nnDistances(:,3:end), 2);

                currentClusterCutoff = 0.5 * mean(distances);
            else
                currentClusterCutoff = clusterCutoff;
            end
        else
            currentClusterCutoff = mean(validPositions(:, parameters.clusterRadiusIndex));
        end
        
        %% set the object radii for later segmentation
        objectRadii(i) = currentClusterCutoff;

        %% cluster nearby seeds
        Z = linkage(validPositions(:,3:5), 'ward');
        clusterIndices = cluster(Z, 'cutoff', currentClusterCutoff, 'criterion', 'distance');


		%% initialize track ids at the last frame
		%% propagate seeds to the previous frame using optical flow
		%% cluster seeds in the previous frame
		%% case 1: one of the seeds in a cluster has a tracking id -> assign tracking id to all other points
		%% case 2: none of the seeds in a cluster has a tracking id -> assign new tracking id (#current tracks + 1)
		%% case 3: two or more of the seeds have a tracking id -> introduce merge and add new seed with new tracking id (#current tracks + 1)
		%% special case if only one tracked location resides in a cluster -> potential dead end, i.e., apply intensity heuristic or fuse to nearest neighbor
		for j=unique(clusterIndices)'
			currentIndices = find(clusterIndices == j);
			trackingIds = unique(validPositions(currentIndices, parameters.trackingIdIndex));

			%% propagate tracking id if it already exists
			if (sum(trackingIds > 0) == 0)
				d_orgs_new(currentTrackId, i, :) = mean(validPositions(currentIndices, :), 1);
				d_orgs_new(currentTrackId, i, parameters.trackingIdIndex) = currentTrackId;
				currentTrackId = currentTrackId + 1;

				%% if a single tracking id exists already, use it
			elseif (sum(trackingIds > 0) == 1)
				existingTrackingId = max(validPositions(currentIndices, parameters.trackingIdIndex));
				d_orgs_new(existingTrackingId, i, :) = mean(validPositions(currentIndices, :), 1);
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
				d_orgs_new(currentTrackId, i, :) = mean(validPositions(currentIndices, :), 1);
				d_orgs_new(currentTrackId, i, parameters.trackingIdIndex) = currentTrackId;

				%% update the successors
				for k=trackingIds(trackingIds>0)
					d_orgs_new(k, i+1, parameters.predecessorIdIndex) = currentTrackId;
				end

				currentTrackId = currentTrackId + 1;
			end
		end

		%% propagate tracked seeds backwards in time using optical flow
		if (i > 1)
			
			%% extract the previous, current and next positions
			valindIndices = find(squeeze(d_orgs_new(:,i,3) > 0));
			currentIndex = max(find(squeeze(d_orgs(:,i-1,3) > 0))) + 1;

			for j=valindIndices'

				currentPosition = round(squeeze(d_orgs_new(j, i, :)));

    			%% TODO: potentially estimate weighted centroid of a small region to optimize localization
                previousDirection = [0,0,0];
				
				%% add the seeds and the seed predictions to the seed frames
				previousPosition = currentPosition(parameters.prevPosIndices);

				%% write seed candidates to the result image
                d_orgs(currentIndex, i-1, :) = currentPosition;
                d_orgs(currentIndex, i-1, 3:5) = previousPosition;
                currentIndex = currentIndex + 1;
			end
        end
        
                

		disp(sprintf('Finished tracking for frame %i (%.2f %%)', i, 100*(numFrames-i)/numFrames));
    end
end