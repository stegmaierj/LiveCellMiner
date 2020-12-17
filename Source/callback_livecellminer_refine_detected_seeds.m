%%
% LiveCellMiner.
% Copyright (C) 2020 D. Moreno-Andres, A. Bhattacharyya, W. Antonin, J. Stegmaier
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

function [d_orgs] = RefineDetectedSeeds(d_orgs, parameters)

    %% return if no refinement is required
    if (parameters.numRefinementSteps <= 0)
        disp('Skipping seed refinement...');
        return; 
    end

    %% TODO: replace with parametrizable folders
    rawImageFolder = parameters.rawImageFolder;
    rawImageFiles = dir([rawImageFolder parameters.inputFilter]);
    
    %% get the required parameters
    numFrames = size(d_orgs, 2);
    numRefinementSteps = parameters.numRefinementSteps;
    refinementRadius = parameters.refinementRadius;
    debugFigures = parameters.debugFigures;
    
    %% extract all seed points and perform seed point refinement based on iterative weighted centroid estimation
    for i=numFrames:-1:2

        %% load the previous raw image to reestimate the seeds
        prevRawImage = single(loadtiff([rawImageFolder rawImageFiles(i-1).name]));
        prevRawImage = 255 * (prevRawImage - min(prevRawImage(:))) / (max(prevRawImage(:)) - min(prevRawImage(:)));
        imageSize = size(prevRawImage);

        validIndices = find(squeeze(d_orgs(:,i,1) > 0));

        %% extract and refine the seed points of the current time point
        for j=validIndices'

            %% refine the weighted centroid
            weightedCentroid = squeeze(round(d_orgs(j, i, parameters.prevPosIndices)));
            for k=1:numRefinementSteps

                %% extract intensities in a cube surrounding the current weighted centroid
                rangeX = max(1, (weightedCentroid(2) - refinementRadius)):min((weightedCentroid(2) + refinementRadius), imageSize(1));
                rangeY = max(1, (weightedCentroid(1) - refinementRadius)):min((weightedCentroid(1) + refinementRadius), imageSize(2));

                %% identify neighborhood positions and the corresponding intensities
                [xpos, ypos] = meshgrid(rangeY, rangeX);
                intensities = double(prevRawImage(rangeX, rangeY));
                
                %% compute the current weighted centroid
                xpos = sum(xpos(:) .* intensities(:)) / sum(intensities(:));
                ypos = sum(ypos(:) .* intensities(:)) / sum(intensities(:));
                zpos = ones(size(xpos));

                weightedCentroid = round([xpos, ypos, zpos]);
            end

            %% set the refined weighted centroid
            d_orgs(j, i, parameters.prevPosIndices) = weightedCentroid;
        end

        %% plot debug figures if enabled
        if (debugFigures == true)
            
            figure(1); clf; hold on;
            
            %% plot previous raw image with current and refined current seeds
            imagesc(prevRawImage); 
            
            currentPositions = squeeze(d_orgs(validIndices, i, parameters.posIndices));
            previousPositions = squeeze(d_orgs(validIndices, i, parameters.prevPosIndices));
            
            plot(currentPositions(:,1), currentPositions(:,2), '.g');
            plot(previousPositions(:,1), previousPositions(:,2), 'or');
            for k=1:size(previousPositions,1)
                plot([currentPositions(k,1), previousPositions(k,1)], [currentPositions(k,2), previousPositions(k,2)], '-r');
            end
        end
        
        fprintf('Extracting and refining detections %i / %i\n', numFrames - i + 1, numFrames);
    end
end