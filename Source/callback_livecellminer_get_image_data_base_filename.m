function imageDatabaseFilename = callback_livecellminer_get_image_data_base_filename(cellID, parameter, code_alle, zgf_y_bez, bez_code)

    experimentOutputVariable = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
    positionOutputVariable = callback_livecellminer_find_output_variable(bez_code, 'Position');

    currentProjectID = code_alle(cellID, experimentOutputVariable);
    currentPositionID = code_alle(cellID, positionOutputVariable);
    experimentName = zgf_y_bez(experimentOutputVariable, currentProjectID).name;
    positionName = zgf_y_bez(positionOutputVariable, currentPositionID).name;

    imageDatabaseFilename = [parameter.projekt.pfad filesep];
    positionFolder = callback_livecellminer_find_position_folder(imageDatabaseFilename, experimentName, positionName);

    imageDatabaseFilename = [positionFolder experimentName '_' positionName  '_ImageData.h5'];
end