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

%% initialize the global settings variable
clear parameters;
global parameters;
global d_orgs;
global d_org;
global rawImagePatches;
global maskImagePatches;
global parameter;

%% find the synchronization index or create it if not present yet
synchronizationIndex = callback_chromodec_find_single_feature(var_bez, 'manualSynchronization');
if (synchronizationIndex == 0)
    d_orgs(:,:,end+1) = 0;
    var_bez = char(var_bez(1:size(d_orgs,3)-1,:), 'manualSynchronization');
    aktparawin;
end

%% find the manually confirmed index or create it if not present yet
parameters.manuallyConfirmedFeature = callback_chromodec_find_single_feature(dorgbez, 'manuallyConfirmed');
if (parameters.manuallyConfirmedFeature == 0)
    
    if (isempty(d_org))
        d_org = zeros(size(d_orgs,1), 1);
    else
        d_org(:,end+1) = 0;
    end
    parameters.manuallyConfirmedFeature = size(d_org,2);
    if (~isempty(dorgbez))
        dorgbez = char(dorgbez, 'manuallyConfirmed');
    else
        dorgbez = char('manuallyConfirmed');
    end
    aktparawin;
end

%% find the manual synchronization index
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
synchronizationIndex = parameter.gui.merkmale_und_klassen.ind_zr;
set(gaitfindobj('CE_Auswahl_ZR'),'value', oldSelection);
aktparawin;

%% initialize the settings
parameters.numVisualizedCells = 10;
parameters.timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;
parameters.patchWidth = parameter.projekt.patchWidth;
parameters.selectedCells = ind_auswahl;
parameters.currentIdRange = 1:min(length(parameters.selectedCells), parameters.numVisualizedCells);
parameters.currentCells = parameters.selectedCells(parameters.currentIdRange);
parameters.visualizationMode = 1;
parameters.colormapIndex = 1;
parameters.markerSize = 10;
parameters.gamma = 1;
parameters.axesEqual = false;
parameters.fontSize = 16;
parameters.manualStageIndex = synchronizationIndex;
parameters.colormapStrings = {'gray';'jet';'parula'};
parameters.showInfo = false;
parameters.dirtyFlag = true;
parameters.numStages = 2;

%% open the main figure
parameters.mainFigure = figure;
set(parameters.mainFigure, 'units', 'normalized', 'color', 'black', 'OuterPosition', [0 0 1 1]);

%% mouse, keyboard events and window title
set(parameters.mainFigure, 'WindowButtonDownFcn', @callback_chromodec_clickEventHandler);
set(parameters.mainFigure, 'WindowScrollWheelFcn', @callback_chromodec_scrollEventHandler);
set(parameters.mainFigure, 'KeyReleaseFcn', @callback_chromodec_keyReleaseEventHandler);

%% updateVisualization
callback_chromodec_update_visualization;