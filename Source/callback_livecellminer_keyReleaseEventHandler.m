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

%% the key event handler
function callback_livecellminer_keyReleaseEventHandler(~,evt)
    global parameters; %#ok<GVMIS> 
    global d_org; %#ok<GVMIS> 

    parameters.xLim = get(gca, 'XLim');
    parameters.yLim = get(gca, 'YLim');
    parameters.mainFigure;
    %% switch between the images of the loaded series
    if (strcmp(evt.Key, 'rightarrow'))

       callback_livecellminer_show_next_cells;

    elseif (strcmp(evt.Key, 'leftarrow'))
        
        parameters.currentIdRange = parameters.currentIdRange - parameters.numVisualizedCells;
        if (min(parameters.currentIdRange) < 1)
            parameters.currentIdRange = 1:min(length(parameters.selectedCells), parameters.numVisualizedCells);
            disp('Reached beginning of the selected cells. Select either more cells to proceed or stop annotating here...');
        end
        
        parameters.currentCells = parameters.selectedCells(parameters.currentIdRange);
        parameters.dirtyFlag = true;
        callback_livecellminer_update_visualization;

    %% display raw image
    elseif(strcmp(evt.Character, '1'))
        parameters.visualizationMode = 1;
        parameters.dirtyFlag = true;
        callback_livecellminer_update_visualization;

    %% display mask image
    elseif(strcmp(evt.Character, '2'))
        parameters.visualizationMode = 2;
        parameters.dirtyFlag = true;
        callback_livecellminer_update_visualization;    

    %% display raw+mask oevrlay image
    elseif(strcmp(evt.Character, '3'))
        parameters.visualizationMode = 3;
        parameters.dirtyFlag = true;
        callback_livecellminer_update_visualization;
        
    %% display secondary channel image
    elseif(strcmp(evt.Character, '4'))
        parameters.visualizationMode = 4;
        parameters.dirtyFlag = true;
        callback_livecellminer_update_visualization;
        
    %% display first and secondary channel image
    elseif(strcmp(evt.Character, '5'))
        parameters.visualizationMode = 5;
        parameters.dirtyFlag = true;
        callback_livecellminer_update_visualization;
        
    %% display help dialog box
    elseif(strcmp(evt.Character, 'h'))
        callback_livecellminer_showHelp;
    
	%% export the csv file and save the current workspace    
    elseif(strcmp(evt.Character, 's'))
        exportProject;
		
    %% toggle the color map
    elseif (strcmp(evt.Character, 'c'))
        parameters.colormapIndex = mod(parameters.colormapIndex+1, 3)+1;
        callback_livecellminer_update_visualization;

    %% toggle add/delete/deselect mode
    elseif (strcmp(evt.Character, 'a'))
        parameters.axesEqual = ~parameters.axesEqual;
        callback_livecellminer_update_visualization;

    elseif (strcmp(evt.Character, 'm'))
    
        parameters.dirtyFlag = true;
        parameters.secondChannelFeatures.showMask = ~parameters.secondChannelFeatures.showMask;
        callback_livecellminer_update_visualization;

    elseif (strcmp(evt.Character, 'p'))
    
        parameters.dirtyFlag = true;

        %% segmentation mode to be used (extend, shring, toroidal)
        dlgtitle = '2nd Channel Feature Extraction:';
        dims = [1 100];
        additionalUserSettings = inputdlg({'Segmentation Mode (0: Extend, 1: Shrink, 2: Toroidal, 3: Padded Toroidal)', 'Structuring Element (e.g., disk, square, diamond)', 'Structuring Element Radius', 'Padding of Toroidal Region'}, ...
                                           dlgtitle, dims, {num2str(parameters.secondChannelFeatures.extractionMode), parameters.secondChannelFeatures.strelType, num2str(parameters.secondChannelFeatures.strelRadius), num2str(parameters.secondChannelFeatures.toroidalPadding)});
        if (isempty(additionalUserSettings))
            disp('No feature extraction settings provided, stopping processing ...');
            return;
        else
            %% convert parameters to the required format
            parameters.secondChannelFeatures.extractionMode = str2double(additionalUserSettings{1});
            parameters.secondChannelFeatures.strelType = additionalUserSettings{2};
            parameters.secondChannelFeatures.strelRadius = str2double(additionalUserSettings{3});
            parameters.secondChannelFeatures.toroidalPadding = str2double(additionalUserSettings{4});
            parameters.secondChannelFeatures.structuringElement = strel(parameters.secondChannelFeatures.strelType, parameters.secondChannelFeatures.strelRadius);
        end

        callback_livecellminer_update_visualization;

    %% toggle info text
    elseif (strcmp(evt.Character, 'i'))
        parameters.showInfo = ~parameters.showInfo;
        callback_livecellminer_update_visualization;
    
	%% set current cells as manually checked
	elseif (strcmp(evt.Key, 'uparrow'))
        d_org(parameters.currentCells, parameters.manuallyConfirmedFeature) = 1;
        disp('Labeled current set of cells as suitable for manual training and going to next frame!');
        callback_livecellminer_show_next_cells;
        
	%% set current cells as manually checked
	elseif (strcmp(evt.Character, 'g'))
        d_org(parameters.currentCells, parameters.manuallyConfirmedFeature) = 1;
        disp('Labeled current set of cells as suitable for manual training!');
        
    elseif (strcmp(evt.Key, 'downarrow'))
        d_org(parameters.currentCells, parameters.manuallyConfirmedFeature) = 0;
        callback_livecellminer_update_visualization;
        disp('Labeled current set of cells as unsuitable for manual training!');
    end
end