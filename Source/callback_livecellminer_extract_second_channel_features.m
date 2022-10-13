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

%% add haralick function for feature computation
addpath([parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'toolbox' filesep 'haralick' filesep]);

%% preload image patches if not available yet
if (~exist('rawImagePatches', 'var') || isempty(rawImagePatches))
    callback_livecellminer_load_image_files;
end

%% segmentation mode to be used (extend, shring, toroidal)
dlgtitle = '2nd Channel Feature Extraction:';
dims = [1 100];
additionalUserSettings = inputdlg({'Segmentation Mode (0: Extend, 1: Shrink, 2: Toroidal)', 'Structuring Element (e.g., disk, square, diamond)', 'Structuring Element Radius', 'Extract Advanced Features?'}, dlgtitle, dims, {'0', 'disk', '2', '0'});
if (isempty(additionalUserSettings))
    disp('No feature extraction settings provided, stopping processing ...');
    return;
else
    %% convert parameters to the required format
    extractionMode = str2double(additionalUserSettings{1});
    strelType = additionalUserSettings{2};
    strelRadius = str2double(additionalUserSettings{3});
    extractAdvancedFeatures = str2double(additionalUserSettings{4}) > 0;
    structuringElement = strel(strelType, strelRadius);
    
    %% spefify feature name parts
    if (extractionMode == 0)
        extractionSuffix = 'Ext';
    elseif (extractionMode == 1)
        extractionSuffix = 'Shr';
    elseif (extractionMode == 2)
        extractionSuffix = 'Tor';
    else
        extractionSuffix = '';
    end
    
    extractionSuffix = ['-' extractionSuffix '-' strelType '-r=' num2str(strelRadius)];
end

%% loop through all image patches and compute the secondary channel features
numCells = size(d_orgs,1);
numFrames = size(d_orgs,2);

%% assemble the feature names
featureNames = cell(3,1);
featureNames{1} = ['Ch2-MeanIntensity' extractionSuffix];
featureNames{2} = ['Ch2-StdIntensity' extractionSuffix];
featureNames{3} = ['Ch2-MaxIntensity' extractionSuffix];
featureNames{4} = ['Ch1-Ch2-MI-Ratio' extractionSuffix];
featureNames{5} = ['Ch2-Outer-Inner-Mean-Ratio' extractionSuffix];
featureNames{6} = ['Ch2-Max-Int-Displacement' extractionSuffix];

if (extractAdvancedFeatures == true)
    extractionPrefix = 'Ch2-';
    featureNames{7} = [extractionPrefix 'Area', extractionSuffix];
    featureNames{8} = [extractionPrefix 'MajorAxisLength', extractionSuffix];
    featureNames{9} = [extractionPrefix 'MinorAxisLength', extractionSuffix];
    featureNames{10} = [extractionPrefix 'Orientation', extractionSuffix];
    featureNames{11} = [extractionPrefix 'Circularity',  extractionSuffix];
    featureNames{12} = [extractionPrefix 'MeanIntensity',  extractionSuffix];
    featureNames{13} = [extractionPrefix 'StdIntensity', extractionSuffix];
    featureNames{14} = [extractionPrefix 'StdIntensityGradMag' extractionSuffix];
    featureNames{15} = [extractionPrefix 'AngularSecondMoment', extractionSuffix];
    featureNames{16} = [extractionPrefix 'Contrast', extractionSuffix];
    featureNames{17} = [extractionPrefix 'Correlation', extractionSuffix];
    featureNames{18} = [extractionPrefix 'Variance', extractionSuffix];
    featureNames{19} = [extractionPrefix 'InverseDifferenceMoment(Homogeneity)' extractionSuffix];
    featureNames{20} = [extractionPrefix 'SumAverage', extractionSuffix];
    featureNames{21} = [extractionPrefix 'SumVariance', extractionSuffix];
    featureNames{22} = [extractionPrefix 'SumEntropy', extractionSuffix];
    featureNames{23} = [extractionPrefix 'Entropy', extractionSuffix];
    featureNames{24} = [extractionPrefix 'DifferenceVariance', extractionSuffix];
    featureNames{25} = [extractionPrefix 'DifferenceEntropy ', extractionSuffix];
    featureNames{26} = [extractionPrefix 'InformationMeasureofCorrelationI', extractionSuffix];
    featureNames{27} = [extractionPrefix 'InformationMeasureofCorrelationII', extractionSuffix];
    featureNames{28} = [extractionPrefix 'MaximalCorrelationCoefficient', extractionSuffix];
end
numFeatures = length(featureNames);

additionalFeatures = zeros(numCells, numFrames, numFeatures);

%% start timer
tic;

%% initialize the thread data collection variable
threadResults = cell(numFrames, 1);

%% process all frames
parfor i=1:numFrames
    
    %% initialize the current results
    currentResults = zeros(numCells, numFeatures);
    
    %% extract features for all cells
    for j=1:numCells
        
        %% get the current input images
        maskImage = maskImagePatches{j, i};
        rawImage1 = double(rawImagePatches{j, i});
        rawImage2 = double(rawImagePatches2{j, i});
        
        %% compute the mask
        if (extractionMode == 0)
            maskImageCh2 = imdilate(maskImage, structuringElement);
        elseif (extractionMode == 1)
            maskImageCh2 = imerode(maskImage, structuringElement);
        else
            maskImageCh2 = imdilate(maskImage, structuringElement) - maskImage;
        end
        
        %% compute the current feature
        currentRegionProps = regionprops(maskImageCh2, 'PixelIdxList', 'Centroid');
        if (isempty(currentRegionProps))
            continue;
        end
        
        %% compute the actual features
        currentResults(j,1) = mean(rawImage2(currentRegionProps(1).PixelIdxList));
        currentResults(j,2) = std(rawImage2(currentRegionProps(1).PixelIdxList));
        currentResults(j,3) = max(rawImage2(currentRegionProps(1).PixelIdxList));
        currentResults(j,4) = mean(rawImage1(currentRegionProps(1).PixelIdxList)) / mean(rawImage2(currentRegionProps(1).PixelIdxList));
        
        %% characterize the maximum displacement
        outerIntensities = rawImage2(maskImageCh2 > 0 & ~maskImage);
        innerIntensities = rawImage2(maskImage > 0);
        globalUpperQuantile = quantile(rawImage2(maskImageCh2>0), 0.75);
        outerUpperQuantile = quantile(outerIntensities, 0.75);
        innerUpperQuantile = quantile(innerIntensities, 0.75);
        
        globalUpperQuantileIndices = find((maskImageCh2 > 0 & rawImage2 > globalUpperQuantile));
        globalUpperQuantileIntensities = rawImage2(globalUpperQuantileIndices);
        globalUpperQuantileIntensities = globalUpperQuantileIntensities / sum(globalUpperQuantileIntensities);
        [xpos, ypos] = ind2sub(size(maskImageCh2), globalUpperQuantileIndices);
        upperQuantileCentroid = [sum(globalUpperQuantileIntensities .* xpos), sum(globalUpperQuantileIntensities .* ypos)];
        
        currentResults(j,5) = mean(outerIntensities(outerIntensities>outerUpperQuantile)) / mean(innerIntensities(innerIntensities>innerUpperQuantile));
        currentResults(j,6) = norm(parameter.projekt.patchRescaleFactor * (upperQuantileCentroid - currentRegionProps(1).Centroid));
        
        if (extractAdvancedFeatures)
            [~, featureVector] = callback_livecellminer_extract_nucleus_features(rawImage2, double(maskImageCh2));
            currentResults(j,7:end) = featureVector;
        end
    end
    
    %% pass results to the thread data collector
    threadResults{i} = currentResults;
end

%% add new features to d_orgs
if (var_bez(end,1) == 'y')
    var_bez = var_bez(1:end-1,:);
end

%% add features to d_orgs
for i=1:numFeatures
    
    %% add new empty time series
    d_orgs(:,:,end+1) = 0; %#ok<SAGROW>
    
    %% add results for all frames
    for j=1:numFrames
        d_orgs(:,j,end) = threadResults{j}(:,i);
    end
    
    %% update the specifiers
    var_bez = char(var_bez, featureNames{i});
end

%% update window and show success message
aktparawin;
disp(['Finished extracting features for secondary channel. Elapsed time: ' num2str(toc)]);