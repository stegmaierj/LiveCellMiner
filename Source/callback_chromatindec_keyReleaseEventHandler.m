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
    global parameters;
    global d_orgs;
    global d_org;

    parameters.xLim = get(gca, 'XLim');
    parameters.yLim = get(gca, 'YLim');
    parameters.mainFigure;
    %% switch between the images of the loaded series
    if (strcmp(evt.Key, 'rightarrow'))

       callback_chromatindec_show_next_cells;

    elseif (strcmp(evt.Key, 'leftarrow'))
        
        parameters.currentIdRange = parameters.currentIdRange - parameters.numVisualizedCells;
        if (min(parameters.currentIdRange) < 1)
            parameters.currentIdRange = 1:min(length(parameters.selectedCells), parameters.numVisualizedCells);
            disp('Reached beginning of the selected cells. Select either more cells to proceed or stop annotating here...');
        end
        
        parameters.currentCells = parameters.selectedCells(parameters.currentIdRange);
        parameters.dirtyFlag = true;
        callback_chromatindec_update_visualization;

    %% display raw image
    elseif(strcmp(evt.Character, '1'))
        parameters.visualizationMode = 1;
        parameters.dirtyFlag = true;
        callback_chromatindec_update_visualization;

    %% display mask image
    elseif(strcmp(evt.Character, '2'))
        parameters.visualizationMode = 2;
        parameters.dirtyFlag = true;
        callback_chromatindec_update_visualization;    

    %% display raw+mask oevrlay image
    elseif(strcmp(evt.Character, '3'))
        parameters.visualizationMode = 3;
        parameters.dirtyFlag = true;
        callback_chromatindec_update_visualization;
        
    %% display help dialog box
    elseif(strcmp(evt.Character, 'h'))
        showHelp;
    
	%% export the csv file and save the current workspace    
    elseif(strcmp(evt.Character, 's'))
        exportProject;
		
    %% toggle the color map
    elseif (strcmp(evt.Character, 'c'))
        parameters.colormapIndex = mod(parameters.colormapIndex+1, 3)+1;
        callback_chromatindec_update_visualization;

    %% toggle add/delete/deselect mode
    elseif (strcmp(evt.Character, 'a'))
        parameters.axesEqual = ~parameters.axesEqual;
        callback_chromatindec_update_visualization;
    
	%% set current cells as manually checked
	elseif (strcmp(evt.Key, 'uparrow'))
        d_org(parameters.currentCells, parameters.manuallyConfirmedFeature) = 1;
        disp('Labeled current set of cells as suitable for manual training and going to next frame!');
        callback_chromatindec_show_next_cells;
        
	%% set current cells as manually checked
	elseif (strcmp(evt.Character, 'g'))
        d_org(parameters.currentCells, parameters.manuallyConfirmedFeature) = 1;
        disp('Labeled current set of cells as suitable for manual training!');
        
    elseif (strcmp(evt.Key, 'downarrow'))
        d_org(parameters.currentCells, parameters.manuallyConfirmedFeature) = 0;
        disp('Labeled current set of cells as unsuitable for manual training!');
    end
end