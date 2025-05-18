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

%% get the selected single features
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;
selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
experimentOutputVariable = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

numGroups = length(unique(code_alle(:,selectedOutputVariable)));

if (numGroups <= 1)
    disp('Error: The selected output variable contains only one group, i.e., there is nothing to compare. Please select a different output variable and repeat.');
    return;
end

%% get stage transitions
if (synchronizationIndex > 0)
    confirmedTrack = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) > 0;
else
    confirmedTrack = ones(size(ind_auswahl));
end

%% ask user which test to perform
% prompt = {sprintf('Absolute Time Points (Comma Separated, 1-%i):', parameter.gui.livecellminer.alignedLength)};
% dlgtitle = 'Select Time Points to Compare';
% dims = [1 35];
% definput = {'20, 60, 100'};
% answer = inputdlg(prompt,dlgtitle,dims,definput);

prompt = {'Frames Before IP (e.g., -10, -5 for IP - 10 and IP - 5, leave empty to ignore):', ...
          'Frames After IP (e.g., 10 for IP + 10, leave empty to ignore):', ...
          'Frames Before MA (e.g., 10 for MA - 10, leave empty to ignore):', ...
          'Frames After MA (e.g., 10 for MA + 10, leave empty to ignore):'};
dlgtitle = sprintf('Select Time Points to Compare (IP Frame: %i, MA Frame: %i, Aligned Length: %i)', parameter.gui.livecellminer.IPTransition, parameter.gui.livecellminer.MATransition, parameter.gui.livecellminer.alignedLength);
dims = [1 100];
definput = {'-10, -5', '', '', '5, 10'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

timePointsBeforeIP = parameter.gui.livecellminer.IPTransition + str2num(answer{1});
timePointsAfterIP = parameter.gui.livecellminer.IPTransition + str2num(answer{2});
timePointsBeforeMA = parameter.gui.livecellminer.MATransition + str2num(answer{3});
timePointsAfterMA = parameter.gui.livecellminer.MATransition + str2num(answer{4});

timePoints = [timePointsBeforeIP, timePointsAfterIP, timePointsBeforeMA, timePointsAfterMA];

if (min(timePoints) < 1 || max(timePoints) > parameter.gui.livecellminer.alignedLength)
    fprintf('Your time point selection is invalid (%s)! Make sure that the minimum time point is larger than 1 and that the maximum time point is smaller than %i.\n', num2str(timePoints), parameter.gui.livecellminer.alignedLength);
    return;
end

%% cancel processing if no time points were seleted
if (isempty(timePoints))
   disp('No time points selected, aborting ANOVA computations...');
   return;
end

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
        
    %% create an output file
    outputFileName1 = ['TwoWayANOVA_' zgf_y_bez(experimentOutputVariable,1).name '_' kill_lz(var_bez(f,:)) '_TestResults.csv'];
    fileHandle1 = fopen([parameter.projekt.pfad filesep outputFileName1], 'wb');
    
    fprintf(fileHandle1, 'Figure;Feature;Time Point;Group1;Group2;P-Value;Sign. (alpha = %.2f);Method;Multiple Testing Correction;Notes\n', parameter.gui.statistikoptionen.p_krit);
    
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
        responseVariable = [responseVariable; currentValues(validIndices);]; %#ok<AGROW>
        
        %% assemble the group names based on the time points and the selected output classes
        clear currentGroupNames;
        timeString = sprintf('TP%04d', i);
        for j=1:length(validIndices)
           timeFeature{currentIndex} = timeString; %#ok<SAGROW>
           groupNames{currentIndex} = zgf_y_bez(selectedOutputVariable, code(ind_auswahl(validIndices(j)))).name; %#ok<SAGROW>
           currentGroupNames{j} = zgf_y_bez(selectedOutputVariable, code(ind_auswahl(validIndices(j)))).name; %#ok<SAGROW>
           currentIndex = currentIndex+1;
        end
        
        %% perform anova for individual time points
        [~,ANOVATAB,STATS] = anova1(currentValues(validIndices)', currentGroupNames);
        
        figure;
        [c,~,~,gnames] = multcompare(STATS, 'CType', multipleTestingMethod);
        
        for j=1:size(c,1)
            c(j,end)
            fprintf(fileHandle1, '%i;%s;%i;%s;%s;%.2e;%i;One-Way ANOVA;%s;Comparing individual time points;\n', 1, kill_lz(var_bez(f,:)), i, gnames{c(j,1)}, gnames{c(j,2)}, c(j,end), c(j,end) < parameter.gui.statistikoptionen.p_krit, multipleTestingMethod);
        end
        
        %% Window,  Close figures 
        eval(gaitfindobj_callback('MI_Schliessen'));
    end
    
    %% compute the two-way anova with the selected time series as responses and the selected output classes and frames as the independent variables
    [p,tbl,stats] = anovan(responseVariable, {groupNames, timeFeature(:)}, 'model','interaction', 'varnames', {'class', 'time'});
    
    %% display the comparison of the computed confidence intervals
    figure;
    [c,m,h,gnames] = multcompare(stats, 'CType', multipleTestingMethod);
    
    for j=1:size(c,1)
        fprintf(fileHandle1, '%i;%s;%s;%s;%s;%.2e;%i;Two-Way ANOVA;%s; Interaction model comparing all selected time points\n', 1,kill_lz(var_bez(f,:)), num2str(timePoints), gnames{c(j,1)}, gnames{c(j,2)}, c(j,end), c(j,end) < parameter.gui.statistikoptionen.p_krit, multipleTestingMethod);
    end
    
    %% Window,  Close figures 
    eval(gaitfindobj_callback('MI_Schliessen'));
    
    %% close the file
    fclose(fileHandle1);
end