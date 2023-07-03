function positionFolder = callback_livecellminer_find_position_folder(projectRoot, microscopeName, experimentName, positionName)


    projectRoot = strrep(projectRoot, '\', '/');

    containsMicroscopeFolder = isfolder([projectRoot microscopeName filesep]);

    if (containsMicroscopeFolder)
        containsProjectFolder = isfolder([projectRoot microscopeName filesep experimentName filesep]);
    else
        containsProjectFolder = isfolder([projectRoot experimentName filesep]);
    end

    positionFolder = projectRoot;

    if (containsMicroscopeFolder)
        positionFolder = [positionFolder microscopeName filesep];
    end

    if (containsProjectFolder)
        positionFolder = [positionFolder experimentName filesep];
    end

    positionFolder = [positionFolder positionName filesep];

    if (~isfolder(positionFolder))
        fprintf('Error: position was not found at the location %s, please double-check folder structure!', positionFolder);
        positionFolder = -1;
    end
end