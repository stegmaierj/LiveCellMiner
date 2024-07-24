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

%% specify the default settings file
settingsFile = [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'externalDependencies.txt'];

%% load previous path if it exists, otherwise set default paths to have an idea how the paths should be specified.
previousPathsLoaded = false;
if (exist(settingsFile, 'file'))
    fileHandle = fopen(settingsFile, 'r');
    currentLine = fgets(fileHandle);
    
    if (currentLine > 0)
        splitString = strsplit(currentLine, ';');
        XPIWITPath = splitString{1};
        CELLPOSEEnvironment = splitString{2};
        fclose(fileHandle);
        previousPathsLoaded = true;
    end
end

%% show some example paths if no previous paths exist
if (previousPathsLoaded == false)
    XPIWITPath = 'D:/Programming/XPIWIT/Release/2019/XPIWIT_Windows_x64/Bin/';
    CELLPOSEEnvironment = 'C:/Environments/cellpose/python.exe';
end

%% open input dialog for setting the paths
prompt = {'XPIWIT Path:', 'Cellpose Environment:'};
dlgtitle = 'Paths to External Dependencies';
dims = [1 100];
definput = {XPIWITPath, CELLPOSEEnvironment};
answer = inputdlg(prompt,dlgtitle,dims,definput);

%% write the new path to disk
if (~isempty(answer))
    
    XPIWITPath = strrep(answer{1}, '\', '/');
    if (XPIWITPath(end) ~= '/'); XPIWITPath = [XPIWITPath '/']; end

    if (~isfolder(answer{1}))
        disp('Wrong XPIWIT path provided - please try again and specify path to the Bin folder that contains the XPIWIT(.exe).');
    end
        
    CELLPOSEEnvironment = answer{2};

    if (~isfile(answer{2}))
        disp('Wrong cellpose environment provided - please try again and specify path to the python(.exe) of the Cellpose environment.');
    end

    fileHandle = fopen(settingsFile, 'wb');
    fprintf(fileHandle, '%s;%s;%s', XPIWITPath, CELLPOSEEnvironment);
    fclose(fileHandle);
else
    disp('Wrong information provided - please try again and specify folders for the XPIWIT and Cellpose paths and the path to the python.exe of the Cellpose environment.');
end
