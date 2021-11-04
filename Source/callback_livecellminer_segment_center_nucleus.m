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

%% function to segment a single nucleus that is assumed to be located in the center of the image.
%% nuclei partially visible or touching are removed automatically
function [maskImage] = callback_livecellminer_segment_center_nucleus(rawImage, singleCenterCC)

    %% set to true to enable debug figures
    debugFigures = false;

    %% adjust the contrast of the input image
    rawImage = imadjust(rawImage);

    %% get the raw image size and compute the image center
    imageSize = size(rawImage);
    imageCenter = round(imageSize / 2);

    %% slightly smooth the input image to obtain more robust thresholding
    smoothedRawImage = medfilt2(rawImage, [5,5]);

    %% specify the center range to compute the minimum and maximum intensity in.
    centerRadius = 5;
    rangeX = max(imageCenter(1)-centerRadius, 1):min(imageCenter(1)+centerRadius, imageSize(1));
    rangeY = max(imageCenter(2)-centerRadius, 1):min(imageCenter(2)+centerRadius, imageSize(2));
    maxCenterIntensity = double(max(max(smoothedRawImage(rangeX, rangeY))));
    smoothedRawImage(smoothedRawImage > maxCenterIntensity) = maxCenterIntensity;
    if (isa(smoothedRawImage,'uint16'))
        minCenterIntensity = double(min(min(smoothedRawImage(rangeX, rangeY)))) / 65536;
    elseif (isa(smoothedRawImage,'uint8'))
        minCenterIntensity = double(min(min(smoothedRawImage(rangeX, rangeY)))) / 256;
    else
        minCenterIntensity = double(min(min(smoothedRawImage(rangeX, rangeY))));
    end

    %% compute Otsu threshold to obtain the initial mask image
    threshold = graythresh(smoothedRawImage);
    threshold = 0.5 * (threshold + minCenterIntensity);
    maskImage = imbinarize(smoothedRawImage, threshold);

    %% compute the distance map of the mask image and set the minima to the seed image
    distanceMap = bwdist(~maskImage);
    distanceMap = max(distanceMap(:)) - distanceMap;
    distanceMap = imgaussfilt(distanceMap, 2);
   
    seedImage = (distanceMap - imhmin(distanceMap, 2)) < 0;
    
    %% only preserve largest connected component by default
    %% for a few frames before and after the division, this strategy is disabled to successfully split anaphase frames.
    if (singleCenterCC == true)
        seedRegionProps = regionprops(seedImage, 'Area', 'PixelIdxList', 'Centroid');
        minIndex = -1;
        minDistance = Inf;
        for i=1:length(seedRegionProps)
            currentDistance = norm(seedRegionProps(i).Centroid - imageCenter);
            if (currentDistance < minDistance)
                minDistance = currentDistance;
                minIndex = i;
            end
        end
        seedImage(:) = 0;
        seedImage(seedRegionProps(minIndex).PixelIdxList) = 1;
    end
    
    %% add background label
    seedImage(:,1) = 1;
    seedImage(:,end) = 1; 
    seedImage(1,:) = 1;
    seedImage(end,:) = 1;
    
    %% impose the labels onto the distance map for the seeded watershed
    distanceMap = imimposemin(distanceMap, seedImage);
       
    %% compute the watershed lines of the distance map and apply them to split connected objects
    watershedImage = watershed(distanceMap);
    watershedLines = watershedImage ~= 0;
    maskImage = watershedLines .* maskImage;

    %% identify the center object and suppress all other objects
    labelImage = bwlabel(maskImage);
    centerLabel = labelImage(imageCenter(1), imageCenter(2));

    %% in some cases the object is slightly off the center. In this case, determine the closest object to the patch center.
    if (centerLabel == 0)

        %% compute the region props and determine the closest label to the center
        currentRegionProps = regionprops(labelImage, 'Centroid', 'Area'); %#ok<MRPBW>
        minIndex = 0;
        minDistance = inf;
        for i=1:length(currentRegionProps)

            %% skip empty labels
            if (currentRegionProps(i).Area <= 0)
                continue;
            end

            %% compute the current distance
            currentDistance = norm(currentRegionProps(i).Centroid - imageCenter);
            if (currentDistance < minDistance)
                minIndex = i;
                minDistance = currentDistance;
            end
        end

        %% assign the identified label
        centerLabel = minIndex;
    end

    %% remove all other cell parts
    invalidIndices = labelImage ~= centerLabel;
    maskImage(invalidIndices) = 0;
    maskImage = bwfill(maskImage, 'holes');
    maskImage = imclose(maskImage, strel('disk', 3));
    
    %% some debug figures
    if (debugFigures == true)
        figure(3); imagesc(distanceMap);

        figure(4);
        subplot(1,3,1);
        imagesc(smoothedRawImage);

        subplot(1,3,2);
        imagesc(maskImage);

        subplot(1,3,3);
        imagesc(maskImage .* double(rawImage));
        caxis([min(rawImage(:)), max(rawImage(:))]);
    end
end