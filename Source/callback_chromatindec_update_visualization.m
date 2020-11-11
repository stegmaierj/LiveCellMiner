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

global parameter;
global parameters;
global d_orgs;
global rawImagePatches;
global maskImagePatches;

parameters.timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;

if (parameters.dirtyFlag == true)
    %% get the number of cells 
    numCells = length(parameters.currentCells);
    timeRange = parameters.timeRange;
    numTimePoints = length(parameters.timeRange);
    imageSize = [parameters.patchWidth, parameters.patchWidth];

    %% initialize the montage image
    parameters.montageImage = zeros(numCells * imageSize(2), numTimePoints*imageSize(1));
    parameters.labelImage = zeros(numCells * imageSize(2), numTimePoints*imageSize(1), 3);

    %% loop through all selected cells and add them to the montage
    currentCell = 1;
    for i=generate_rowvector(parameters.currentCells)

        %% depending on the visualization mode, select either the raw or the mask image or the masked raw image
        if (~exist('rawImagePatches', 'var') || isempty(rawImagePatches))
            if (parameters.visualizationMode == 1)
                currentImage = double(loadtiff(parameter.projekt.imageFiles{i,1}));
            elseif (parameters.visualizationMode == 2)
                currentMask = double(loadtiff(parameter.projekt.imageFiles{i,2}) > 0);
            else
                currentImage = double(loadtiff(parameter.projekt.imageFiles{i,1}));
                currentMask = double(loadtiff(parameter.projekt.imageFiles{i,2}));
                currentImage = currentImage .* currentMask;
            end

            %% adjust intensity of the current patch
            if (parameters.visualizationMode ~= 2)
                currentImage = (currentImage - min(currentImage(:))) / (max(currentImage(:)) - min(currentImage(:)));
            end
        end

        %% specify range of the current row
        rangeY = ((currentCell-1)*imageSize(2)+1):currentCell*imageSize(2);

        %% fill the individual time points
        currentTimePoint = 1;
        for j=timeRange

            rangeX = ((currentTimePoint-1)*imageSize(1)+1):currentTimePoint*imageSize(1);

            if (exist('rawImagePatches', 'var') && exist('maskImagePatches', 'var') && ~isempty(rawImagePatches) && ~isempty(maskImagePatches)) 

                if (isempty(rawImagePatches{i, j}) || isempty(rawImagePatches{i, j}))
                    continue;
                end

                if (parameters.visualizationMode == 1)
                    parameters.montageImage(rangeY, rangeX) = double(rawImagePatches{i, j}) / max(max(double(rawImagePatches{i, j})));
                elseif (parameters.visualizationMode == 2)
                    parameters.montageImage(rangeY, rangeX) = maskImagePatches{i, j};
                else
                   parameters.montageImage(rangeY, rangeX) = imadjust(rawImagePatches{i, j}) .* maskImagePatches{i, j}; 
                end
            else
                if (parameters.visualizationMode == 1)
                    parameters.montageImage(rangeY, rangeX) = double(currentImage(:,:,j)) / max(max(double(currentImage(:,:,j))));
                elseif (parameters.visualizationMode == 2)
                    parameters.montageImage(rangeY, rangeX) = currentMask(:,:,j);
                else
                   parameters.montageImage(rangeY, rangeX) = currentMask(:,:,j) .* imadjust(currentImage(:,:,j)); 
                end
            end

            %% initialize the labelImage used for state annotation
            parameters.labelImage(rangeY, rangeX, 1) = i;
            parameters.labelImage(rangeY, rangeX, 2) = j;

            %% increment the time point counter
            currentTimePoint = currentTimePoint + 1;
        end

        %% increment the cell counter
        currentCell = currentCell + 1;
    end

    %% add separation bars for better visibility of the patches
    maxIntensity = max(parameters.montageImage(:));
    for i=1:numCells
        parameters.montageImage((i*imageSize(2)-1):(i*imageSize(2)+1), :) = 0.1*maxIntensity;
    end
    for i=1:numTimePoints
       parameters.montageImage(:, (i*imageSize(1)-1):(i*imageSize(1)+1)) = 0.1*maxIntensity;
    end
end

%% plot the figure
figure(parameters.mainFigure); clf;
imagesc(parameters.montageImage);
%set(parameters.mainFigure, 'OuterPosition', [1913          33        1936        1056])
set(gca,'Units','normalized')
set(gca,'Position',[0 0 1 1])
colormap gray;
axis([0, size(parameters.montageImage, 2), 0, size(parameters.montageImage, 1)]);
axis equal;
axis tight;
axis off;

set(parameters.mainFigure, 'Name', sprintf('Finished %i / %i cells', min(parameters.currentCells), size(d_orgs,1)));

%% draw the currently annotated states
currentCell = 1;
for i=generate_rowvector(parameters.currentCells)
    
    currentStates = squeeze(d_orgs(i, parameters.timeRange, parameters.manualStageIndex));
    
    invalidIndices = find(currentStates < 0);
    unlabeledIndices = find(currentStates == 0);
    beforeIP = find(currentStates == 1);
    beforeMA = find(currentStates == 2);
    afterMA = find(currentStates == 3);
    
    if (~isempty(invalidIndices)); rectangle('Position', [(invalidIndices(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(invalidIndices), (parameter.projekt.patchWidth-1)], 'EdgeColor','r'); end
    if (~isempty(unlabeledIndices)); rectangle('Position', [(unlabeledIndices(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(unlabeledIndices), (parameter.projekt.patchWidth-1)], 'EdgeColor','b'); end
    if (~isempty(beforeIP)); rectangle('Position', [(beforeIP(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(beforeIP), (parameter.projekt.patchWidth-1)], 'EdgeColor','g'); end
    if (~isempty(beforeMA)); rectangle('Position', [(beforeMA(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(beforeMA), (parameter.projekt.patchWidth-1)], 'EdgeColor','m'); end
    if (~isempty(afterMA)); rectangle('Position', [(afterMA(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(afterMA), (parameter.projekt.patchWidth-1)], 'EdgeColor','c'); end
    
    currentCell = currentCell + 1;
end
parameters.dirtyFlag = false;