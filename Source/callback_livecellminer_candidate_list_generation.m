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

%% function to generate potential candidates for cell division stages
function [motherList, daughterList, motherDaughterList] = callback_livecellminer_candidate_list_generation(d_orgs, parameters)

    timeWindowMother = parameters.timeWindowMother;
    timeWindowDaughter = parameters.timeWindowDaughter;

    %% extract the tracking information in CTC format
    maxTrackingId = max(max(max(d_orgs(:,:,parameters.trackingIdIndex))));
    trackingData = zeros(maxTrackingId, 4);
    for i=1:maxTrackingId

        %% identify valid time points and continue if empty
        validTimePoints = find(squeeze(d_orgs(i,:,3) > 0));
        if (isempty(validTimePoints))
            continue;
        end

        %% write lines of the result tracking file
        if (i == d_orgs(i, min(validTimePoints), parameters.predecessorIdIndex))
            trackingData(i,:) = [i, min(validTimePoints)-1, max(validTimePoints)-1, 0];
        else
            trackingData(i,:) = [i, min(validTimePoints)-1, max(validTimePoints)-1, d_orgs(i,min(validTimePoints), parameters.predecessorIdIndex)];
        end
    end
    
    %% initialize the result lists
    motherDaughterList = [];
    motherList = [];
    daughterList = [];
        
    % Trajectory has a valid predecessor (entry in the 4th column is non-zero).
    % Trajectory ends before the entire time lapse data set ends ...
    % ...(entry in  the 3rd column is smaller than the number of frames)
    % Trajectory has two successors, i.e., there are two trajectories with the current trajectory as a mother.
    
    for i=1:length(trackingData)
        
        %% get the potential predecessor id
        potentialMotherId = trackingData(i,4);
        
        %% if predecessor exists, check if it has two daughters and if yes add it
        if potentialMotherId ~=0
            
            %% get the number of daughters with the same predecessor. Each valid cell has 2 successors
            daughterIds = find(trackingData(:,4) == potentialMotherId);
            numDaughters = length(daughterIds);
            
            %% if number of daughters matches 2, add the cell to the candidate list
            if numDaughters == 2
                % [daughter] = find(txtData(:,4) == tempVal);
                %% output(j,:) = txtData(i,:); 
                %% TODO: double-check why the above line was wrong.
                %% you actually selected the final time points of cells that have a predecessor
                %% however, we wanted to have the final time points of the predecessor itself, given that it has two daughters.
                %% see lines below on what i changed for the selection             
                %% Compute the length of the daughters. 
                %% An indicator for an erroneous division is at least one very short daughter track.
                motherIndex = find(trackingData(:,1) == potentialMotherId);
                daughter1Index = trackingData(daughterIds(1),1);
                daughter2Index = trackingData(daughterIds(2),1);
                
                motherLength = trackingData(motherIndex, 3) - trackingData(motherIndex, 2);
                daughter1Length = trackingData(daughter1Index, 3) - trackingData(daughter1Index, 2);
                daughter2Length = trackingData(daughter2Index, 3) - trackingData(daughter2Index, 2);
                                
                %% if daughter lengths are sufficiently large, add the cell candidate
                if (~isempty(motherLength) && motherLength >= timeWindowMother && min([daughter1Length, daughter2Length]) >= timeWindowDaughter)
                    currentMother = trackingData(motherIndex,:);
                    currentDaughter1 = trackingData(daughter1Index,:);
                    currentDaughter2 = trackingData(daughter2Index,:);
                    currentMother(2:3) = [currentMother(3)-timeWindowMother+1, currentMother(3)];
                    currentDaughter1(2:3) = [currentDaughter1(2), currentDaughter1(2) + timeWindowDaughter - 1];
                    currentDaughter2(2:3) = [currentDaughter2(2), currentDaughter2(2) + timeWindowDaughter - 1];                    
                    motherList = [motherList; currentMother]; %#ok<AGROW> 
                    daughterList = [daughterList; currentDaughter1; currentDaughter2]; %#ok<AGROW> 
                    motherDaughterList = [motherDaughterList; motherIndex, daughter1Index, daughter2Index]; %#ok<AGROW> 
                end
            end
        end
    end

    %% remove duplicate rows
    motherList = unique(motherList, 'rows');
    daughterList = unique(daughterList, 'rows');
    motherDaughterList = unique(motherDaughterList, 'rows');
end
