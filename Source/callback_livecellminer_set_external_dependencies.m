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

function [XPIWITPath, ULTRACKPath] = callback_livecellminer_set_external_dependencies()

    %% specify the default settings file
    currentFileDir = fileparts(mfilename('fullpath'));
    settingsFile = [currentFileDir filesep 'externalDependencies.txt'];
    
    %% load previous path if it exists, otherwise set default paths to have an idea how the paths should be specified.
    previousPathsLoaded = false;
    if (exist(settingsFile, 'file'))
        fileHandle = fopen(settingsFile, 'r');
        currentLine = fgets(fileHandle);
        
        if (currentLine > 0)
            splitString = strsplit(currentLine, ';');
            XPIWITPath = splitString{1};
            ULTRACKPath = splitString{2};
            fclose(fileHandle);
            previousPathsLoaded = true;
        end
    end
    
    %% show some example paths if no previous paths exist
    if (previousPathsLoaded == false)
        XPIWITPath = 'D:/Programming/XPIWIT/Release/2019/XPIWIT_Windows_x64/Bin/';
        ULTRACKPath = 'C:/Environments/ultrack/python.exe';
    end

    questionDlgText = sprintf('Current external dependencies set to \n\n XPIWITPath = %s \n\n ULTRACKPath = %s', XPIWITPath, ULTRACKPath);
    
    answer = questdlg(questionDlgText, ...
	    'External Dependencies', ...
	    'Ok','Reset','Cancel','Ok');

    % Handle response
    switch answer
        case 'Ok'
            return;
        case 'Reset'
            msgBoxHandle = msgbox('Please select the Bin folder of your XPIWIT installation that contains the XPIWIT.sh (Unix) or XPIWIT.exe (Windows).');
            waitfor(msgBoxHandle);
        
        
            XPIWITPath = uigetdir(XPIWITPath, 'Wrong XPIWIT path provided - please try again and specify path to the Bin folder that contains the XPIWIT(.exe).');
            XPIWITPath = strrep(XPIWITPath, '\', '/');
            if (XPIWITPath(end) ~= '/'); XPIWITPath = [XPIWITPath '/']; end
        
            msgBoxHandle = msgbox('Please select the python executable of the Ultrack environment (e.g., C:/Environments/ultrack/python.exe (Windows) or /opt/anaconda3/envs/ultrack (Unix))');
            waitfor(msgBoxHandle);
        
            ULTRACKPath = uigetdir(ULTRACKPath, 'Wrong information provided - please try again and specify folders for the XPIWIT and the path to the python.exe (Windows) or python executable (Unix) of the Ultrack environment.');
            ULTRACKPath = strrep(ULTRACKPath, '\', '/');
            ULTRACKPath = [ULTRACKPath 'python'];
            if (ispc)
                ULTRACKPath = [ULTRACKPath '.exe'];
            end
            
            %% write the new path to disk
            if (isfolder(XPIWITPath) && isfile(ULTRACKPath))
                fileHandle = fopen(settingsFile, 'wb');
                fprintf(fileHandle, '%s;%s;%s', XPIWITPath, ULTRACKPath);
                fclose(fileHandle);
            else
                disp('Wrong information provided - please try again and specify folders for the XPIWIT and the path to the python.exe (Windows) or python executable (Unix) of the Ultrack environment.');
            end
        case 'Cancel'
            return;
    end
end