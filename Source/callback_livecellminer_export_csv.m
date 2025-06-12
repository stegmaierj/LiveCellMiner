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

%% get the export selection stored in variable "ind_auswahl"
callback_livecellminer_get_export_selection;

%% ask which part of the data should be exported
answer = questdlg('Would you like to export time series or single features?', ...
	'Export Selection', ...
	'Time Series (TS)','Single Features (SF)', 'Cancel', 'Cancel');

%% get the output directory
outputDirectory = uigetdir();

%% get the selected indices
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
selectedOutputVariable = parameter.gui.merkmale_und_klassen.ausgangsgroesse;
selectedOutputVariableName = kill_lz(bez_code(selectedOutputVariable, :));

%% get stage transitions
if (synchronizationIndex > 0)
    stageTransitions = squeeze(d_orgs(ind_auswahl, 1, synchronizationIndex)) > 0;
    validIndices = ind_auswahl(stageTransitions);
else
    validIndices = ind_auswahl;
    disp('Data set was not synchronized yet, exporting unaligned time series!');
end

%% handle time series processing
if (strcmp(answer, 'Time Series (TS)'))

    %% export tiem series separately
    for f=parameter.gui.merkmale_und_klassen.ind_zr

        %% get the current heat map
        if (synchronizationIndex > 0)
            currentHeatMap = callback_livecellminer_compute_aligned_heatmap(d_orgs, validIndices, synchronizationIndex, f, parameter);
            IPTransition = parameter.gui.livecellminer.IPTransition;
            MATransition = parameter.gui.livecellminer.MATransition;
            alignedLength = parameter.gui.livecellminer.alignedLength;
            relativeFrameNumbers = callback_livecellminer_get_relative_frame_numbers(IPTransition, MATransition, alignedLength, 1);
            relativeFrameNumbers = num2str(relativeFrameNumbers(2:end), '%i;');
        else
            currentHeatMap = squeeze(d_orgs(validIndices, :, f));
            relativeFrameNumbers = num2str(1:size(d_orgs,2), '%i;');
        end

        %% construct the output file name
        featureName = kill_lz(var_bez(f, :));
        fileID = fopen([outputDirectory filesep featureName '_' datestr(now,'YYYY_mm_DD_HH_MM_SS') '_SingleCells.csv'], 'wb');
        fileIDCombined = fopen([outputDirectory filesep featureName '_' datestr(now,'YYYY_mm_DD_HH_MM_SS') '_GroupedCells_' selectedOutputVariableName '.csv'], 'wb');

        %% create the specifier string for the first line
        outputVariables = '';
        for j=1:size(bez_code,1)
            outputVariables = [outputVariables kill_lz(bez_code(j,:)) ';' ];
        end

        %% print the specifiers
        fprintf(fileID, '%s%s\n', outputVariables, relativeFrameNumbers);
        fprintf(fileIDCombined, '%s%s%s\n', strrep(outputVariables, 'Cell;', '#Cells;'), 'Metric;', relativeFrameNumbers);

        %% export values of all selected cells
        for j=1:length(validIndices)

            currentOutputVariables = [];
            for k=1:size(bez_code,1)
                currentOutputVariables = [currentOutputVariables zgf_y_bez(k,code_alle(validIndices(j),k)).name ';' ];
            end

            fprintf(fileID, '%s%s\n', currentOutputVariables, num2str(currentHeatMap(j,:), '%.2f;'));
        end

        %% export combined values for the current output variable
        for j=unique(code_alle(validIndices, selectedOutputVariable))'

            currentIndices = find(code_alle(validIndices, selectedOutputVariable) == j);

            meanValues = nanmean(currentHeatMap(currentIndices,:));
            stdValues = nanstd(currentHeatMap(currentIndices,:));

            currentOutputVariables = [];
            for k=1:size(bez_code,1)

                %numCodeValues = length(unique(code_alle(validIndices(currentIndices),k)));
                codeValues = unique(code_alle(validIndices(currentIndices),k));
                numCodeValues = length(codeValues);

                codeStrings = [];
                for l=codeValues'
                    codeStrings = [codeStrings zgf_y_bez(k,l).name];
    
                    if (l ~= codeValues(end))
                        codeStrings = [codeStrings ', '];
                    end
                end
                    
                if (strcmp(kill_lz(bez_code(k,:)), 'Cell'))
                    currentOutputVariables = [currentOutputVariables num2str(length(currentIndices)) ';' ];
                else
                    currentOutputVariables = [currentOutputVariables codeStrings ';' ];
                end
            end

            fprintf(fileIDCombined, '%s%s%s\n', currentOutputVariables, 'Mean;', num2str(meanValues, '%.2f;'));
            fprintf(fileIDCombined, '%s%s%s\n', currentOutputVariables, 'Std;', num2str(stdValues, '%.2f;'));
        end

        %% close the file handle
        fclose(fileID);
        fclose(fileIDCombined);
    end

%% export single features
elseif (strcmp(answer, 'Single Features (SF)'))

    %% construct the output file name
    fileID = fopen([outputDirectory filesep 'SingleFeatures' '_' datestr(now,'YYYY_mm_DD_HH_MM_SS') '_SingleCells.csv'], 'wb');
    fileIDCombined = fopen([outputDirectory filesep 'SingleFeatures' '_' datestr(now,'YYYY_mm_DD_HH_MM_SS') '_GroupedCells_' selectedOutputVariableName '.csv'], 'wb');

    %% create the specifier string for the first line
    outputVariables = '';
    for j=1:size(bez_code,1)
        outputVariables = [outputVariables kill_lz(bez_code(j,:)) ';' ];
    end

    featureNames = '';
    for j=parameter.gui.merkmale_und_klassen.ind_em
        featureNames = [featureNames kill_lz(dorgbez(j,:)), ';'];
    end

    %% print the specifiers
    fprintf(fileID, '%s%s\n', outputVariables, featureNames);
    fprintf(fileIDCombined, '%s%s%s\n', strrep(outputVariables, 'Cell;', '#Cells;'), 'Metric;', featureNames);

    %% export values of all selected cells
    for j=validIndices'

        currentOutputVariables = [];
        for k=1:size(bez_code,1)
            currentOutputVariables = [currentOutputVariables zgf_y_bez(k,code_alle(j,k)).name ';' ];
        end

        fprintf(fileID, '%s%s\n', currentOutputVariables, num2str(d_org(j,parameter.gui.merkmale_und_klassen.ind_em), '%.2f;'));
    end

    %% export combined values for the current output variable
    for j=unique(code_alle(validIndices, selectedOutputVariable))'

        currentIndices = validIndices(code_alle(validIndices, selectedOutputVariable) == j);

        meanValues = nanmean(d_org(currentIndices,parameter.gui.merkmale_und_klassen.ind_em));
        stdValues = nanstd(d_org(currentIndices,parameter.gui.merkmale_und_klassen.ind_em));

        currentOutputVariables = [];
        for k=1:size(bez_code,1)

            codeValues = unique(code_alle(currentIndices,k));
            numCodeValues = length(codeValues);

            codeStrings = [];
            for l=codeValues'
                codeStrings = [codeStrings zgf_y_bez(k,l).name];

                if (l ~= codeValues(end))
                    codeStrings = [codeStrings ', '];
                end
            end


            if (strcmp(kill_lz(bez_code(k,:)), 'Cell'))
                currentOutputVariables = [currentOutputVariables num2str(length(currentIndices)) ';' ];
            else
                currentOutputVariables = [currentOutputVariables codeStrings ';' ];
            end
        end

        fprintf(fileIDCombined, '%s%s%s\n', currentOutputVariables, 'Mean;', num2str(meanValues, '%.2f;'));
        fprintf(fileIDCombined, '%s%s%s\n', currentOutputVariables, 'Std;', num2str(stdValues, '%.2f;'));
    end

    %% close the file handle
    fclose(fileID);
    fclose(fileIDCombined);

else
    disp('Nothing selected for export, skipping ...');
end
