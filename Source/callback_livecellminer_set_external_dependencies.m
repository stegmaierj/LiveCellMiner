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

function [XPIWITPath, ULTRACKPath, CELLPOSEPath] = callback_livecellminer_set_external_dependencies()

    %% specify the default settings file
    currentFileDir = fileparts(mfilename('fullpath'));
    settingsFile = [currentFileDir filesep 'externalDependencies.txt'];

    XPIWITPath = '';
    ULTRACKPath = '';
    CELLPOSEPath = '';
    
    %% load previous path if it exists, otherwise set default paths to have an idea how the paths should be specified.
    previousPathsLoaded = false;
    if (exist(settingsFile, 'file'))
        fileHandle = fopen(settingsFile, 'r');
        currentLine = fgets(fileHandle);
        
        if (currentLine > 0)
            splitString = strsplit(currentLine, ';');
            
            if (~isempty(splitString))
                XPIWITPath = splitString{1};
            end
            
            if (length(splitString) > 1)
                ULTRACKPath = splitString{2};
            end

            if (length(splitString) > 2)
                CELLPOSEPath = splitString{3};
            end
            fclose(fileHandle);
            previousPathsLoaded = true;
        end
    end
    
    %% show some example paths if no previous paths exist
    if (previousPathsLoaded == false)
        if (ispc)
            XPIWITPath = 'D:/Programming/XPIWIT/Release/2019/XPIWIT_Windows_x64/Bin/XPIWIT.exe';
            ULTRACKPath = 'C:/Environments/ultrack/python.exe';
            CELLPOSEPath = 'C:/Environments/cellpose/python.exe';
        else
            XPIWITPath = '/Users/myusername/Programming/XPIWIT/Bin/XPIWIT.sh';
            ULTRACKPath = '/opt/anaconda3/envs/ultrack/bin/python';
            CELLPOSEPath = '/opt/anaconda3/envs/cellpose/bin/python';
        end
    end

    dependenciesOK = false;

    while ~dependenciesOK
        questionDlgText = sprintf('Current external dependencies set to \n\n XPIWITPath = %s \n\n ULTRACKPath = %s \n\n CELLPOSEPath = %s', XPIWITPath, ULTRACKPath, CELLPOSEPath);
        
        answer = questdlg(questionDlgText, ...
	        'External Dependencies', ...
	        'Reset XPIWIT', 'Reset Ultrack', 'Reset Cellpose', 'Ok');

        if (isempty(answer))
            dependenciesOK = true;
            continue;
        end
    
        % Handle response
        switch answer
            case 'Reset XPIWIT'
                msgBoxHandle = msgbox('Please select the XPIWIT executable (XPIWIT.sh (Unix) or XPIWIT.exe (Windows)).');
                waitfor(msgBoxHandle);
            
            
                [XPIWITFile, XPIWITFolder] = uigetfile({'*'}, XPIWITPath, 'Wrong XPIWIT path provided - please try again and select the XPIWIT executable (XPIWIT.sh (Unix) or XPIWIT.exe (Windows)).');
                XPIWITPath = [XPIWITFolder XPIWITFile];
                XPIWITPath = strrep(XPIWITPath, '\', '/');
    
            case 'Reset Ultrack'
                msgBoxHandle = msgbox('Please select the python executable of the Ultrack environment (e.g., C:/Environments/ultrack/python.exe (Windows) or /opt/anaconda3/envs/ultrack/bin/python (Unix))');
                waitfor(msgBoxHandle);
            
                [ULTRACKFile, ULTRACKFolder] = uigetfile({'*'}, ULTRACKPath, 'Please select the python executable of the Ultrack environment (e.g., C:/Environments/ultrack/python.exe (Windows) or /opt/anaconda3/envs/ultrack/bin/python (Unix))');
                ULTRACKPath = [ULTRACKFolder ULTRACKFile];
                ULTRACKPath = strrep(ULTRACKPath, '\', '/');

            case 'Reset Cellpose'
                msgBoxHandle = msgbox('Please select the python executable of the Cellpose environment (e.g., C:/Environments/cellpose/python.exe (Windows) or /opt/anaconda3/envs/cellpose/bin/python (Unix))');
                waitfor(msgBoxHandle);
            
                [CELLPOSEFile, CELLPOSEFolder] = uigetfile({'*'}, CELLPOSEPath, 'Please select the python executable of the Cellpose environment (e.g., C:/Environments/cellpose/python.exe (Windows) or /opt/anaconda3/envs/cellpose/bin/python (Unix))');
                CELLPOSEPath = [CELLPOSEFolder CELLPOSEFile];
                CELLPOSEPath = strrep(CELLPOSEPath, '\', '/');
        end
    end

    %% write the new path to disk
    if (isfile(XPIWITPath) && isfile(ULTRACKPath))
        fileHandle = fopen(settingsFile, 'wb');
        fprintf(fileHandle, '%s;%s;%s', XPIWITPath, ULTRACKPath, CELLPOSEPath);
        fclose(fileHandle);
    else
        disp('Wrong information provided - please try again and specify folders for the XPIWIT and the path to the python.exe (Windows) or python executable (Unix) of the Ultrack and Cellpose environments.');
    end
end