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

%% combine tracks of mothers and corresponding daughters, which have different ids after the division
function [finalFeatureMatrix, originalIds, finalRawImagePatches, finalMaskImagePatches] = CombineMotherDaughterTracks(featureMatrix, motherList, daughterList, motherDaughterList, deletionIndices, ...
                                                                         rawImagePatches, maskImagePatches, settings)
    %% create output directories if they don't exist yet
    outputRawFolder = settings.outputRawFolder;
    outputMaskFolder = settings.outputMaskFolder;
    timeWindowMother = settings.timeWindowMother;
    timeWindowDaughter = settings.timeWindowDaughter;
    patchWidth = settings.patchWidth;
                                                                     
    %% assemble feature matrix with correct mother daughter relationship
    numFeatures = size(featureMatrix, 3);
    originalIds = [];
    currentIndex = 1;
    finalFeatureMatrix = zeros(size(motherDaughterList,1)*2, timeWindowMother+timeWindowDaughter, numFeatures);
    finalRawImagePatches = cell(size(motherDaughterList,1)*2, timeWindowMother+timeWindowDaughter);
    finalMaskImagePatches = cell(size(motherDaughterList,1)*2, timeWindowMother+timeWindowDaughter);
    for j=1:size(motherList,1)
               
       %% get the daughter indices
       daughter1Index = find(daughterList(:,1) == motherDaughterList(j,2));
       daughter2Index = find(daughterList(:,1) == motherDaughterList(j,3));
       
       %% get the frame ranges for the mother and the daughters
       rangeMother = (motherList(j,2):motherList(j,3)) + 1;
       rangeDaughter1 = (daughterList(daughter1Index, 2):daughterList(daughter1Index, 3)) + 1;
       rangeDaughter2 = (daughterList(daughter2Index, 2):daughterList(daughter2Index, 3)) + 1;
       
       %% get the mother and daughter indices
       motherIndex = motherDaughterList(j,1);
       daughter1Index = motherDaughterList(j,2);
       daughter2Index = motherDaughterList(j,3);
              
       %% ensure that all indices are valid
       if (isempty(motherIndex) || isempty(daughter1Index) || isempty(daughter2Index) || ...
           ismember(motherIndex, deletionIndices) || ismember(daughter1Index, deletionIndices) || ismember(daughter2Index, deletionIndices))
          continue; 
       end
       
       %% assemble two rows for the feature matrix
       finalFeatureMatrix(currentIndex, 1:timeWindowMother, :) = squeeze(featureMatrix(motherIndex, rangeMother, :));
       finalFeatureMatrix(currentIndex+1, 1:timeWindowMother, :) = squeeze(featureMatrix(motherIndex, rangeMother, :));
       finalFeatureMatrix(currentIndex, (timeWindowMother+1):end, :) = squeeze(featureMatrix(daughter1Index, rangeDaughter1, :));
       finalFeatureMatrix(currentIndex+1, (timeWindowMother+1):end, :) = squeeze(featureMatrix(daughter2Index, rangeDaughter2, :));
       
       %% fill the output images
       outputImageRaw1 = zeros(patchWidth, patchWidth, timeWindowMother+timeWindowDaughter);
       outputImageRaw2 = zeros(patchWidth, patchWidth, timeWindowMother+timeWindowDaughter);
       outputImageMask1 = zeros(patchWidth, patchWidth, timeWindowMother+timeWindowDaughter);
       outputImageMask2 = zeros(patchWidth, patchWidth, timeWindowMother+timeWindowDaughter);
       outputImageEdge1 = zeros(patchWidth, patchWidth, 3, timeWindowMother+timeWindowDaughter);
       outputImageEdge2 = zeros(patchWidth, patchWidth, 3, timeWindowMother+timeWindowDaughter);
       
       for i=1:timeWindowMother
            outputImageRaw1(:, :, i) = rawImagePatches{motherIndex, rangeMother(i)};
            outputImageRaw2(:, :, i) = rawImagePatches{motherIndex, rangeMother(i)};
            outputImageMask1(:, :, i) = maskImagePatches{motherIndex, rangeMother(i)};
            outputImageMask2(:, :, i) = maskImagePatches{motherIndex, rangeMother(i)};
            
            finalRawImagePatches{currentIndex, i} = rawImagePatches{motherIndex, rangeMother(i)};
            finalRawImagePatches{currentIndex+1, i} = rawImagePatches{motherIndex, rangeMother(i)};
            finalMaskImagePatches{currentIndex, i} = maskImagePatches{motherIndex, rangeMother(i)};
            finalMaskImagePatches{currentIndex+1, i} = maskImagePatches{motherIndex, rangeMother(i)};
       end
       
       for i=1:timeWindowDaughter
            outputImageRaw1(:, :, (timeWindowMother+i)) = rawImagePatches{daughter1Index, rangeDaughter1(i)};
            outputImageRaw2(:, :, (timeWindowMother+i)) = rawImagePatches{daughter2Index, rangeDaughter2(i)};
            outputImageMask1(:, :, (timeWindowMother+i)) = maskImagePatches{daughter1Index, rangeDaughter1(i)};
            outputImageMask2(:, :, (timeWindowMother+i)) = maskImagePatches{daughter2Index, rangeDaughter2(i)};
            
            finalRawImagePatches{currentIndex, (timeWindowMother+i)} = rawImagePatches{daughter1Index, rangeDaughter1(i)};
            finalRawImagePatches{currentIndex+1, (timeWindowMother+i)} = rawImagePatches{daughter2Index, rangeDaughter2(i)};
            finalMaskImagePatches{currentIndex, (timeWindowMother+i)} = maskImagePatches{daughter1Index, rangeDaughter1(i)};
            finalMaskImagePatches{currentIndex+1, (timeWindowMother+i)} = maskImagePatches{daughter2Index, rangeDaughter2(i)};
       end
       
	   %% write image snippets to disk if enabled
       if (settings.writeImagePatches == true)
           clear options;
           options.overwrite = true;
           options.compress = 'lzw';
           filename1 = strcat(outputRawFolder, '/', sprintf('cell_id_%04d.tif', currentIndex));
           filename2 = strcat(outputRawFolder, '/', sprintf('cell_id_%04d.tif', currentIndex+1));
           saveastiff(uint16(outputImageRaw1), filename1, options);
           saveastiff(uint16(outputImageRaw2), filename2, options);

           filename1 = strcat(outputMaskFolder, '/', sprintf('mask_cell_id_%04d.tif', currentIndex));
           filename2 = strcat(outputMaskFolder, '/', sprintf('mask_cell_id_%04d.tif', currentIndex+1));
           saveastiff(uint16(outputImageMask1), filename1, options);
           saveastiff(uint16(outputImageMask2), filename2, options);
       end
       
       %% save the original Ids to retrieve the correct snippets later on
       originalIds = [originalIds; motherIndex, daughter1Index; motherIndex, daughter2Index];
       
       %% increment counter by 2 as two lines are added (mother+daughter1 and mother+daughter2)
       currentIndex = currentIndex + 2;
    end
end