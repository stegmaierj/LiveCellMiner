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

%% preload image files if not done yet
if (~exist('rawImagePatches', 'var') || isempty(rawImagePatches))
   callback_livecellminer_load_image_files; 
end

%% warn if too many cells were selected
if (length(ind_auswahl) > 50)
    answer = questdlg(sprintf('You selected %i cells for image export. Export may be slow. Continue?', length(ind_auswahl)));

    if (~strcmp(answer, 'Yes'))
        disp('Skipping export ...');
        return;
    end
end

%% find synchronization
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

if (synchronizationIndex == 0)
    disp('Perform synchronization first, as it is needed for the export of an aligned gallery. Synchronization can be done with LiveCellMiner -> Align');
    return;
end

%% get the extents of the image snippets
imageWidth = size(rawImagePatches{1,1}, 1);
imageHeight = size(rawImagePatches{1,1}, 2);

%% get the number of cells
numCells = length(ind_auswahl);
selectedTimePoints = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;
numTimePoints = length(selectedTimePoints);

%% identify the maximum durations for the three different phases of the selected cells
maxPhase1 = 0;
maxPhase2 = 0;
maxPhase3 = 0;

for i=ind_auswahl'
    currentStages = d_orgs(i, selectedTimePoints, synchronizationIndex);

    maxPhase1 = max(maxPhase1, sum(currentStages == 1));
    maxPhase2 = max(maxPhase2, sum(currentStages == 2));
    maxPhase3 = max(maxPhase3, sum(currentStages == 3));
end

%% initialize the result array
resultImage = zeros(imageHeight*numCells, imageWidth*(maxPhase1+maxPhase2+maxPhase3));


for i=1:numCells

    currentIndex = ind_auswahl(i);
    phase1Indices = selectedTimePoints(d_orgs(currentIndex, selectedTimePoints, synchronizationIndex) == 1);
    phase2Indices = selectedTimePoints(d_orgs(currentIndex, selectedTimePoints, synchronizationIndex) == 2);
    phase3Indices = selectedTimePoints(d_orgs(currentIndex, selectedTimePoints, synchronizationIndex) == 3);


    %% add phase 1 frames
    for j=1:length(phase1Indices)

        startPosX = maxPhase1*imageWidth - j*imageWidth + 1;
        startPosY = (i-1)*imageHeight+1;

        rangeX = startPosX:(startPosX+imageWidth-1);
        rangeY = startPosY:(startPosY+imageHeight-1);

        resultImage(rangeY, rangeX) = rawImagePatches{currentIndex, phase1Indices(length(phase1Indices)-j+1)};
    end

    %% add phase 2 frames
    numPhase2Indices = length(phase2Indices);
    phase2IndicesPart1 = phase2Indices(1:round(numPhase2Indices/2));
    phase2IndicesPart2 = phase2Indices(round(numPhase2Indices/2+1):end);

    %% add phase 2 frames, part 1
    for j=1:length(phase2IndicesPart1)

        startPosX = maxPhase1*imageWidth + (j-1)*imageWidth + 1;
        startPosY = (i-1)*imageHeight+1;

        rangeX = startPosX:(startPosX+imageWidth-1);
        rangeY = startPosY:(startPosY+imageHeight-1);

        resultImage(rangeY, rangeX) = rawImagePatches{currentIndex, phase2IndicesPart1(j)};
    end
    
    %% add phase 1 frames
    for j=1:length(phase2IndicesPart2)

        startPosX = (maxPhase1+maxPhase2)*imageWidth - j*imageWidth + 1;
        startPosY = (i-1)*imageHeight+1;

        rangeX = startPosX:(startPosX+imageWidth-1);
        rangeY = startPosY:(startPosY+imageHeight-1);

        resultImage(rangeY, rangeX) = rawImagePatches{currentIndex, phase2IndicesPart2(length(phase2IndicesPart2)-j+1)};
    end

    %% add phase 3 frames
    for j=1:length(phase3Indices)

        startPosX = (maxPhase1+maxPhase2)*imageWidth + (j-1)*imageWidth + 1;
        startPosY = (i-1)*imageHeight+1;

        rangeX = startPosX:(startPosX+imageWidth-1);
        rangeY = startPosY:(startPosY+imageHeight-1);

        resultImage(rangeY, rangeX) = rawImagePatches{currentIndex, phase3Indices(j)};
    end

end
% 
% figure(2)
% imagesc(resultImage);
% axis equal;

[file,path] = uiputfile('*.tif', 'Please select output path for the created gallery.');

if (max(resultImage(:)) > 255)
    resultImage = uint16(resultImage);
else
    resultImage = uint8(resultImage);
end

clear options;
options.overwrite = true;
options.compress = 'lzw';

saveastiff(uint16(resultImage), [path file], options);

