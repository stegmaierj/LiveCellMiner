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

%% clear console entries
clc;

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
significanceLevel = parameter.gui.statistikoptionen.p_krit;

if (~exist('statisticalTestMethod', 'var'))
    statisticalTestMethod = 'ttest2';
end
disp(['Computing statistical test using the ' statisticalTestMethod ' method.']);

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

%% perform selected test to all selected features independently for each of the output variables
for f=selectedFeatures
    
    %% get the selected output classes
    selectedOutputClasses = unique(code(ind_auswahl));
    numOutputClasses = length(selectedOutputClasses);
    
    if ((strcmp(statisticalTestMethod, 'anova') || strcmp(statisticalTestMethod, 'kruskalwallis')) && numOutputClasses <= 1)
        disp('ANOVA and Kruskal-Wallis can only be applied for more than one group!');
        return;
    end
    
    %% open result files for writing
    outputFileName1 = [statisticalTestMethod '_' kill_lz(dorgbez(f,:)) '_TestResult.csv'];
    outputFileName2 = [statisticalTestMethod '_' kill_lz(dorgbez(f,:)) '_PValues.csv'];
    outputFileName3 = [statisticalTestMethod '_' kill_lz(dorgbez(f,:)) '_Readme.txt'];
    fileHandle1 = fopen([parameter.projekt.pfad filesep outputFileName1], 'wb');
    fileHandle2 = fopen([parameter.projekt.pfad filesep outputFileName2], 'wb');
    fileHandle3 = fopen([parameter.projekt.pfad filesep outputFileName3], 'wb');
    fprintf(fileHandle3, 'Info: Returns a test decision for the null hypothesis that the data in vectors x and y comes from independent random samples from normal distributions with equal means and equal but unknown variances, using the two-sample t-test. The alternative hypothesis is that the data in x and y comes from populations with unequal means. The result h is 1 if the test rejects the null hypothesis at the %.2f%% significance level, and 0 otherwise.', 100*significanceLevel);
    fclose(fileHandle3);
    
    %% write the specifiers
    fprintf(fileHandle1, 'Class1/Class2;');
    fprintf(fileHandle2, 'Class1/Class2;');
    for i=1:numOutputClasses
        fprintf(fileHandle1, '%s;', zgf_y_bez(selectedOutputVariable, selectedOutputClasses(i)).name);
        fprintf(fileHandle2, '%s;', zgf_y_bez(selectedOutputVariable, selectedOutputClasses(i)).name);
    end
    fprintf(fileHandle1, '\n');
    fprintf(fileHandle2, '\n');
    
    clear groupNames;
    for i=1:length(ind_auswahl)
        groupNames{i} = zgf_y_bez(selectedOutputVariable, code(ind_auswahl(i))).name; %#ok<SAGROW> 
    end
    
    %% perform ANOVA or Kruskal-Wallis
    if (strcmp(statisticalTestMethod, 'anova'))
      
        [p,ANOVATAB,STATS] = anova1(d_org(ind_auswahl(confirmedTrack), f), groupNames(confirmedTrack));
        
        figure;
        multcompare(STATS, 'CType', multipleTestingMethod);
    elseif (strcmp(statisticalTestMethod, 'kruskalwallis'))
        [p, ANOVATAB,STATS] = kruskalwallis(d_org(ind_auswahl(confirmedTrack), f), groupNames(confirmedTrack));
        
        figure;
        c = multcompare(STATS, 'CType', multipleTestingMethod);

        for i=1:size(c,1)
            oligo1 = c(i,1);
            oligo2 = c(i,2);
            fprintf('%s vs. %s, p-value: %e\n', zgf_y_bez(parameter.gui.merkmale_und_klassen.ausgangsgroesse, oligo1).name, zgf_y_bez(parameter.gui.merkmale_und_klassen.ausgangsgroesse, oligo2).name, c(i,6));
        end
    else
                    
        %% compute t-test of all classes against all other classes
        for i=1:numOutputClasses

            %% print the current feature name
            fprintf(fileHandle1, '%s;', zgf_y_bez(selectedOutputVariable, selectedOutputClasses(i)).name);
            fprintf(fileHandle2, '%s;', zgf_y_bez(selectedOutputVariable, selectedOutputClasses(i)).name);

            %% run through the classes again 
            for j=1:numOutputClasses

                %% get the current output classes
                class1 = selectedOutputClasses(i);
                class2 = selectedOutputClasses(j);

                %% find indices matching the feature and output classes
                selectedIndices1 = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == class1 & confirmedTrack));
                selectedIndices2 = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == class2 & confirmedTrack));
                outputVariableName1 = zgf_y_bez(selectedOutputVariable, class1).name;
                outputVariableName2 = zgf_y_bez(selectedOutputVariable, class2).name;

                %% get the feature values
                currentFeatureValues1 = d_org(selectedIndices1, f);
                currentFeatureValues2 = d_org(selectedIndices2, f);

                %% compute the t-test for the current classes
                if (strcmp(statisticalTestMethod, 'ttest2'))
                    [h, p] = ttest2(currentFeatureValues1, currentFeatureValues2, 'alpha', significanceLevel);
                elseif (strcmp(statisticalTestMethod, 'wilcoxon'))
                    [p,h] = ranksum(currentFeatureValues1, currentFeatureValues2, 'alpha', significanceLevel);
                end

                if (h == 1); resultInterpretation = 'rejected'; else; resultInterpretation = 'not-rejected'; end

                %% write results to the file
                fprintf(fileHandle1, '%f;', h);
                fprintf(fileHandle2, '%f;', p);
                fprintf('%s test that %s and %s for feature %s comes from a normal distribution with mean equal to zero and unknown variance: %i (%s, p = %f) \n', statisticalTestMethod , outputVariableName1, outputVariableName2, kill_lz(dorgbez(f,:)), h, resultInterpretation, p);
            end

            %% add line breaks
            fprintf(fileHandle1, '\n');
            fprintf(fileHandle2, '\n');
        end

        %% close the file handles
        fclose(fileHandle1);
        fclose(fileHandle2);
    end
end