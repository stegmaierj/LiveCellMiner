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

%% Performs segmentation based on segmentation label propagation
function d_orgs = callback_livecellminer_perform_segmentation_based_tracking(parameters)

    %% load additional dependencies
    addpath('toolbox/saveastiff_4.3/');
    
    %%%%%%%%%% PARAMETERS %%%%%%%%%%%
    useRegistrationBasedCorrection = false;
    preloadData = true; %% only set to false if debugging to avoid reloading the data at each call
    minVolume = 100; %% excludes objects smaller than this volume
    skipFrames = 1; %% the allowed number of frames to skip for tracking an object
    maxCellSize = 10000; % 4000 for Weiyis Project;
    %%%%%%%%%% PARAMETERS %%%%%%%%%%%
    
    %% specify elastix path
    elastixRootDir = [pwd '/../ThirdParty/Elastix/'];
    if (ismac)
        elastixPath = [elastixRootDir 'macOS/bin/'];
    elseif (ispc)
        elastixPath = [elastixRootDir 'Windows/'];
        elastixPath = strrep(elastixPath, '/', filesep);
    else
        elastixPath = [elastixRootDir 'Linux/bin/'];
    end
    
%     %% specify the output directory
%     outputRoot = uigetdir('C:\Users\stegmaier\Downloads\20211129_Stiching_EGFP_Caax-H2a-mCherry_CA-Mypt1\', 'Please select the output root directory ...');
%     outputRoot = [outputRoot filesep];
%     if (~isfolder(outputRoot)); mkdir(outputRoot); end
    
    %% get the input directories
    inputDir = parameters.augmentedMaskFolder;
    disp(['Using segmented images contained in the folder ' inputDir ' for tracking.']);    
    

    %% get the transformations directory
    if (useRegistrationBasedCorrection == true)
        transformationDir = [outputRoot 'Transformations' filesep];
        if (~isfolder(transformationDir))
            transformationDir = uigetdir('D:\ScieboDrive\Projects\2021\KnautNYU_PrimordiumCellSegmentation\Processing\Transformations\', 'Specify the transformation directory');
            transformationDir = [transformationDir filesep];
            transformationFiles = dir([transformationDir '*.txt']);
        else
            disp(['Using transformations contained in the folder ' transformationDir]);    
        end
    end
    
%     %% create the result folder for the tracking data
%     outputFolderTracked = [outputRoot 'Nuclei_Tracked' filesep];
%     if (~isfolder(outputFolderTracked)); mkdir(outputFolderTracked); end
%     
%     outputFolderTrackedSplit = [outputRoot 'Nuclei_Tracked_Split' filesep];
%     if (~isfolder(outputFolderTrackedSplit)); mkdir(outputFolderTrackedSplit); end
    
    %% get information about the input/output files
    inputFiles = dir([inputDir '*.png']);
    numFrames = length(inputFiles);
    
    %% specify save options
    clear options;
    options.overwrite = true;
    options.compress = 'lzw';
    
    %% preload data to have all frames in memory for faster processing
    if (preloadData == true)
        
        %% clear previous data
        clear resultImages;
        clear rawImages;
        clear segmentationImages;
        clear regionProps;
        
        %% load and transform all input images
        for i=1:numFrames
            
            %% load the current image and obtain the region props
            segmentationImages{i} = uint16(imread([inputDir inputFiles(i).name]));
            regionProps{i} = regionprops(segmentationImages{i}, 'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
                    
            %% remove spurious objects that have their centroid outside of the valid area
            for j=1:size(regionProps{i})
                if (regionProps{i}(j).Area <= 0)
                    continue;
                end
                
                currentCentroid = round(regionProps{i}(j).Centroid);
    
                if (length(currentCentroid) > 2)
                    currentLabel = segmentationImages{i}(currentCentroid(2), currentCentroid(1), currentCentroid(3));
                else
                    currentLabel = segmentationImages{i}(currentCentroid(2), currentCentroid(1));
                end
    
                if (currentLabel ~= j)
                    segmentationImages{i}(regionProps{i}(j).PixelIdxList) = 0;
                end
            end
            
            %% recompute the region props after removing spurious objects
            regionProps{i} = regionprops(segmentationImages{i}, 'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
            
            %% transform the image at time point t to time point t-1 for better overlaps
            if (useRegistrationBasedCorrection == true)
                
                %% save temporary image
                outputDirTemp = [tempdir num2str(i) filesep];
                inputFile = [outputDirTemp 'currImage.tif'];
                saveastiff(uint16(segmentationImages{i}), inputFile, options);
                
                %% apply transformation to the segmentation image
                transformixCommand = [elastixPath 'transformix.sh ' ...
                    '-in ' inputFile ' ' ...
                    '-out ' outputDirTemp ' ' ...
                    '-tp ' transformationDir transformationFiles(i).name];
                
                if (ispc)
                    transformixCommand = strrep(transformixCommand, 'transformix.sh', 'transformix.exe');
                end
                system(transformixCommand);
                
                %% load the transformed image at time point t and the previous image at t-1
                transformedCurrentImage = loadtiff([outputDirTemp 'result.tif']);
                movefile([outputDirTemp 'result.tif'], [resultDirTrans strrep(inputFiles(i).name, '.tif', '_Trans.tif')]); rmdir(outputDirTemp, 's');
                
                %% save the regionprops for later computations
                regionPropsTransformed{i} = regionprops(transformedCurrentImage, 'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
            else
                regionPropsTransformed{i} = regionProps{i};
            end
            
            %% initialize the result images
            resultImages{i} = uint16(zeros(size(segmentationImages{i})));
        end
    end
    
    %% clear previous tracking results
    clear visitedIndices;
    for i=1:numFrames
        visitedIndices{i} = zeros(size(regionProps{i},1), 1); %#ok<SAGROW>
        resultImages{i}(:) = 0;
    end
    
    %% initialize current tracking id
    currentTrackingId = 1;
    
    %% iterate over all frames in a backward fashion
    for i=numFrames:-1:1

        if (i==170)
            test = 1;
        end
    
        %% process all cells contained in the current frame
        for j=1:size(regionProps{i},1)
            
            if (i==4 && (j == 178 || j == 179))
                test = 1;
            end
    
            %% skip processing if cell was already visited or is below the minimum volume
            if (regionProps{i}(j).Area < minVolume || visitedIndices{i}(j))
                continue;
            end
    
            if (currentTrackingId == 54)
                test = 1;
            end
            
            %% get the current object and add it to the result image
            currentFrame = i;
            currentObject = regionProps{i}(j).PixelIdxList;
            resultImages{currentFrame}(currentObject) = currentTrackingId;
            
            %% use transformed object, if registration correction is enabled
            if (useRegistrationBasedCorrection == true)
                currentObject = regionPropsTransformed{i}(j).PixelIdxList;
            end
            
            %% set visited status of the current object
            visitedIndices{i}(j) = 1;
            
            %% track current object as long as possible
            while currentFrame > 1
                
                matchIndices = [];
                matchDiceIndices = [];
                for s=1:skipFrames
    
                    if ((currentFrame-s) < 1)
                        matchIndices = [];
                        break;
                    end
    
                    %% identify the potential matches
                    currentIndex = unique(segmentationImages{currentFrame}(currentObject));
                    potentialMatches = segmentationImages{currentFrame-s}(currentObject);
                    potentialMatchIndices = unique(potentialMatches);
                    potentialMatchIndices(potentialMatchIndices == 0) = [];
    
                    if (isempty(potentialMatchIndices))
                        continue;
                    end
                    
                    for m=potentialMatchIndices'
    
                        %% TODO: add forward consistency check for largest overlap matches!
                        matchObject = regionProps{currentFrame-s}(m).PixelIdxList;
                        potentialMatchesForward = segmentationImages{currentFrame}(matchObject);
                        potentialMatchIndicesFw = unique(potentialMatchesForward);
                        potentialMatchIndicesFw(potentialMatchIndicesFw == 0) = [];
            
                        matchCountsFw = zeros(size(potentialMatchIndicesFw));
                        diceIndicesFw = zeros(size(potentialMatchIndicesFw));
                        for k=1:length(matchCountsFw)
                            matchCountsFw(k) = sum(potentialMatchesForward == potentialMatchIndicesFw(k));
                            diceIndicesFw(k) = 2 * (matchCountsFw(k)) / (length(potentialMatchesForward) + regionProps{currentFrame}(potentialMatchIndicesFw(k)).Area);
                        end
            
                        [maxOverlapFw, maxIndexFw] = max(diceIndicesFw);
                        matchIndexFw = potentialMatchIndicesFw(maxIndexFw);
            
                        
                        %% skip if the linked object is already taken or if no object was found
                        if (ismember(matchIndexFw, currentIndex))
                            matchIndices = [matchIndices, m];
                            matchDiceIndices = [matchDiceIndices, maxOverlapFw];
                        end
                    end
                    
    
    %                 %% determine the best match
    %                 matchCounts = zeros(size(potentialMatchIndices));
    %                 diceIndices = zeros(size(potentialMatchIndices));
    %                 for k=1:length(matchCounts)
    %                     matchCounts(k) = sum(potentialMatches == potentialMatchIndices(k));
    %                     diceIndices(k) = 2 * (matchCounts(k)) / (length(currentObject) + regionProps{currentFrame-s}(potentialMatchIndices(k)).Area);
    %                 end
    % 
    %                 [sortedDiceIndices, sortedIndices] = sort(diceIndices, 'descend');
    % 
    %                 if (length(sortedDiceIndices) > 1)
    %                     secondNNRatio = sortedDiceIndices(2) / sortedDiceIndices(1);
    %                     if (secondNNRatio > secondNNRatioThreshold)
    %                         test = 1;
    %                         disp('Oversegmentation Detected!');
    %                     end
    %                 else
    % 
    %                     %% set the match index as the maximum overlap segment
    %                     [maxOverlap, maxIndex] = max(diceIndices);
    %                     matchIndex = potentialMatchIndices(maxIndex);
    %         
    %                     %% skip if the linked object is already taken or if no object was found
    %                     if (~isempty(matchIndex))
    %                         currentSkipFrame = s;
    %                         break;
    %                     end
    %                 end
    
                    % skip if the linked object is already taken or if no object was found
                    if (~isempty(potentialMatchIndices))
                        currentSkipFrame = s;
                        break;
                    end
                end
    
                if (isempty(matchIndices))
                    break;
                end
    
                %% add intermediate masks for frames where the segmentation is missing
                %% TODO: evenly distribute between current and previous frame.
                for s=1:(currentSkipFrame-1)
                    resultImages{currentFrame-s}(currentObject) = currentTrackingId;
                end
    
                %% select only best match if the current segment is a potentially undersegmented object
                [sortedDiceIndices, sortedIndices] = sort(matchDiceIndices, 'descend');
    
                if (length(currentObject) > maxCellSize)
                    matchIndices = matchIndices(sortedIndices(1));
                end
    
    
                currentObject = [];
                for matchIndex=matchIndices
    
                    if (visitedIndices{currentFrame-currentSkipFrame}(matchIndex) > 0)
                        continue;
                    end
    
                    %% update the matched object and add it to the next result image
                    visitedIndices{currentFrame-currentSkipFrame}(matchIndex) = 1;
                    currentObject = [currentObject; regionProps{currentFrame-currentSkipFrame}(matchIndex).PixelIdxList];
                end
    
                resultImages{currentFrame-currentSkipFrame}(currentObject) = currentTrackingId;
                    
                %% TODO!!!! CHANGE !!! AFTER !!! ADDITION OF MULTIPLE SEGMENTS !!! use the transformed current object for better alignment
                if (useRegistrationBasedCorrection == true && length(regionPropsTransformed{currentFrame-currentSkipFrame}) >= matchIndex)
                    currentObject = regionPropsTransformed{currentFrame-currentSkipFrame}(matchIndex).PixelIdxList;
                end
                
                %% decrement frame counter
                currentFrame = currentFrame - currentSkipFrame;
            end
            
            %% increase tracking id
            currentTrackingId = currentTrackingId + 1;
        end
        
        %% print status message
        fprintf('Finished tracking frame %i / %i\n', numFrames-i+1, numFrames);
    end
    
    clear tempResultImages;
    
    currentTrackingId = 0;
    for i=1:numFrames
        tempResultImages{i} = resultImages{i};
    
        maxTrackingLabel = max(resultImages{i}(:));
        if (maxTrackingLabel > currentTrackingId)
            currentTrackingId = maxTrackingLabel;
        end
    end
    
    parameters.clusterRadiusIndex = 9;            %% index to the cluster radius feature
    parameters.trackingIdIndex = 10;              %% index to the tracking id
    parameters.predecessorIdIndex = 11;           %% index to the predecessor
    parameters.posIndices = 3:5;                  %% indices to the positions
    parameters.prevPosIndices = 6:8;              %% indices to the previous positions
    
    %% initialize d_orgs
    numFeatures = 11;
    d_orgs = zeros(0, numFrames, numFeatures);
    var_bez = char('id', 'scale', 'xpos', 'ypos', 'zpos', 'prevXPos', 'prevYPos', 'prevZPos', 'clusterCutoff', 'trackletId', 'predecessorId');
    
    nextTrackingId = currentTrackingId + 1;
    
    %% assign new label to mother cells in a backwards fashion
    for i=numFrames:-1:2
    
        currentRegionProps = regionprops(tempResultImages{i}, 'Area', 'Centroid', 'PixelIdxList');
        previousRegionProps = regionprops(tempResultImages{i-1}, 'Area', 'Centroid', 'PixelIdxList');
    
        for j=1:length(currentRegionProps)
    
            if (currentRegionProps(j).Area <= 0)
                continue;
            end
    
            maxLabel = max(tempResultImages{i-1}(currentRegionProps(j).PixelIdxList));
            labelCounts = zeros(maxLabel,1);
            zeroCounts = sum(tempResultImages{i-1}(currentRegionProps(j).PixelIdxList) == 0);
            for k=1:maxLabel
                labelCounts(k) = sum(tempResultImages{i-1}(currentRegionProps(j).PixelIdxList) == k);
            end
    
            [maxIntersection, maxIntersectionLabel] = max(labelCounts);
    
            if (maxLabel == 0 || maxIntersectionLabel ~= j || maxIntersection == 0)
                
                if (maxLabel == 0)
                    disp(['Potential disappearance detected from frame ' num2str(i-1) ' to ' num2str(i) ' for label ' num2str(j)]);
                else
                    disp(['Potential division detected from frame ' num2str(i-1) ' to ' num2str(i) ' for label ' num2str(maxIntersectionLabel)]);
    
                    for k=(i-1):-1:1
                        tempResultImages{k}(tempResultImages{k}==maxIntersectionLabel) = nextTrackingId;
                    end
    
                    d_orgs(j,i,parameters.predecessorIdIndex) = nextTrackingId;
                    d_orgs(maxIntersectionLabel,i,parameters.predecessorIdIndex) = nextTrackingId;
    
                    nextTrackingId = nextTrackingId + 1;
                end
            end
    
            test = 1;
    
        end
    end
    
    for i=1:numFrames
        currentRegionProps = regionprops(tempResultImages{i}, 'Area', 'Centroid');
    
        for j=1:size(currentRegionProps)
            if (currentRegionProps(j).Area <= 0)
                continue;
            end
    
            d_orgs(j, i, parameters.posIndices) = [currentRegionProps(j).Centroid, 0];
            d_orgs(j, i, parameters.trackingIdIndex) = j;
    
            if (i == 1 || (i > 1 && d_orgs(j, i-1, parameters.trackingIdIndex) > 0))
                d_orgs(j, i, parameters.predecessorIdIndex) = j;
            end
        end
    end
%     
%     %% save result images
%     parfor i=1:numFrames
%         saveastiff(uint16(resultImages{i}), [outputFolderTracked strrep(inputFiles(i).name, '.tif', '_Tracked.tif')], options);
%         saveastiff(uint16(tempResultImages{i}), [outputFolderTrackedSplit strrep(inputFiles(i).name, '.tif', '_TrackedSplit.tif')], options);
%     end
end