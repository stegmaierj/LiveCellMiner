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

%% remember old selection
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;

%% get the synchronization index
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
syncFeature = parameter.gui.merkmale_und_klassen.ind_zr;

%% restore the old selection
set(gaitfindobj('CE_Auswahl_ZR'), 'value', oldSelection);
aktparawin;

%% get the experiment id and oligo id
experimentId = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
oligoId = callback_livecellminer_find_output_variable(bez_code, 'OligoID');

if (experimentId == 0 || oligoId == 0)
    disp('ERROR: Experiment or OligoID output variable were not found. Please run "LiveCellMiner -> Process -> Add OligoId Output Variable"');
    return; 
end

experimentIds = unique(code_alle(ind_auswahl,experimentId));
oligoIds = unique(code_alle(ind_auswahl,oligoId));

%% check the number of occurrences for the different output classes and experiments (to ensure there are sufficient samples per treatment).
currentCounts = zeros(length(experimentIds), length(oligoIds));

experimentLabels = cell(length(experimentIds), 1);
oligoLabels = cell(length(oligoIds), 1);

currentExperiment = 1;

for i=experimentIds'
    
    experimentLabels{currentExperiment} = strrep(zgf_y_bez(experimentId,i).name, '_', '\_');
    currentOligoID = 1;
    
    for j=oligoIds'
        validIndices = ind_auswahl(find(code_alle(ind_auswahl,experimentId) == i & code_alle(ind_auswahl,oligoId) == j & squeeze(d_orgs(ind_auswahl,1,syncFeature)) > 0));
        invalidIndices = ind_auswahl(find(code_alle(ind_auswahl,experimentId) == i & code_alle(ind_auswahl,oligoId) == j & squeeze(d_orgs(ind_auswahl,1,syncFeature)) <= 0));
            
        currentCounts(currentExperiment, currentOligoID) = length(validIndices);
        
        oligoLabels{currentOligoID} = strrep(zgf_y_bez(oligoId,j).name, '_', '\_');
        currentOligoID = currentOligoID + 1;
        
        if (isempty(validIndices) && isempty(invalidIndices))
            continue;
        end
        
                
        disp(['Experiment: ' zgf_y_bez(experimentId,i).name ', OligoID: ' zgf_y_bez(oligoId,j).name, ', valid sync information: ' num2str(length(validIndices)) ' / ' num2str(length(validIndices) + length(invalidIndices))]);
    end

    currentExperiment = currentExperiment + 1;
end

disp(['Total number of valid sync information: ' num2str(sum(currentCounts(:))) ' / ' num2str(length(ind_auswahl))]);

%for i=1:length(oligoLabels)
%    if (isempty(oligoLabels{i}))
%        oligoLabels{i} = '';
%    end    
%end
    
fh = figure(2);
set(fh, 'Units','normalized', 'OuterPosition', [0,0,1,1]);

h = heatmap(currentCounts);
h.YLabel = 'Experiment';
h.XLabel = 'OligoID';
h.YDisplayLabels = experimentLabels;
h.XDisplayLabels = oligoLabels;
h.Title = 'Number of valid cells per experiment / oligo combination';