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
clear settings;
global settings;
global d_orgs;
global d_org;
global rawImagePatches;
global maskImagePatches;
global parameter;

%% find the synchronization index or create it if not present yet
synchronizationIndex = callback_chromatindec_find_single_feature(var_bez, 'manualSynchronization');
if (synchronizationIndex == 0)
    d_orgs(:,:,end+1) = 0;
    var_bez = char(var_bez(1:size(d_orgs,3)-1,:), 'manualSynchronization');
    aktparawin;
end

%% find the manually confirmed index or create it if not present yet
settings.manuallyConfirmedFeature = callback_chromatindec_find_single_feature(dorgbez, 'manuallyConfirmed');
if (settings.manuallyConfirmedFeature == 0)
    
    if (isempty(d_org))
        d_org = zeros(size(d_orgs,1), 1);
    else
        d_org(:,end+1) = 0;
    end
    settings.manuallyConfirmedFeature = size(d_org,2);
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
settings.numVisualizedCells = 10;
settings.timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;
settings.patchWidth = parameter.projekt.patchWidth;
settings.selectedCells = ind_auswahl;
settings.currentIdRange = 1:min(length(settings.selectedCells), settings.numVisualizedCells);
settings.currentCells = settings.selectedCells(settings.currentIdRange);
settings.visualizationMode = 1;
settings.colormapIndex = 1;
settings.markerSize = 10;
settings.gamma = 1;
settings.axesEqual = false;
settings.fontSize = 16;
settings.manualStageIndex = synchronizationIndex;
settings.colormapStrings = {'gray';'jet';'parula'};
settings.showInfo = false;
settings.dirtyFlag = true;
settings.numStages = 2;

%% open the main figure
settings.mainFigure = figure;
set(settings.mainFigure, 'units', 'normalized', 'color', 'black', 'OuterPosition', [0 0 1 1]);

%% mouse, keyboard events and window title
set(settings.mainFigure, 'WindowButtonDownFcn', @callback_chromatindec_clickEventHandler);
set(settings.mainFigure, 'WindowScrollWheelFcn', @callback_chromatindec_scrollEventHandler);
set(settings.mainFigure, 'KeyReleaseFcn', @callback_chromatindec_keyReleaseEventHandler);

%% updateVisualization
callback_chromatindec_update_visualization;
