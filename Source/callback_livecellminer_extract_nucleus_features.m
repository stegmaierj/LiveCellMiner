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

%% Script to extract features from image snippet using a segmentation mask
function [featureNames, featureVector] = callback_livecellminer_extract_nucleus_features(rawImage, maskImage)

    %% enable / disable debug figures
    debugFigures = false;

    %% Find basic features from raw image
    adjustedRawImg = imadjust(rawImage);
    labelImage = bwlabel(maskImage);
    gradMagImage  = imgradient(rawImage);
    featureNames1 = char('Area', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Circularity', 'MeanIntensity', 'StdIntensity', 'StdIntensityGradMag');

    % compute the basic features from the raw image
    regPropRaw = regionprops(labelImage, rawImage, 'Area', 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Circularity', 'MeanIntensity'); %#ok<MRPBW>

    % extract the label of the connected component located in the center
    imageSize = size(labelImage);
    imageCenter = round(imageSize / 2);
    centerLabel = labelImage(imageCenter(1), imageCenter(2));
    
    if centerLabel <= 0
        minDist = inf;
        minIndex = 0;
        for i=1:length(regPropRaw)
            if (regPropRaw(i).Area <= 0)
                continue;
            end

            currDist = norm(regPropRaw(i).Centroid - imageCenter);

            if (currDist < minDist)
               minDist = currDist;
               minIndex = i;
            end
        end

        centerLabel = minIndex;
    end

    % concatenate features to a vector
    if centerLabel <= 0
        featureVector1 = zeros();
    else
        validIndices = labelImage == centerLabel;
        stdIntensity = std2(rawImage(validIndices));   % std for raw image
        stdIntensityGradMag = std2(gradMagImage(validIndices));
        featureVector1 = [regPropRaw(centerLabel).Area, regPropRaw(centerLabel).MajorAxisLength, ...
                          regPropRaw(centerLabel).MinorAxisLength, regPropRaw(centerLabel).Orientation, regPropRaw(centerLabel).Circularity, ...
                          regPropRaw(centerLabel).MeanIntensity, stdIntensity, stdIntensityGradMag];
    end

    %% extract the Haralick features
    segmentedImage = maskImage.* adjustedRawImg;    % CHECK: might need to write uint16(maskImage).*adjustedRawImg
    
    if (debugFigures == true)
        imagesc(segmentedImage);
    end
    numLevels = 64;

    % compute the graylevel co-occurence matrices
    [glcm1, SI1] = graycomatrix(segmentedImage, 'offset', [0 1], 'Symmetric', true, 'NumLevels', numLevels);
    [glcm2, SI2] = graycomatrix(segmentedImage, 'offset', [1 0], 'Symmetric', true, 'NumLevels', numLevels);
    [glcm3, SI3] = graycomatrix(segmentedImage, 'offset', [1 1], 'Symmetric', true, 'NumLevels', numLevels);
    [glcm4, SI4] = graycomatrix(segmentedImage, 'offset', [-1 1], 'Symmetric', true, 'NumLevels', numLevels);

    % remove the first and second rows to discard peak in co-occurence matrix
    glcm1_new = glcm1(2:end, 2:end);
    glcm2_new = glcm2(2:end, 2:end);
    glcm3_new = glcm3(2:end, 2:end);
    glcm4_new = glcm4(2:end, 2:end);
        
    % debugging code to find why co-oc matrix is zero
    if (debugFigures && (sum(sum(glcm1_new)) == 0 || sum(sum(glcm2_new)) == 0 || sum(sum(glcm3_new)) == 0 || sum(sum(glcm4_new)) == 0))

        figure(1);
        imagesc(adjustedRawImg);
        title('Adjusted raw image'); colorbar;

        figure(2);
        title('Scaled images');
        subplot(2,2,1);
        imagesc(SI1); colorbar;
        subplot(2,2,2);
        imagesc(SI2); colorbar;
        subplot(2,2,3);
        imagesc(SI3); colorbar;
        subplot(2,2,4);
        imagesc(SI4); colorbar;

        figure(3);
        title('co-oc matrix for curtailed image');
        subplot(2,2,1);
        imagesc(glcm1(2:end, 2:end)); colorbar;
        subplot(2,2,2);
        imagesc(glcm2(2:end, 2:end)); colorbar;
        subplot(2,2,3);
        imagesc(glcm3(2:end, 2:end)); colorbar;
        subplot(2,2,4);
        imagesc(glcm4(2:end, 2:end)); colorbar;

        figure(4);
        title('co-oc matrix for whole image');
        subplot(2,2,1);
        imagesc(glcm1); colorbar;
        subplot(2,2,2);
        imagesc(glcm2); colorbar;
        subplot(2,2,3);
        imagesc(glcm3); colorbar;
        subplot(2,2,4);
        imagesc(glcm4); colorbar;

    end

    % extract the Haralick features from the background corrected co-occurence matrices
    try
        hf1 = haralickTextureFeatures(glcm1_new);
        hf2 = haralickTextureFeatures(glcm2_new);
        hf3 = haralickTextureFeatures(glcm3_new);
        hf4 = haralickTextureFeatures(glcm4_new);
    catch
        hf1 = zeros(14, 1);
        hf2 = zeros(14, 1);
        hf3 = zeros(14, 1);
        hf4 = zeros(14, 1);
    end
    
    % compute the average Haralick features for rotation invariance to some extent
    featureVector2 = mean([hf1, hf2, hf3, hf4], 2);
    featureNames2 = char('AngularSecondMoment', 'Contrast', 'Correlation', 'Variance', 'InverseDifferenceMoment(Homogeneity)',...
                         'SumAverage', 'SumVariance', 'SumEntropy', 'Entropy', 'DifferenceVariance', 'DifferenceEntropy ', 'InformationMeasureofCorrelationI', ...
                         'InformationMeasureofCorrelationII', 'MaximalCorrelationCoefficient');
                     
%     %% perform classification using the classifiers for inter- and metaphase
%     multiChannelImage = cat(3, rawImage, rawImage.*maskImage, maskImage);
%     probabilityInter = 0; %predict(networkInter.net, multiChannelImage);
%     probabilityMeta = 0; %predict(networkMeta.net, multiChannelImage);
%     featureNames3 = char('ProbabilityOfInterphase', 'ProbabilityOfMetaphase');
    
    %% combine the shape features and the Haralick texture features
    featureNames = char(featureNames1, featureNames2);
    featureVector = [featureVector1, transpose(featureVector2)];

    %% show debug figures if enabled
    if debugFigures == true
        figure(1);
        imagesc(adjustedRawImg);
        title('Adjusted raw image'); colorbar;
        figure(2);
        title('Scaled images');
        subplot(2,2,1);
        imagesc(SI1); colorbar;
        subplot(2,2,2);
        imagesc(SI2); colorbar;
        subplot(2,2,3);
        imagesc(SI3); colorbar;
        subplot(2,2,4);
        imagesc(SI4); colorbar;

        figure(3);
        title('co-oc matrix for curtailed image');
        subplot(2,2,1);
        imagesc(glcm1(2:end, 2:end)); colorbar;
        subplot(2,2,2);
        imagesc(glcm2(2:end, 2:end)); colorbar;
        subplot(2,2,3);
        imagesc(glcm3(2:end, 2:end)); colorbar;
        subplot(2,2,4);
        imagesc(glcm4(2:end, 2:end)); colorbar;

        figure(4);
        title('co-oc matrix for whole image');
        subplot(2,2,1);
        imagesc(glcm1); colorbar;
        subplot(2,2,2);
        imagesc(glcm2); colorbar;
        subplot(2,2,3);
        imagesc(glcm3); colorbar;
        subplot(2,2,4);
        imagesc(glcm4); colorbar;
    end
end

