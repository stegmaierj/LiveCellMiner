%%
% LiveCellMiner.
% Copyright (C) 2021 D. Moreno-Andrés, A. Bhattacharyya, W. Antonin, J. Stegmaier
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

%% constrain the selction to ind_auswahl?
answer = questdlg('Would you like constrain the selection to the currently selected cells?', 'Constrain to current cells?', 'Yes', 'No', 'Cancel', 'Yes');
constrainToCurrentCells = strcmp('Yes', answer);

%% get the synchronization feature
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
syncFeature = parameter.gui.merkmale_und_klassen.ind_zr;

%% restore the old selection
set(gaitfindobj('CE_Auswahl_ZR'), 'value', oldSelection);
aktparawin;

%% loop through all indices and check for inconsitencies
invalidIndices = [];
for i=1:2:size(d_orgs,1)
    
   %% get the states of the current cell
   currentStates = unique(d_orgs(i,:, syncFeature));
   currentStates2 = unique(d_orgs(i+1,:, syncFeature));
   interPhaseFrames = find(d_orgs(i,:, syncFeature) == 1);
   
   %% add indices if there's any discrepancy between the two cells
   if (length(currentStates) > 1 && ...
      (~ismember(1, currentStates) || ...
       ~ismember(2, currentStates) || ...
       ~ismember(3, currentStates)) || ...
       sum(d_orgs(i,:, syncFeature) ~= d_orgs(i+1,:, syncFeature)) > 0 || ...
       (~isempty(interPhaseFrames) && max(interPhaseFrames) >= parameter.gui.livecellminer.IPTransition))
       invalidIndices = [invalidIndices; i; i+1]; %#ok<AGROW> 
   end
end

%% check if the invalid indices should be constrained to the current selection
if (constrainToCurrentCells == true)
    invalidIndices = intersect(ind_auswahl, invalidIndices);
end

%% set the selection to the invalid indices
if (~isempty(invalidIndices))
    ind_auswahl = invalidIndices;
    aktparawin;
else
    disp('No invalid annotations found!');
end