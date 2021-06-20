%%
% LiveCellMiner.
% Copyright (C) 2020 D. Moreno-Andres, A. Bhattacharyya, W. Antonin, J. Stegmaier
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
% TBA
%
%%

function [] = callback_livecellminer_show_heatmaps(parameter, d_orgs, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, visualizationMode)

    %% get the parameters from the GUI
    IPTransition = parameter.gui.livecellminer.IPTransition;
    MATransition = parameter.gui.livecellminer.MATransition;
    alignedLength = parameter.gui.livecellminer.alignedLength;
    timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;

    darkMode = parameter.gui.livecellminer.darkMode;
    alignPlots = parameter.gui.livecellminer.alignPlots;
    errorStep = parameter.gui.livecellminer.errorStep;
    showErrorBars = parameter.gui.livecellminer.showErrorBars;
    summarizeSelectedExperiments = parameter.gui.livecellminer.summarizeSelectedExperiments;

    %% set visualization mode
    if (~exist('visualizationMode', 'var'))
        visualizationMode = 2;
    end

    %% get the selected cells
    selectedCells = ind_auswahl;

    synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
    if (synchronizationIndex <= 0 && parameter.gui.livecellminer.alignPlots)
        disp('Please synchronize the data sets first, e.g., by running "LiveCellMiner -> Align -> Perform Auto Sync".');
        return;
    end

    %% identify the contained features, experiments and positions
    experimentId = callback_livecellminer_find_output_variable(bez_code, parameter.gui.livecellminer.summaryOutputVariable);
    selectedExperiments = unique(code_alle(selectedCells, experimentId));
    selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
    selectedPositionsOrOligos = unique(code_alle(selectedCells, selectedOutputVariable));
    selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;

    %% compute the number of required subplots
    numSubPlots = 0;
    for p=generate_rowvector(selectedPositionsOrOligos)
        validIndices = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == p));

        if (isempty(validIndices))
            continue;
        end

        numSubPlots = numSubPlots + 1;
    end

    if (summarizeSelectedExperiments == false)
        numSubPlots = numSubPlots * length(selectedExperiments);
    end
    [numRows, numColumns] = compute_subplot_layout(numSubPlots);

    %% plot separate figures for each feature
    for featureIndex = generate_rowvector(selectedFeatures)

        %% open new figure and initialize it to black background
        fh = figure; clf;

        if (darkMode == true)
            colordef black; %#ok<COLORDEF>
            set(fh, 'color', 'black');
        else
            colordef white; %#ok<COLORDEF>
            set(fh, 'color', 'white');
        end

        %% summarize the results of each position either as a heat map, box plots or line plots
        minValue = inf;
        maxValue = -inf;

        currentSubPlot = 1;

        if (summarizeSelectedExperiments == false)
            for e=generate_rowvector(selectedExperiments)
                for p=generate_rowvector(selectedPositionsOrOligos)

                    %% get stage transitions
                    if (synchronizationIndex > 0 && alignPlots == true)
                        stageTransitions = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) >= 0;
                    end

                    %% get the valid cells for the current combination of experiment and position
                    if (synchronizationIndex == 0 || alignPlots == false)
                        validIndices = ind_auswahl(find(code_alle(ind_auswahl, experimentId) == e & code_alle(ind_auswahl, selectedOutputVariable) == p));
                    else
                        validIndices = ind_auswahl(find(code_alle(ind_auswahl, experimentId) == e & code_alle(ind_auswahl, selectedOutputVariable) == p & stageTransitions));
                    end

                    %% continue if no valid cells are present in this combination
                    if (isempty(validIndices))
                        continue;
                    end

                    compute_individual_plots;

                    %% increment subplot counter
                    currentSubPlot = currentSubPlot + 1;
                end
            end
        else
            for p=generate_rowvector(selectedPositionsOrOligos)

                %% get stage transitions
                if (synchronizationIndex > 0 && alignPlots == true)
                    stageTransitions = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) >= 0;
                end

                %% get the valid cells for the current combination of experiment and position
                if (synchronizationIndex == 0 || alignPlots == false)
                    validIndices = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == p));
                else
                    validIndices = ind_auswahl(find(code_alle(ind_auswahl, selectedOutputVariable) == p & stageTransitions));
                end

                %% continue if no valid cells are present in this combination
                if (isempty(validIndices))
                    continue;
                end

                compute_individual_plots;

                %% increment subplot counter
                currentSubPlot = currentSubPlot + 1;
            end
        end

        for i=1:(numRows*numColumns)
            subplot(numRows, numColumns, i);

            if (visualizationMode == 1)
                caxis([minValue, maxValue]);
                set(gca, 'YLim', [0, size(currentHeatMap, 1)]);
            else
                set(gca, 'YLim', [minValue, maxValue]);
            end

            %% optionally adjust x-axis with IP and MA relative frame numbers
            if (parameter.gui.livecellminer.relativeFrameNumbers)
                callback_livecellminer_relative_frame_numbers;
            end
        end
    end

    colordef white; %#ok<COLORDEF>
end