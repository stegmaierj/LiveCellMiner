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

function [] = callback_livecellminer_show_combined_plots(parameter, d_orgs, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, visualizationMode, createNewFigure)

%% get the parameters from the GUI
IPTransition = parameter.gui.livecellminer.IPTransition;
MATransition = parameter.gui.livecellminer.MATransition;
alignedLength = parameter.gui.livecellminer.alignedLength;
alignPlots = parameter.gui.livecellminer.alignPlots;
errorStep = parameter.gui.livecellminer.errorStep;
showErrorBars = parameter.gui.livecellminer.showErrorBars;
darkMode = parameter.gui.livecellminer.darkMode;
summarizeSelectedExperiments = parameter.gui.livecellminer.summarizeSelectedExperiments;

%% set visualization mode
if (~exist('createNewFigure', 'var'))
    createNewFigure = true;
end

%% set visualization mode
if (~exist('visualizationMode', 'var'))
    visualizationMode = 2;
end
timeRange = parameter.gui.zeitreihen.segment_start:parameter.gui.zeitreihen.segment_ende;

%% get the selected cells
selectedCells = ind_auswahl;

%% find the manual synchronization index
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

if (synchronizationIndex == 0)
    msgbox('For aligned plotting, synchronization information is needed. Please perform synchronization first, e.g., using "Align -> Perform Auto Sync"');
    return;
end

%% identify the contained features, experiments and positions
experimentId = callback_livecellminer_find_output_variable(bez_code, parameter.gui.livecellminer.summaryOutputVariable);
selectedExperiments = unique(code_alle(selectedCells, experimentId));
selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
selectedPositionsOrOligos = unique(code_alle(selectedCells, selectedOutputVariable));
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;

%% compute the number of required subplots
numSubPlots = 1;
if (summarizeSelectedExperiments == false)
    numSubPlots = numSubPlots * length(selectedExperiments);
end
[numRows, numColumns] = compute_subplot_layout(numSubPlots);

%% specify the color map and the line styles
colorMap = callback_livecellminer_get_colormap(parameter.gui.livecellminer.colorMap, length(selectedPositionsOrOligos), parameter);
lineStyles = {'-', '-', '-', '-', '--', ':', '-.'};

%% box plots
dataPoints = [];
grouping = [];

%% plot separate figures for each feature
for featureIndex = generate_rowvector(selectedFeatures)
    
    if (parameter.gui.livecellminer.darkMode == true)
        colordef black;
        markerColor = 'w';
    else
        markerColor = 'k';
        colordef white;
    end
    
    %% open new figure and initialize it with the selected color mode
    if (createNewFigure == true)
        fh = figure; clf; hold on;
    else
        fh = gcf;
    end
    
    if (parameter.gui.livecellminer.darkMode == true)
        set(fh, 'color', 'black');
    else
        set(fh, 'color', 'white');
    end
    set(fh, 'Units','normalized', 'OuterPosition', [0,0,1,1]);
    
    %% summarize the results of each position either as a heat map, box plots or line plots
    minValue = inf;
    maxValue = -inf;
    
    currentLegend = char();
    currentSubPlot = 1;
    
    if (summarizeSelectedExperiments == false)
        for e=generate_rowvector(selectedExperiments)
            
            if (createNewFigure == true)
                subplot(numRows, numColumns, currentSubPlot); hold on;
            end
            
            %% plot dummy lines for the proper visualization of the legend
            for i=1:length(selectedPositionsOrOligos)
                if (visualizationMode == 1)
                    plot([1,1], [1, 1], '-r', 'Color', colorMap(i, :));
                else
                    plot([1,1], [1, 1], lineStyles{mod(i, 4)+1}, 'Color', colorMap(i, :));
                end
            end
            
            currentCodeValue = 1;
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
                
                compute_combined_plots;
                currentCodeValue = currentCodeValue + 1;
            end
            
            %% add legends to the figures
            legend(currentLegend);
            set(gca, 'YLim', [minValue, maxValue]);
            
            title(strrep(zgf_y_bez(experimentId,e).name, '_', '\_'));
            ylabel(strrep(kill_lz(var_bez(featureIndex,:)), '_', '\_'));
            
            %% increment subplot counter
            currentSubPlot = currentSubPlot + 1;
        end
    else
        
        %% plot dummy lines for the proper visualization of the legend
        for i=1:length(selectedPositionsOrOligos)
            if (visualizationMode == 1)
                plot([1,1], [1, 1], '-r', 'Color', colorMap(i, :));
            else
                plot([1,1], [1, 1], lineStyles{mod(i, 4)+1}, 'Color', colorMap(i, :));
            end
        end
        
        currentCodeValue = 1;
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
            
            compute_combined_plots;
            
            %% increment subplot counter
            currentCodeValue = currentCodeValue + 1;
        end
        
        legend(currentLegend);
        set(gca, 'YLim', [minValue, maxValue]);
        title('Combined Experiments');
        ylabel(strrep(kill_lz(var_bez(featureIndex,:)), '_', '\_'));
    end
   
    if (createNewFigure == true)
        if (numSubPlots > 1)
            for i=1:numSubPlots
                subplot(numRows, numColumns, i); hold on;
                set(gca, 'YLim', [minValue, maxValue]);
            end
        end
    end

    %% adapt labels and font size of all axes
    callback_livecellminer_beautify_plots;
end

colordef white;
end