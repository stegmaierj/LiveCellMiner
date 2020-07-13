global parameters;
parameters.currentIdRange = parameters.currentIdRange + parameters.numVisualizedCells;

if (max(parameters.currentIdRange) > length(parameters.selectedCells))
    parameters.currentIdRange = (length(parameters.selectedCells) - parameters.numVisualizedCells+1):length(parameters.selectedCells);
    disp('Reached end of the selected cells. Select either more cells to proceed or stop annotating here...');
end

parameters.currentCells = parameters.selectedCells(parameters.currentIdRange);
parameters.dirtyFlag = true;
callback_chromatindec_update_visualization;