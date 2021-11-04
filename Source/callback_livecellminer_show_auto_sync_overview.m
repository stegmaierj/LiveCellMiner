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

%% check the number of occurrences for the different output classes and experiments (to ensure there are sufficient samples per treatment).
currentCounts = zeros(max(code_alle(:,experimentId)), max(code_alle(:,oligoId)));

experimentIds = unique(code_alle(:,experimentId));
oligoIds = unique(code_alle(:,oligoId));

experimentLabels = cell(length(experimentIds), 1);
oligoLabels = cell(length(oligoIds), 1);

for i=experimentIds'
    
    experimentLabels{i} = strrep(zgf_y_bez(experimentId,i).name, '_', '\_');
    
    for j=oligoIds'
        validIndices = find(code_alle(:,experimentId) == i & code_alle(:,oligoId) == j & squeeze(d_orgs(:,1,syncFeature)) > 0);
        invalidIndices = find(code_alle(:,experimentId) == i & code_alle(:,oligoId) == j & squeeze(d_orgs(:,1,syncFeature)) <= 0);
            
        currentCounts(i, j) = length(validIndices);
        
        oligoLabels{j} = strrep(zgf_y_bez(oligoId,j).name, '_', '\_');
        
        if (isempty(validIndices) && isempty(invalidIndices))
            continue;
        end
        
                
        disp(['Experiment: ' zgf_y_bez(experimentId,i).name ', OligoID: ' zgf_y_bez(oligoId,j).name, ', valid sync information: ' num2str(length(validIndices)) ' / ' num2str(length(validIndices) + length(invalidIndices))]);
    end
end

disp(['Total number of valid sync information: ' num2str(sum(currentCounts(:))) ' / ' num2str(size(d_orgs,1))]);

for i=1:length(oligoLabels)
    if (isempty(oligoLabels{i}))
        oligoLabels{i} = '';
    end    
end
    
figure(2);
h = heatmap(currentCounts);
h.YLabel = 'Experiment';
h.XLabel = 'OligoID';
h.YDisplayLabels = experimentLabels;
h.XDisplayLabels = oligoLabels;
h.Title = 'Number of valid cells per experiment / oligo combination';