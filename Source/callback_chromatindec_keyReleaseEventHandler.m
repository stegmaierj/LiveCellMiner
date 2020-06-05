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

%% the key event handler
function callback_chromatindec_keyReleaseEventHandler(~,evt)
    global settings;
    global d_orgs;
    global d_org;

    settings.xLim = get(gca, 'XLim');
    settings.yLim = get(gca, 'YLim');
    settings.mainFigure;
    %% switch between the images of the loaded series
    if (strcmp(evt.Key, 'rightarrow'))

        settings.currentIdRange = settings.currentIdRange + settings.numVisualizedCells;
                
        if (max(settings.currentIdRange) > length(settings.selectedCells))
            settings.currentIdRange = (length(settings.selectedCells) - settings.numVisualizedCells+1):length(settings.selectedCells);
            disp('Reached end of the selected cells. Select either more cells to proceed or stop annotating here...');
        end
        
        settings.currentCells = settings.selectedCells(settings.currentIdRange);
        settings.dirtyFlag = true;
        callback_chromatindec_update_visualization;

    elseif (strcmp(evt.Key, 'leftarrow'))
        
        settings.currentIdRange = settings.currentIdRange - settings.numVisualizedCells;
        if (min(settings.currentIdRange) < 1)
            settings.currentIdRange = 1:min(length(settings.selectedCells), settings.numVisualizedCells);
            disp('Reached beginning of the selected cells. Select either more cells to proceed or stop annotating here...');
        end
        
        settings.currentCells = settings.selectedCells(settings.currentIdRange);
        settings.dirtyFlag = true;
        callback_chromatindec_update_visualization;

    %% display raw image
    elseif(strcmp(evt.Character, '1'))
        settings.visualizationMode = 1;
        settings.dirtyFlag = true;
        callback_chromatindec_update_visualization;

    %% display mask image
    elseif(strcmp(evt.Character, '2'))
        settings.visualizationMode = 2;
        settings.dirtyFlag = true;
        callback_chromatindec_update_visualization;    

    %% display raw+mask oevrlay image
    elseif(strcmp(evt.Character, '3'))
        settings.visualizationMode = 3;
        settings.dirtyFlag = true;
        callback_chromatindec_update_visualization;
        
    %% display help dialog box
    elseif(strcmp(evt.Character, 'h'))
        showHelp;
    
	%% export the csv file and save the current workspace    
    elseif(strcmp(evt.Character, 's'))
        exportProject;
		
    %% toggle the color map
    elseif (strcmp(evt.Character, 'c'))
        settings.colormapIndex = mod(settings.colormapIndex+1, 3)+1;
        callback_chromatindec_update_visualization;

    %% toggle add/delete/deselect mode
    elseif (strcmp(evt.Character, 'a'))
        settings.axesEqual = ~settings.axesEqual;
        callback_chromatindec_update_visualization;
    
	%% set current cells as manually checked
	elseif (strcmp(evt.Character, 'g'))
        d_org(settings.currentCells, settings.manuallyConfirmedFeature) = 1;
        disp('Labeled current set of cells as suitable for manual training!');
    end
end