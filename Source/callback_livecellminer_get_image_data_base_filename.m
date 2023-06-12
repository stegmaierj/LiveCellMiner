function imageDatabaseFilename = callback_livecellminer_get_image_data_base_filename(cellID, parameter, code_alle, zgf_y_bez, bez_code)

    currentProjectID = code_alle(cellID, callback_livecellminer_find_output_variable(bez_code, 'Experiment'));
    currentPositionID = code_alle(cellID, callback_livecellminer_find_output_variable(bez_code, 'Position'));
    experimentName = zgf_y_bez(3,currentProjectID).name;
    positionName = zgf_y_bez(4,currentPositionID).name;

    imageDatabaseFilename = [parameter.projekt.pfad filesep experimentName filesep positionName filesep experimentName '_' positionName  '_ImageData.h5'];

end