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

%% construct the output name based on the current project name
outputFileName = [parameter.projekt.pfad filesep parameter.projekt.datei '.h5'];

if (exist(outputFileName, 'file'))
    fprintf('File %s already exists, skipping recreation. To force recreation, manually delete  the file!\n', outputFileName);
    return;
end

%% preload image files if not done yet
if (~exist('rawImagePatches', 'var') || isempty(rawImagePatches))
   callback_livecellminer_load_image_files; 
end

imageSize = size(rawImagePatches{1,1});
featureSize = size(maskedImageCNNFeatures{1,1});
numFrames = size(d_orgs,2);
hasSecondChannel = ~isempty(rawImagePatches2{1,1});

outputTensorRaw = uint16(zeros(imageSize(1), imageSize(2), numFrames));
outputTensorMask = uint8(zeros(imageSize(1), imageSize(2), numFrames));
outputTensorCNN = single(zeros(featureSize(1), numFrames));
if (hasSecondChannel)
    outputTensorRaw2 = uint16(zeros(imageSize(1), imageSize(2), numFrames));
end

for i=1:size(d_orgs,1)
    for j=1:size(d_orgs,2)
        outputTensorRaw(:,:,j) = rawImagePatches{i,j};

        if (~isempty(rawImagePatches2{i,j}))
            outputTensorRaw2(:,:,j) = rawImagePatches2{i,j};
        end
        outputTensorMask(:,:,j) = maskImagePatches{i,j};
        outputTensorCNN(:,j) = maskedImageCNNFeatures{i,j};
    end

    outputStringRaw = callback_livecellminer_create_hdf5_path(i, code_alle, zgf_y_bez, 'raw');
    outputStringRaw2 = callback_livecellminer_create_hdf5_path(i, code_alle, zgf_y_bez, 'raw2');
    outputStringMask = callback_livecellminer_create_hdf5_path(i, code_alle, zgf_y_bez, 'mask');
    outputStringCNNFeatures = callback_livecellminer_create_hdf5_path(i, code_alle, zgf_y_bez, 'cnn');

    h5create(outputFileName, outputStringRaw, size(outputTensorRaw), 'Datatype', 'uint16');
    h5write(outputFileName, outputStringRaw, outputTensorRaw);

    if (hasSecondChannel)
        h5create(outputFileName, outputStringRaw2, size(outputTensorRaw2), 'Datatype', 'uint16');
        h5write(outputFileName, outputStringRaw2, outputTensorRaw2);
    end

    h5create(outputFileName, outputStringMask, size(outputTensorMask), 'Datatype', 'uint8');
    h5write(outputFileName, outputStringMask, outputTensorMask);

    h5create(outputFileName, outputStringCNNFeatures, size(outputTensorCNN), 'Datatype', 'single');
    h5write(outputFileName, outputStringCNNFeatures, outputTensorCNN);

    if (mod(i,100) == 1)
        fprintf('Finished converting %i / %i cells to the HDF5 file ...\n', i, size(d_orgs,1));
    end
end

%% success message
fprintf('Converted image data base saved to %s\n', outputFileName);
