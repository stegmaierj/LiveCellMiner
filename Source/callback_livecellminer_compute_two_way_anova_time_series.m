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


%% get the selected single features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;
selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

%% get stage transitions
if (synchronizationIndex > 0)
    confirmedTrack = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) > 0;
else
    confirmedTrack = ones(size(ind_auswahl));
end

%% ask user which test to perform
prompt = {sprintf('Absolute Time Points (Comma Separated, 1-%i):', parameter.gui.livecellminer.alignedLength)};
dlgtitle = 'Select Time Points to Compare';
dims = [1 35];
definput = {'20, 60, 100'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

%% cancel processing if no time points were seleted
if (isempty(answer))
   disp('No time points selected, aborting ANOVA computations...');
   return;
end
timePoints = str2num(answer{1});

%% retrieve the parameters and convert them to numbers
significanceLevel = parameter.gui.statistikoptionen.p_krit;

%% get method for multiple testing
switch (parameter.gui.livecellminer.multipleTestingMethod)
    case 1
        multipleTestingMethod = 'tukey-kramer';
    case 2
        multipleTestingMethod = 'hsd';
    case 3
        multipleTestingMethod = 'lsd';
    case 4
        multipleTestingMethod = 'bonferroni';
    case 5
        multipleTestingMethod = 'dunn-sidak';
    case 6
        multipleTestingMethod = 'scheffe';
    otherwise
        multipleTestingMethod = 'tukey-kramer';
end

%% get the selected output classes
selectedOutputClasses = unique(code(:));
numOutputClasses = length(selectedOutputClasses);

%% perform selected test to all selected features independently for each of the output variables
for f=selectedFeatures
        
    %% get the aligned heat map for the current time series
    [resultHeatMap] = callback_livecellminer_compute_aligned_heatmap(d_orgs, ind_auswahl, synchronizationIndex, f, parameter);

    %% prepare the response variables and group names for the anova function
    responseVariable = [];
    currentIndex = 1;
    clear timeFeature;
    clear groupNames;
    for i=timePoints
        
        %% extract the column of feature values for the current time point
        currentValues = resultHeatMap(:,i);
        
        %% identify valid indices to remove infs and nans if present
        validIndices = find(~isnan(currentValues) & ~isinf(currentValues) & confirmedTrack);
        
        %% stack responses of the different time points to a single variable
        responseVariable = [responseVariable; currentValues(validIndices);];
        
        %% assemble the group names based on the time points and the selected output classes
        timeString = sprintf('TP%04d', i);
        for j=1:length(validIndices)
           timeFeature{currentIndex} = timeString;
           groupNames{currentIndex} = zgf_y_bez(selectedOutputVariable, code(ind_auswahl(validIndices(j)))).name;
           currentIndex = currentIndex+1;
        end
    end
    
    %% compute the two-way anova with the selected time series as responses and the selected output classes and frames as the independent variables
    [p,tbl,stats] = anovan(responseVariable, {groupNames, timeFeature(:)}, 'model','interaction', 'varnames', {'class', 'time'});
    
    %% display the comparison of the computed confidence intervals
    figure;
    multcompare(stats, 'CType', multipleTestingMethod);
end