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

%% add path to the stats toolbox as scixminer shadows the required kstest function
%addpath([matlabroot '/toolbox/stats/stats/']);


callback_normtest(d_org(ind_auswahl,:),dorgbez,code(ind_auswahl),zgf_y_bez,bez_code,par,parameter,uihd);


% %% get the selected single features
% selectedFeatures = parameter.gui.merkmale_und_klassen.ind_em;
% selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
% 
% %% ask user which test to perform
% prompt = {'Significance Level:'};
% dlgtitle = 'One-Sample Kolmogorov-Smirnov Test';
% dims = [1 35];
% definput = {'0.05'};
% answer = inputdlg(prompt,dlgtitle,dims,definput);
% 
% %% retrieve the parameters and convert them to numbers
% significanceLevel = parameter.gui.statistikoptionen.p_krit;
% 
% %% open result text files
% outputFileName1 = 'NormalityTest_TestResult.csv';
% outputFileName2 = 'NormalityTest_PValues.csv';
% outputFileName3 = 'NormalityTest_Readme.txt';
% fileHandle1 = fopen([parameter.projekt.pfad filesep outputFileName1], 'wb');
% fileHandle2 = fopen([parameter.projekt.pfad filesep outputFileName2], 'wb');
% fileHandle3 = fopen([parameter.projekt.pfad filesep outputFileName3], 'wb');
% fprintf(fileHandle3, 'Info: returns a test decision for the null hypothesis that the data in vector x comes from a standard normal distribution, against the alternative that it does not come from such a distribution, using the one-sample Kolmogorov-Smirnov test. The result h is 1 if the test rejects the null hypothesis at the %.2f%% significance level, or 0 otherwise.', 100*significanceLevel);
% fclose(fileHandle3);
%     
% %% print the specifiers to the text files
% fprintf(fileHandle1, 'Feature/Class;');
% fprintf(fileHandle2, 'Feature/Class;');
% for i=1:length(selectedOutputClasses)
%     fprintf(fileHandle1, '%s;', zgf_y_bez(selectedOutputVariable, selectedOutputClasses(i)).name);
%     fprintf(fileHandle2, '%s;', zgf_y_bez(selectedOutputVariable, selectedOutputClasses(i)).name); 
% end
% fprintf(fileHandle1, '\n');
% fprintf(fileHandle2, '\n');
% 
% %% perform selected test to all selected features independently for each of the output variables
% for f=selectedFeatures
%     
%     %% get the number of classes for the current output variable
%     selectedOutputClasses = unique(code(ind_auswahl));
%     
%     %% write the feature name of the current feature
%     fprintf(fileHandle1, '%s;', kill_lz(dorgbez(f,:)));
%     fprintf(fileHandle2, '%s;', kill_lz(dorgbez(f,:)));
%     
%     %% analyze output classess separately
%     for o=selectedOutputClasses'
%         
%         %% find the selected indices for the current output variable
%         selectedIndices = find(code == o);
%         outputVariableName = zgf_y_bez(selectedOutputVariable, o).name;
%         
%         %% get the feature values and compute the z-scores
%         currentFeatureValues = d_org(selectedIndices, f);
%         currentFeatureValues = (currentFeatureValues - mean(currentFeatureValues)) / std(currentFeatureValues);
% 
%         %% remove nans and infs if present
%         currentFeatureValues(isnan(currentFeatureValues)) = [];
%         currentFeatureValues(isinf(currentFeatureValues)) = [];
%         
%         %% perform the selected test if valid values are available
%         if (~isempty(currentFeatureValues))
%             [h, p] = kstest(currentFeatureValues, 'alpha', significanceLevel);
%             if (h == 1); resultInterpretation = 'rejected'; else; resultInterpretation = 'not-rejected'; end
%         else
%             h = nan;
%             p = nan;
%             resultInterpretation = 'no data available';
%         end
%         
%         %% print the test results to file and console
%         fprintf(fileHandle1, '%f;', h);
%         fprintf(fileHandle2, '%f;', p);        
%         fprintf('Testing single feature %s for class %s for normality: %i (%s, p = %f) \n', kill_lz(dorgbez(f,:)), outputVariableName, h, resultInterpretation, p);
%     end
%     
%     %% add line breaks
%     fprintf(fileHandle1, '\n');
%     fprintf(fileHandle2, '\n');
% end
% 
% %% close the file handles
% fclose(fileHandle1);
% fclose(fileHandle2);