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

global parameter;
global parameters;
global d_org;
global d_orgs;
global zgf_y_bez;
global bez_code;
global code_alle;
global rawImagePatches;
global rawImagePatches2;
global maskImagePatches;

%% get the current time range
parameters.timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;

%% get the output variables
experimentIdIndex = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
positionIdIndex = callback_livecellminer_find_output_variable(bez_code, 'Position');
oligoIdIndex = callback_livecellminer_find_output_variable(bez_code, 'OligoID');

%% only update if anything changed
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

        %% specify range of the current row
        rangeY = ((currentCell-1)*imageSize(2)+1):currentCell*imageSize(2);

        %% fill the individual time points
        currentTimePoint = 1;
        for j=timeRange

            %% specify range for the current column
            rangeX = ((currentTimePoint-1)*imageSize(1)+1):currentTimePoint*imageSize(1);

            %% fill the montage image
            if (exist('rawImagePatches', 'var') && exist('maskImagePatches', 'var') && ~isempty(rawImagePatches) && ~isempty(maskImagePatches)) 

                %% continue if images are empty
                if (isempty(rawImagePatches{i, j}) || isempty(maskImagePatches{i, j}))
                    continue;
                end
                
                %% normalize the intensities
                if (parameters.visualizationMode ~= 2)
                    minValue1 = min(double(rawImagePatches{i, j}(:)));
                    maxValue1 = max(double(rawImagePatches{i, j}(:)));
                    normalizedPatch1 = (double(rawImagePatches{i, j}) - minValue1) / (maxValue1 - minValue1);
                end
                
                if (~isempty(rawImagePatches2{i,j}) && parameters.visualizationMode >= 4)
                    minValue2 = min(double(rawImagePatches2{i, j}(:)));
                    maxValue2 = max(double(rawImagePatches2{i, j}(:)));
                    normalizedPatch2 = (double(rawImagePatches2{i, j}) - minValue2) / (maxValue2 - minValue2);
                end
                
                %% set visualized image patches depending on current visualization mode
                if (parameters.visualizationMode == 1)
                    parameters.montageImage(rangeY, rangeX) = normalizedPatch1;
                    
                %% mask image mode
                elseif (parameters.visualizationMode == 2)
                    parameters.montageImage(rangeY, rangeX) = maskImagePatches{i, j};
                    
                %% masked raw image mode
                elseif (parameters.visualizationMode == 3)
                    parameters.montageImage(rangeY, rangeX) = normalizedPatch1 .* double(maskImagePatches{i, j});
                   
                %% secondary channel image
                elseif (parameters.visualizationMode == 4)
                    if (~isempty(rawImagePatches2{i,j}))
                        parameters.montageImage(rangeY, rangeX) = normalizedPatch2;
                    else
                        disp('Error: no secondary channel information available to display!');
                    end
                    
                %% superimposed first and second channel
                else
                    if (~isempty(rawImagePatches2{i,j}))                       
                        parameters.montageImage(rangeY, rangeX, 1) = normalizedPatch1;
                        parameters.montageImage(rangeY, rangeX, 2) = normalizedPatch2;
                        parameters.montageImage(rangeY, rangeX, 3) = 0;
                    else
                        disp('Error: no secondary channel information available to display!');
                    end
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
set(gca,'Units','normalized')
set(gca,'Position',[0 0 1 1])
colormap gray;
axis([0, size(parameters.montageImage, 2), 0, size(parameters.montageImage, 1)]);
axis equal;
axis tight;
axis off;

%% set the figure title
currentCellIndex = find(parameters.currentCells(1) == parameters.selectedCells);
totalNumberOfCells = length(parameters.selectedCells);
set(parameters.mainFigure, 'Name', sprintf('Finished %i / %i cells', currentCellIndex, totalNumberOfCells));

%% draw the currently annotated states
currentCell = 1;
for i=generate_rowvector(parameters.currentCells)
    
    %% determine state transitions
    manualLabelStatus = d_org(i, parameters.manuallyConfirmedFeature);
    currentStates = squeeze(d_orgs(i, parameters.timeRange, parameters.manualStageIndex));
    invalidIndices = find(currentStates < 0);
    unlabeledIndices = find(currentStates == 0);
    beforeIP = find(currentStates == 1);
    beforeMA = find(currentStates == 2);
    afterMA = find(currentStates == 3);
    
    %% plot colored rectangles
    if (~isempty(invalidIndices)); rectangle('Position', [(invalidIndices(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(invalidIndices), (parameter.projekt.patchWidth-1)], 'EdgeColor','r'); end
    if (~isempty(unlabeledIndices)); rectangle('Position', [(unlabeledIndices(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(unlabeledIndices), (parameter.projekt.patchWidth-1)], 'EdgeColor','b'); end
    if (~isempty(beforeIP)); rectangle('Position', [(beforeIP(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(beforeIP), (parameter.projekt.patchWidth-1)], 'EdgeColor','g'); end
    if (~isempty(beforeMA)); rectangle('Position', [(beforeMA(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(beforeMA), (parameter.projekt.patchWidth-1)], 'EdgeColor','m'); end
    if (~isempty(afterMA)); rectangle('Position', [(afterMA(1)-1)*parameter.projekt.patchWidth+1, (currentCell-1)*parameter.projekt.patchWidth+1, parameter.projekt.patchWidth*length(afterMA), (parameter.projekt.patchWidth-1)], 'EdgeColor','c'); end
    
    %% plot if the track was manually aligned
    if (manualLabelStatus > 0)
        rectangle('Position', [0, (currentCell-1)*parameter.projekt.patchWidth+1, 0.25*parameter.projekt.patchWidth, 0.25*parameter.projekt.patchWidth], 'FaceColor','g');
    else
        rectangle('Position', [0, (currentCell-1)*parameter.projekt.patchWidth+1, 0.25*parameter.projekt.patchWidth, 0.25*parameter.projekt.patchWidth], 'FaceColor','r');
    end

    %% plot text label showing the experiment, position and plate
    if (parameters.showInfo)
        positionName = zgf_y_bez(positionIdIndex, code_alle(i, positionIdIndex)).name;
        oligoName = zgf_y_bez(oligoIdIndex, code_alle(i, oligoIdIndex)).name;
        text(0.3*parameter.projekt.patchWidth, (currentCell-1)*parameter.projekt.patchWidth+0.25*parameter.projekt.patchWidth, strrep(['Exp. ' num2str(code_alle(i, experimentIdIndex)) ', ' positionName '(' oligoName ')'], '_', '-'), 'Color','white', 'BackgroundColor', [0,0,0,0.5]);
    end
    
    currentCell = currentCell + 1;
end

%% set dirty flag to false
parameters.dirtyFlag = false;