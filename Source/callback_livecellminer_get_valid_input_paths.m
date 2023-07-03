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

%% lists all subdirectories and searches for valid position folders containing image data.
function [inputFolders, microscopeList, experimentList, positionList] = callback_livecellminer_get_valid_input_paths(inputRootFolders)
       
    %% initialize folder, experiment and position variables
    currentFolderIndex = 1;
    experimentIndex = 1;
    microscopeIndex = 1;
    positionIndex = 1;
    
    %% initialize the cell arrays for files, microscopes, experiments and positions
    microscopeList = cell(1,1);
    experimentList = cell(1,1);
    micronsPerPixel = cell(1,1);
    channelFilter = cell(1,1);
    positionList = cell(1,1);
    
    if (~iscell(inputRootFolders))
        inputRootFoldersTemp = cell(1,1);
        inputRootFoldersTemp{1} = inputRootFolders;
        inputRootFolders = inputRootFoldersTemp;
    end

    %% process all selected folders
    for f=1:length(inputRootFolders)
        
        %% get the current root folder
        inputRootFolder = inputRootFolders{f};

        %% display status as it may take a bit
        disp('Recursively scanning input directory for valid position folders ...');

        %% ensure that the last character of the path is not a file separator
        if (inputRootFolder(end) == '/' || inputRootFolder(end) == '\')
            inputRootFolder = inputRootFolder(1:end-1);
        end

        %% get the list of subdirectories
        initialSubdirList = dir([inputRootFolder filesep '**']);
        subdirList = cell(1,1);

        %% add root folder (in case the desired positions were directly selected)
        subdirList{1} = inputRootFolder;

        currentSubDir = 2;
        for i=1:length(initialSubdirList)
           if (initialSubdirList(i).isdir && ~strcmp(initialSubdirList(i).name, '.') && ~strcmp(initialSubdirList(i).name, '..'))
               subdirList{currentSubDir} = [initialSubdirList(i).folder filesep initialSubdirList(i).name];
               currentSubDir = currentSubDir + 1;
           end
        end
        
        if (isempty(subdirList) || isempty(subdirList{1}))
            subdirList{1} = inputRootFolder;
        end

        %% iterate over all subdirs and add them if appropriate
        for i=1:length(subdirList)

            %% convert to unix-style paths
            currentSubDir = strrep(subdirList{i}, '\', '/');

            %% perform regexp search for a valid plate idenfier
            expression = '[Pp][0]*0[0123456789]+';
            splitString = strsplit(currentSubDir, '/');
            startIndex = regexp(splitString{end}, expression); %#ok<RGXP1> 

            %% only add path if the regular expression was found
            if (~isempty(startIndex))

                %% set the input folder
                inputFolders{currentFolderIndex} = currentSubDir; %#ok<AGROW> 

                %% extract the microscope, experiment and position from the file name
                currentMicroscope = splitString{end-2};
                currentExperiment = splitString{end-1};
                currentPosition = splitString{end};

                %% check if any of the output variables already exists
                microscopeFound = false;
                experimentFound = false;
                positionFound = false;
                for j=1:length(microscopeList)
                   if (strcmp(microscopeList{j}, currentMicroscope))
                       microscopeFound = true;
                   end
                end

                for j=1:length(experimentList)
                   if (strcmp(experimentList{j}, currentExperiment))
                       experimentFound = true;
                   end
                end

                for j=1:length(positionList)
                   if (strcmp(positionList{j}, currentPosition))
                       positionFound = true;
                   end
                end

                %% add output variables if they were not contained yet
                if (microscopeFound == false)
                    microscopeList{microscopeIndex} = currentMicroscope;
                    microscopeIndex = microscopeIndex + 1;
                end

                if (experimentFound == false)
                    micronsPerPixel{experimentIndex} = '1.0';
                    channelFilter{experimentIndex} = '';
                    experimentList{experimentIndex} = currentExperiment;
                    experimentIndex = experimentIndex + 1;
                end

                if (positionFound == false)
                    positionList{positionIndex} = currentPosition;
                    positionIndex = positionIndex + 1;
                end

                %% add file separator at the end of each folder
                if (inputFolders{currentFolderIndex}(end) ~= '/')
                    inputFolders{currentFolderIndex} = [inputFolders{currentFolderIndex} '/']; %#ok<AGROW> 
                end

                %% display status and increment index for the next folder
                disp(['Added folder ' inputFolders{currentFolderIndex} ' to the input list.']);
                currentFolderIndex = currentFolderIndex + 1;
            end
        end
    end
end