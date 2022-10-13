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

syncIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
manuallyCheckedIndex = callback_livecellminer_find_single_feature(dorgbez, 'manuallyConfirmed');

[fileName, folderName] = uigetfile('*.mat', 'Please select appropriate synchronization file that was exported from another SciXMiner project of the same experiment.');
load([folderName filesep fileName]);

microscopeIndexOld = callback_livecellminer_find_output_variable(bez_code_old, 'Microscope');
experimentIndexOld = callback_livecellminer_find_output_variable(bez_code_old, 'Experiment');
positionIndexOld = callback_livecellminer_find_output_variable(bez_code_old, 'Position');

microscopeIndexNew = callback_livecellminer_find_output_variable(bez_code, 'Microscope');
experimentIndexNew = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
positionIndexNew = callback_livecellminer_find_output_variable(bez_code, 'Position');

for mOld=unique(code_alle_old(:,microscopeIndexOld))'
    for eOld=unique(code_alle_old(:,experimentIndexOld))'
        for pOld=unique(code_alle_old(:,positionIndexOld))'
            
            oldMicroscope = zgf_y_bez_old(microscopeIndexOld, mOld).name;
            oldExperiment = zgf_y_bez_old(experimentIndexOld, eOld).name;
            oldPosition = zgf_y_bez_old(positionIndexOld, pOld).name;
            
            successFlag = false;
            oldIndices = find(code_alle_old(:,microscopeIndexOld) == mOld & code_alle_old(:,experimentIndexOld) == eOld & code_alle_old(:,positionIndexOld) == pOld);
            
            for mNew=unique(code_alle(:,microscopeIndexNew))'
                for eNew=unique(code_alle(:,experimentIndexNew))'
                    for pNew=unique(code_alle(:,positionIndexNew))'
                        
                        newMicroscope = zgf_y_bez(microscopeIndexNew, mNew).name;
                        newExperiment = zgf_y_bez(experimentIndexNew, eNew).name;
                        newPosition = zgf_y_bez(positionIndexNew, pNew).name;
                        
                        if (successFlag == true || strcmp(oldMicroscope, newMicroscope) == 0 || strcmp(oldExperiment, newExperiment) == 0 || strcmp(oldPosition, newPosition) == 0)
                            continue;
                        else
                            newIndices = find(code_alle(:,microscopeIndexNew) == mNew & code_alle(:,experimentIndexNew) == eNew & code_alle(:,positionIndexNew) == pNew);

                            if (length(newIndices) == length(oldIndices))
                                d_orgs(newIndices, :, syncIndex) = d_orgs_old(oldIndices, :); %#ok<SAGROW> 
                                d_org(newIndices, manuallyCheckedIndex) = d_org_old(oldIndices, :); %#ok<SAGROW> 
                                successFlag = true;
                                disp(['Successfully copied synchronization for ' newMicroscope ' / ' newExperiment ' / ' newPosition]);
                            else
                                disp(['Matching entries found for ' newMicroscope ' / ' newExperiment ' / ' newPosition ' but number of cell deviates (' num2str(length(oldIndices)) ' vs. ' num2str(length(newIndices)) ')!!']); 
                            end
                        end
                    end
                end
            end
            
            if (successFlag == false)
                disp(['No matching entries found for ' oldMicroscope ' / ' oldExperiment ' / ' oldPosition '!!']); 
            end
        end
    end
end


