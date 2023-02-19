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

%% select the folder containing the raw images and for each project a CSV-based text file
%% containing one row for each position and three columns (Position, OligoID and GeneSymbol).
%% separator is assumed to be \t (i.e., tab).
inputFolder = uigetdir('V:\BiomedicalImageAnalysis\CellTracking_MorenoAndresUKA\Confocal\', 'Select the root folder containing the raw image data of all experiments that are part of this project.');

if (inputFolder == 0)
    disp('ERROR: No input folder selected. Aborting ...');
    return;
end

if (inputFolder(end) ~= '/' && inputFolder(end) ~= '\')
   inputFolder(end+1) = filesep; 
end

%% find output variable of the experiment
experimentId = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
microscopeId = callback_livecellminer_find_output_variable(bez_code, 'Microscope');
positionId = callback_livecellminer_find_output_variable(bez_code, 'Position');

%% open the first file and provide selection of which output variable to add.
%% find all cells belonging to the current experiment and determine the microscope
currentIndices = find(code_alle(:,experimentId) == 1);
currentMicroscrope = code_alle(currentIndices(1), microscopeId);

%% identify the folder containing the experiment
currentInputFolder = [inputFolder zgf_y_bez(microscopeId,currentMicroscrope).name filesep];
if (~isfolder(currentInputFolder))
    currentInputFolder = inputFolder;
end

%% try to load the oligoIds from a text file named identical to the experiment name with txt extension
oligoIdTextFile = [currentInputFolder zgf_y_bez(experimentId,1).name '.txt'];
if (~exist(oligoIdTextFile, 'file'))
    disp(['ERROR: OligoID CSV file was not found in the following path: ' oligoIdTextFile]);
    return;
end

%% open the file to get the available specifiers
fileID = fopen(oligoIdTextFile);
specifiers = strsplit(fgetl(fileID), '\t'); 
fclose(fileID);

prompt = specifiers;
dlgtitle = 'Which output variables do you want to add?';
dims = [1 35];
definput = {'0','1','0'};
selectedOutputVariables = inputdlg(prompt,dlgtitle,dims,definput);


for o=1:length(selectedOutputVariables)

    %% check if output variable should be added
    if (selectedOutputVariables{o} == '0')
        continue;
    end
    currentOutputVariableName = specifiers{o};

    %% check if the oligoID output variable already exists to avoid creating another one
    newOutputVariable = callback_livecellminer_find_output_variable(bez_code, currentOutputVariableName);
    if (newOutputVariable == 0)    
        code_alle(:,end+1) = 0;
        newOutputVariable = size(code_alle, 2);
        bez_code = char(bez_code, currentOutputVariableName);
    end
        
    %% initialize the oligoIDs
    oligoIDs = cell(0);
        
    %% run through all experiments and add the oligoIDs to each plate
    for i=unique(code_alle(:,experimentId))'
    
	    %% find all cells belonging to the current experiment and determine the microscope
        currentIndices = find(code_alle(:,experimentId) == i);
        currentMicroscrope = code_alle(currentIndices(1), microscopeId);
    
	    %% identify the folder containing the experiment
        currentInputFolder = [inputFolder zgf_y_bez(microscopeId,currentMicroscrope).name filesep];
        if (~isfolder(currentInputFolder))
            currentInputFolder = inputFolder;
        end
        
	    %% try to load the oligoIds from a text file named identical to the experiment name with txt extension
        metaDataTextFile = [currentInputFolder zgf_y_bez(experimentId,i).name '.txt'];
        if (~exist(metaDataTextFile, 'file'))
            disp(['ERROR: meta data CSV file was not found in the following path: ' metaDataTextFile]);
            return;
        end
    
	    %% open the text file and process each line
        fileID = fopen(metaDataTextFile);
        fgetl(fileID); %% skip the specifiers
        currentLine = fgetl(fileID);
    
	    %% process all lines
        while ischar(currentLine)
    
		    %% extract the position and oligoID from the current line
            splitString = strsplit(currentLine, '\t');
            currentProject = zgf_y_bez(experimentId,i).name;
            
            if (splitString{1}(1) == 'P')
                splitString{1} = splitString{1}(2:end);
            end
            
            currentPosition = str2double(splitString{1});
            currentOligoID = splitString{o};
    
            %% check if oligo ID is already present
            existingID = 0;
            for j=1:size(oligoIDs, 2)
                if (strcmp(oligoIDs(j), currentOligoID))
                    existingID = j;
                    break;
                end
            end
    
		    %% if id is not present, add it
            if (existingID == 0)
                existingID = length(oligoIDs)+1;
                oligoIDs{existingID} = currentOligoID;
                zgf_y_bez(newOutputVariable,existingID).name = currentOligoID; %#ok<SAGROW> 
            end
            
            %% find positionId in the output variable
            codeAllePosition = 0;
            for j=unique(code_alle(:,positionId))'
                if (str2double(zgf_y_bez(positionId, j).name(end-1:end)) == currentPosition)
                   codeAllePosition = j;
                   break;
                end
            end
    
		    %% identify cells belonging to the current position and experiment and set the code value accordingly
            validIndices = find(code_alle(:,experimentId) == i & code_alle(:,positionId) == codeAllePosition);
            code_alle(validIndices, newOutputVariable) = existingID;
    
		    %% get the next line
            currentLine = fgetl(fileID);
        end
	    
	    %% close the file handle
        fclose(fileID);
    end
    
    %% update the scixminer window
    aktparawin;
end