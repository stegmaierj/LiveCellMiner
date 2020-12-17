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

function callback_livecellminer_clickEventHandler(~, ~)
    global parameters;
    global d_orgs;

    %% get the modifier keys
    modifiers = get(gcf,'currentModifier');        %(Use an actual figure number if known)
    shiftPressed = ismember('shift',modifiers);
    ctrlPressed = ismember('control',modifiers);
    altPressed = ismember('alt',modifiers);

    %% identify the click position and the button
    buttonPressed = get(gcf, 'SelectionType');
    clickPosition = get(gca, 'currentpoint');
    clickPosition = round([clickPosition(1,1), clickPosition(1,2)]);
    
    if (clickPosition(1) <= 0 || clickPosition(1) > size(parameters.labelImage,2) || ...
        clickPosition(2) <= 0 || clickPosition(2) > size(parameters.labelImage,1))
        return;
    end

	%% get the id of the current cell based on the click position
    cellId = parameters.labelImage(clickPosition(2), clickPosition(1), 1);
    frameNumber = parameters.labelImage(clickPosition(2), clickPosition(1), 2);
    
	%% identify the cell pair (one uneven and one even number)
    evenCellId = mod(cellId,2) == 0;
    if (evenCellId)
        cellPair = [cellId-1,cellId];
    else
        cellPair = [cellId,cellId+1];
    end
    
	%% disable cell if right click is obtained and set the stage otherwise
    if (strcmp(buttonPressed, 'alt'))
        d_orgs(cellPair, :, parameters.manualStageIndex) = -1;
    elseif (strcmp(buttonPressed, 'normal'))
        
        maxIndex = max(squeeze(d_orgs(cellId, :, parameters.manualStageIndex)));
        
        if (maxIndex > 2 || maxIndex <= 0)
           d_orgs(cellPair, 1:frameNumber, parameters.manualStageIndex) = 1;
           d_orgs(cellPair, (frameNumber+1):end, parameters.manualStageIndex) = 0;
        elseif (maxIndex == 1)
            alreadyLabeledIndices = find(squeeze(d_orgs(cellId, :, parameters.manualStageIndex) == 1));
            nextIndex = max(alreadyLabeledIndices)+1;
            d_orgs(cellPair, nextIndex:frameNumber, parameters.manualStageIndex) = 2;
            d_orgs(cellPair, (frameNumber+1):end, parameters.manualStageIndex) = 3;
        end
    end
    
    callback_livecellminer_update_visualization;