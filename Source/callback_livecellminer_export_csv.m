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

%% ask which part of the data should be exported
answer = questdlg('Would you like to export time series or single features?', ...
	'Export Selection', ...
	'Time Series (TS)','Single Features (SF)', 'Cancel', 'Cancel');

%% get the output directory
outputDirectory = uigetdir();

%% get the selected indices
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');

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
        fileID = fopen([outputDirectory filesep featureName '_' datestr(now,'YYYY_mm_DD_HH_MM_SS') '.csv'], 'wb');

        %% create the specifier string for the first line
        outputVariables = '';
        for j=1:size(bez_code,1)
            outputVariables = [outputVariables kill_lz(bez_code(j,:)) ';' ];
        end

        %% print the specifiers
        fprintf(fileID, '%s%s\n', outputVariables, relativeFrameNumbers);

        %% export values of all selected cells
        for j=1:length(validIndices)

            currentOutputVariables = [];
            for k=1:size(bez_code,1)
                currentOutputVariables = [currentOutputVariables zgf_y_bez(k,code_alle(validIndices(j),k)).name ';' ];
            end

            fprintf(fileID, '%s%s\n', currentOutputVariables, num2str(currentHeatMap(j,:), '%.2f;'));
        end

        %% close the file handle
        fclose(fileID);
    end

%% export single features
elseif (strcmp(answer, 'Single Features (SF)'))

    %% construct the output file name
    fileID = fopen([outputDirectory filesep 'SingleFeatures' '_' datestr(now,'YYYY_mm_DD_HH_MM_SS') '.csv'], 'wb');

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

    %% export values of all selected cells
    for j=validIndices'

        currentOutputVariables = [];
        for k=1:size(bez_code,1)
            currentOutputVariables = [currentOutputVariables zgf_y_bez(k,code_alle(j,k)).name ';' ];
        end

        fprintf(fileID, '%s%s\n', currentOutputVariables, num2str(d_org(j,parameter.gui.merkmale_und_klassen.ind_em), '%.2f;'));
    end

    %% close the file handle
    fclose(fileID);

else
    disp('Nothing selected for export, skipping ...');
end
