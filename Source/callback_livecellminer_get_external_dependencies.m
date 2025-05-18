
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
        CELLPOSEEnvironment = splitString{2};
        fclose(fileHandle);
        previousPathsLoaded = true;
    end
else
    callback_livecellminer_set_external_dependencies;
end