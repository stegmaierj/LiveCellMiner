function imageDatabaseFilename = callback_livecellminer_get_image_data_base_filename(cellID, parameter, code_alle, zgf_y_bez, bez_code)

    currentMicroscopeID = code_alle(cellID, callback_livecellminer_find_output_variable(bez_code, 'Microscope'));
    currentProjectID = code_alle(cellID, callback_livecellminer_find_output_variable(bez_code, 'Experiment'));
    currentPositionID = code_alle(cellID, callback_livecellminer_find_output_variable(bez_code, 'Position'));
    microscopeName = zgf_y_bez(2,currentMicroscopeID).name;
    experimentName = zgf_y_bez(3,currentProjectID).name;
    positionName = zgf_y_bez(4,currentPositionID).name;

    imageDatabaseFilename = [parameter.projekt.pfad filesep];
    positionFolder = callback_livecellminer_find_position_folder(imageDatabaseFilename, microscopeName, experimentName, positionName);

    imageDatabaseFilename = [positionFolder experimentName '_' positionName  '_ImageData.h5'];
end