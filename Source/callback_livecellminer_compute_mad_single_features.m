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


%% get the selected single features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_em;
selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;

%% find the manual synchronization index
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

%% get stage transitions
if (synchronizationIndex > 0)
    confirmedTrack = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) > 0;
else
    confirmedTrack = ones(size(ind_auswahl));
end

%% retrieve the parameters and convert them to numbers
significanceLevel = 3;

disp(['Computing Median Absolute Deviation (MAD) using a threshold of ' num2str(significanceLevel) '*MAD for hits.']);

%% perform selected test to all selected features independently for each of the output variables
for f=selectedFeatures
    
    %% get the selected output classes
    selectedOutputClasses = unique(code(ind_auswahl));
    numOutputClasses = length(selectedOutputClasses);
    
   
    %% open result files for writing
    outputFileName = ['MADTest_' kill_lz(dorgbez(f,:)) '_TestResult.csv'];
    fileHandle = fopen([parameter.projekt.pfad filesep outputFileName], 'wb');
    
    %% write the specifiers
    fprintf(fileHandle, 'Feature Name; Median; MAD\n');
        
    %% compute the global median
    currentValues = d_org(ind_auswahl(confirmedTrack), f);
    currentValues(isinf(currentValues) | isnan(currentValues)) = [];
    globalMedian = median(currentValues);
    medianValues = zeros(numOutputClasses, 1);
    medianDeviations = zeros(numOutputClasses, 1);
    
    %% compute absolute median deviation
    for i=1:numOutputClasses

        %% get the current output classes
        currentClass = selectedOutputClasses(i);

        %% find indices matching the feature and output classes
        selectedIndices = intersect(ind_auswahl, find(code_alle(ind_auswahl, selectedOutputVariable) == currentClass & confirmedTrack));
        outputVariableName = zgf_y_bez(selectedOutputVariable, currentClass).name;

        %% get the feature values
        currentFeatureValues = d_org(selectedIndices, f);
        currentFeatureValues(isinf(currentFeatureValues) | isnan(currentFeatureValues)) = [];
        
        medianValues(i) = median(currentFeatureValues);
        medianDeviations(i) = abs(medianValues(i) - globalMedian);
    end
    
    MADValue = mean(medianDeviations);
    MADThreshold = globalMedian + 3*MADValue;
    
    fprintf(fileHandle, 'Global Median; %f; %f\n', globalMedian, MADValue);
    
    showHistogram = false; showViolinPlots = true; callback_livecellminer_show_combined_boxplots(parameter, d_org, d_orgs, dorgbez, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, showHistogram, showViolinPlots);
    
    fh = gcf; hold on;
    plot([0, numOutputClasses+1], [globalMedian, globalMedian], '--k', 'LineWidth', 2);
    plot([0, numOutputClasses+1], [globalMedian + significanceLevel*MADValue, globalMedian + 3*MADValue], '-.k', 'LineWidth', 2);
    plot([0, numOutputClasses+1], [globalMedian - significanceLevel*MADValue, globalMedian - 3*MADValue], '-.k', 'LineWidth', 2);

    currentYLim = get(gca, 'YLim');
    textOffset = (currentYLim(2) - currentYLim(1)) / 60;
    text(0.01, globalMedian + textOffset, 'Global Median');
    text(0.01, globalMedian + 3*MADValue + textOffset, sprintf('Global Median + %i*MAD', significanceLevel));
    text(0.01, globalMedian - 3*MADValue - textOffset, sprintf('Global Median - %i*MAD', significanceLevel));
    
    %% compute absolute median deviation
    for i=1:numOutputClasses
        
        %% get the current output classes
        currentClass = selectedOutputClasses(i);

        %% find indices matching the feature and output classes
        outputVariableName = zgf_y_bez(selectedOutputVariable, currentClass).name;

        %% get the feature values
        currentMAD = (medianValues(i) - globalMedian) / MADValue;
        
        %% print the current feature name
        fprintf(fileHandle, '%s;%f;%f;\n', outputVariableName, medianValues(i), currentMAD);
    end
    
    %% close the file handles
    fclose(fileHandle);
end