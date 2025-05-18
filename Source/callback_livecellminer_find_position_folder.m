function positionFolder = callback_livecellminer_find_position_folder(projectRoot, experimentName, positionName)


    projectRoot = strrep(projectRoot, '\', '/');

    containsProjectFolder = isfolder([projectRoot experimentName filesep]);

    positionFolder = projectRoot;

    if (containsProjectFolder)
        positionFolder = [positionFolder experimentName filesep];
    end

    positionFolder = [positionFolder positionName filesep];
    positionFolder = strrep(positionFolder, '\', '/');

    if (~isfolder(positionFolder))
        fprintf('Error: position was not found at the location %s, please double-check folder structure!', positionFolder);
        positionFolder = -1;
    end
end