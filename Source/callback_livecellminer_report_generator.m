%%
% LiveCellMiner.
% Copyright (C) 2021 D. Moreno-Andrés, A. Bhattacharyya, W. Antonin, J. Stegmaier
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

%% identify single features, time series and cells to plot
selectedTimeSeries = parameter.gui.merkmale_und_klassen.ind_zr;
selectedSingleFeatures = parameter.gui.merkmale_und_klassen.ind_em;
syncIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
timeSeriesNames = var_bez(selectedTimeSeries, :);
singleFeatureNames = dorgbez(selectedSingleFeatures, :);
averageInterval = 2;

%% get number of features/time series/objects
selectedCells = ind_auswahl;
numCells = length(ind_auswahl);
numTimeSeries = length(selectedTimeSeries);
numSingleFeatures = length(selectedSingleFeatures);

%% specify output folders
outputFolder = [parameter.projekt.pfad filesep 'Report/'];
outputFolderPlots = [outputFolder 'Plots/'];
outputReportFile = [outputFolder parameter.projekt.datei '_FeatureReport.htm'];
if (~isfolder(outputFolder)); mkdir(outputFolder); end
if (~isfolder(outputFolderPlots)); mkdir(outputFolderPlots); end

%% initialize single feature statistics
singleFeatureStatistics = zeros(length(selectedSingleFeatures), 5); %% min, max, mean, median, std, n-fold increase

%% loop through all selected single features
for f=1:numSingleFeatures
    
    %% get current single feature values
    currentFeature = selectedSingleFeatures(f);
    currentValues = d_org(ind_auswahl, currentFeature);

    %% identify invalid cells
    deletionIndices = [];
    for i=1:numCells
        currentCell = selectedCells(i);
        if (min(squeeze(d_orgs(currentCell, :, syncIndex))) <= 0)
            deletionIndices = [deletionIndices, i]; %#ok<AGROW>
            continue;
        end
    end
    
    %% exclude invalid cells from the statistics
    currentValues(deletionIndices, :) = [];
    
    %% compute stats
    singleFeatureStatistics(f, 1) = min(currentValues);
    singleFeatureStatistics(f, 2) = max(currentValues);
    singleFeatureStatistics(f, 3) = mean(currentValues);
    singleFeatureStatistics(f, 4) = std(currentValues);
    singleFeatureStatistics(f, 5) = median(currentValues);
    
    %% select only current feature for plotting
    selectedSingleFeaturesOld = parameter.gui.merkmale_und_klassen.ind_em;
    parameter.gui.merkmale_und_klassen.ind_em = currentFeature;
        
    %% plot combined line plot
    showHistogram = false; showViolinPlots = true; callback_livecellminer_show_combined_boxplots(parameter, d_org, d_orgs, dorgbez, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, showHistogram, showViolinPlots);
    figureHandle = gcf;
    currentImage = frame2im(getframe(figureHandle));
    imwrite(currentImage, [outputFolderPlots parameter.projekt.datei '_' kill_lz(singleFeatureNames(f,:)) '_BoxPlots.png']);
    close(figureHandle);
    
    %% plot combined heatmap plot
    showHistogram = true; callback_livecellminer_show_combined_boxplots(parameter, d_org, d_orgs, dorgbez, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, showHistogram);
    figureHandle = gcf;
    currentImage = frame2im(getframe(figureHandle));
    imwrite(currentImage, [outputFolderPlots parameter.projekt.datei '_' kill_lz(singleFeatureNames(f,:)) '_Histograms.png']);
    close(figureHandle);
    
    %% reset the single feature selection    
    parameter.gui.merkmale_und_klassen.ind_em = selectedSingleFeaturesOld;
    selectedSingleFeatures = selectedSingleFeaturesOld;
end


%% initialize time series statistics
numClasses = length(unique(code));
numStatistics = 7;
if (numClasses > 1)
    numStatistics = numStatistics + 2*numClasses;
end    
tsStatistics = zeros(length(selectedTimeSeries), numStatistics); %% min, max, mean, median, std, n-fold increase

%% loop through all selected time series features
for f=1:numTimeSeries
    
    %% get current single feature values
    currentFeature = selectedTimeSeries(f);
    
    %% initialize the current stats variable
    currentStatistics = zeros(length(ind_auswahl), 6);
    deletionIndices = zeros(length(ind_auswahl), 1);
        
    %% compute stats for all valid cells and remember invalid ones for exclusion
    for i=1:numCells
        
        %% get the current cell
        currentCell = selectedCells(i);
        
        %% add to exclusion list if no valid sync information is present
        if (min(squeeze(d_orgs(currentCell, :, syncIndex))) <= 0 || sum(isnan(d_orgs(currentCell, :, currentFeature))) > 0 || sum(isinf(d_orgs(currentCell, :, currentFeature))) > 0)
            deletionIndices(i) = 1;
            continue;
        end
        
        %% identify the sync stages
        syncStages = squeeze(d_orgs(currentCell, :, syncIndex));
        beforeIP = find(syncStages == 1);
        afterIP = find(syncStages == 2);
        afterMA = find(syncStages == 3);

        %% get the current values and compute the stats
        currentValues = squeeze(d_orgs(currentCell, :, currentFeature));
        currentStatistics(i,1) = min(currentValues);
        currentStatistics(i,2) = max(currentValues);
        currentStatistics(i,3) = mean(currentValues);
        currentStatistics(i,4) = std(currentValues);
        currentStatistics(i,5) = median(currentValues);
        
        %% compute the nfold increase between IP and MA phase
        %currentStatistics(i,6) = max(mean(currentValues(beforeIP)), mean(currentValues(afterIP(1:3)))) / min(mean(currentValues(beforeIP)), mean(currentValues(afterIP(1:3))));
        %currentStatistics(i,7) = max(mean(currentValues(beforeIP)), mean(currentValues(afterMA(1:3)))) / min(mean(currentValues(beforeIP)), mean(currentValues(afterMA(1:3))));
        
        if (averageInterval > length(afterIP) || isempty(beforeIP) || averageInterval > length(afterMA))
            deletionIndices(i) = 1;
            continue;
        end
        
        averageBeforeIP = mean(currentValues(beforeIP));
        averageAfterIP = mean(currentValues(afterIP(1:averageInterval)));
        averageAfterMA = mean(currentValues(afterMA(1:averageInterval)));
        
        currentStatistics(i,6) = 100 * abs(averageBeforeIP - averageAfterIP) / abs(averageBeforeIP);
        currentStatistics(i,7) = 100 * abs(averageBeforeIP - averageAfterMA) / abs(averageBeforeIP);
        
        if (averageBeforeIP > averageAfterIP)
            currentStatistics(i,6) = -currentStatistics(i,6);
        end
        if (averageBeforeIP > averageAfterMA)
            currentStatistics(i,7) = -currentStatistics(i,7);
        end
        
        if (sum(isnan(currentStatistics(i,:))) > 0 || sum(isinf(currentStatistics(i,:))) > 0)
            deletionIndices(i) = 1;
            continue;
        end
    end
        
    %% compute stats
    tsStatistics(f, 1) = mean(currentStatistics(~deletionIndices,1));
    tsStatistics(f, 2) = mean(currentStatistics(~deletionIndices,2));
    tsStatistics(f, 3) = mean(currentStatistics(~deletionIndices,3));
    tsStatistics(f, 4) = mean(currentStatistics(~deletionIndices,4));
    tsStatistics(f, 5) = mean(currentStatistics(~deletionIndices,5));
    tsStatistics(f, 6) = mean(currentStatistics(~deletionIndices,6));
    
    currentIndex = 7;
    
    if (numClasses > 1)
        for i=unique(code)'
            validIndices = code(selectedCells) == i & ~deletionIndices;
            tsStatistics(f, currentIndex) = mean(currentStatistics(validIndices, 6));
            currentIndex = currentIndex + 1;
        end
    end
    
    tsStatistics(f, currentIndex) = mean(currentStatistics(~deletionIndices,7));
    
    if (numClasses > 1)
        currentIndex = currentIndex + 1;
        for i=unique(code)'
            validIndices = code(selectedCells) == i & ~deletionIndices;
            tsStatistics(f, currentIndex) = mean(currentStatistics(validIndices, 7));
            currentIndex = currentIndex + 1;
        end
    end
        
    %% select only current feature for plotting    
    selectedTSFeaturesOld = parameter.gui.merkmale_und_klassen.ind_zr;
    parameter.gui.merkmale_und_klassen.ind_zr = currentFeature;
        
    %% plot combined line plot
    callback_livecellminer_show_combined_plots(parameter, d_orgs, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, 1);
    figureHandle = gcf;
    currentImage = frame2im(getframe(figureHandle));
    imwrite(currentImage, [outputFolderPlots parameter.projekt.datei '_' kill_lz(timeSeriesNames(f,:)) '_LinePlots.png']);
    close(figureHandle);
    
    %% plot combined heatmap plot
    callback_livecellminer_show_heatmaps(parameter, d_orgs, var_bez, ind_auswahl, bez_code, code_alle, zgf_y_bez, 1)
    figureHandle = gcf;
    currentImage = frame2im(getframe(figureHandle));
    imwrite(currentImage, [outputFolderPlots parameter.projekt.datei '_' kill_lz(timeSeriesNames(f,:)) '_HeatMaps.png']);
    close(figureHandle);
    
    %% reset the time series selection
    parameter.gui.merkmale_und_klassen.ind_zr = selectedTSFeaturesOld;
    selectedTimeSeries = selectedTSFeaturesOld;
end

%% sort the time series according to the n-fold increase
sortFeature = 7;
if (numClasses > 1)
    sortFeature = sortFeature + numClasses;
end
[~, sortIndices] = sortrows(abs(tsStatistics), -(sortFeature));
featureStatisticsSorted = tsStatistics(sortIndices, :);
featureNamesSorted = timeSeriesNames(sortIndices, :);

%% write the report html file
fileID = fopen(outputReportFile, 'wb');

fprintf(fileID, '<html>\n');
fprintf(fileID, '<head><title>%s</title><style>table, th, td {border: 1px solid black; border-collapse: collapse;} tr:hover {background-color:#dddddd;}</style></head>\n', parameter.projekt.datei);
fprintf(fileID, '<body>\n');


fprintf(fileID, '<table id="top" width="100%%">\n');
fprintf(fileID, '<tr>\n');
fprintf(fileID, '<td><b>Time Series Name</b></td>\n');
fprintf(fileID, '<td><b>Min</b></td>\n');
fprintf(fileID, '<td><b>Max</b></td>\n');
fprintf(fileID, '<td><b>Mean</b></td>\n');
fprintf(fileID, '<td><b>Std</b></td>\n');
fprintf(fileID, '<td><b>Median</b></td>\n');
fprintf(fileID, '<td><b>n-Fold Inc. I->P (All)</b></td>\n');

if (numClasses > 1)
    for i=unique(code(ind_auswahl))
        fprintf(fileID, '<td><b>n-Fold Inc. I->P (%s)</b></td>\n', zgf_y_bez(parameter.gui.merkmale_und_klassen.ausgangsgroesse,i).name);
    end
end

fprintf(fileID, '<td><b>n-Fold Inc. I->A (All)</b></td>\n');

if (numClasses > 1)
    for i=unique(code(ind_auswahl))
        fprintf(fileID, '<td><b>n-Fold Inc. I->A (%s)</b></td>\n', zgf_y_bez(parameter.gui.merkmale_und_klassen.ausgangsgroesse,i).name);
    end
end
fprintf(fileID, '</tr>\n');

%% write the time series table
for f=1:numTimeSeries
    fprintf(fileID, '<tr>\n');
    fprintf(fileID, '<td><a href="#%s">%s</a></td>\n', kill_lz(featureNamesSorted(f,:)), kill_lz(featureNamesSorted(f,:)));
    
    for i=1:size(featureStatisticsSorted, 2)
        fprintf(fileID, '<td>%.2f</td>\n', featureStatisticsSorted(f,i));
    end
    fprintf(fileID, '</tr>\n');
end

fprintf(fileID, '<tr>\n');
for i=1:(size(tsStatistics,2)+1)
    fprintf(fileID, '<td><br></td>\n');
end
fprintf(fileID, '</tr>\n');

fprintf(fileID, '<tr>\n');
fprintf(fileID, '<td><b>Single Feature Name</b></td>\n');
fprintf(fileID, '<td><b>Min</b></td>\n');
fprintf(fileID, '<td><b>Max</b></td>\n');
fprintf(fileID, '<td><b>Mean</b></td>\n');
fprintf(fileID, '<td><b>Std</b></td>\n');
fprintf(fileID, '<td><b>Median</b></td>\n');
for i=6:size(tsStatistics,2)
    fprintf(fileID, '<td></td>\n');
end
fprintf(fileID, '</tr>\n');

%% write the single features table
for f=1:numSingleFeatures
    fprintf(fileID, '<tr>\n');
    fprintf(fileID, '<td><a href="#%s">%s</a></td>\n', kill_lz(singleFeatureNames(f,:)), kill_lz(singleFeatureNames(f,:)));
    fprintf(fileID, '<td>%.2f</td>\n', singleFeatureStatistics(f,1));
    fprintf(fileID, '<td>%.2f</td>\n', singleFeatureStatistics(f,2));
    fprintf(fileID, '<td>%.2f</td>\n', singleFeatureStatistics(f,3));
    fprintf(fileID, '<td>%.2f</td>\n', singleFeatureStatistics(f,4));
    fprintf(fileID, '<td>%.2f</td>\n', singleFeatureStatistics(f,5));
    for i=6:size(tsStatistics,2)
        fprintf(fileID, '<td>-</td>\n');
    end
    fprintf(fileID, '</tr>\n');
end

fprintf(fileID, '</table>\n');

fprintf(fileID, '<table width="100%%">\n');

%% write the time series images
for f=1:numTimeSeries
    fprintf(fileID, '<tr id="%s">\n', kill_lz(featureNamesSorted(f,:)));
    fprintf(fileID, '<td><a href="#top">\n');
    fprintf(fileID, '<img src="Plots/%s" width="49%%" >\n', [parameter.projekt.datei '_' kill_lz(featureNamesSorted(f,:)) '_HeatMaps.png']);
    fprintf(fileID, '<img src="Plots/%s" width="49%%" >\n', [parameter.projekt.datei '_' kill_lz(featureNamesSorted(f,:)) '_LinePlots.png']);
    fprintf(fileID, '</a></td>\n');
    fprintf(fileID, '</tr>\n');
end

%% write the single feature images
for f=1:numSingleFeatures
    fprintf(fileID, '<tr id="%s">\n', kill_lz(singleFeatureNames(f,:)));
    fprintf(fileID, '<td><a href="#top">\n');
    fprintf(fileID, '<img src="Plots/%s" width="49%%" >\n', [parameter.projekt.datei '_' kill_lz(singleFeatureNames(f,:)) '_BoxPlots.png']);
    fprintf(fileID, '<img src="Plots/%s" width="49%%" >\n', [parameter.projekt.datei '_' kill_lz(singleFeatureNames(f,:)) '_Histograms.png']);
    fprintf(fileID, '</a></td>\n');
    fprintf(fileID, '</tr>\n');
end

%% close the html file body
fprintf(fileID, '</table>\n');
fprintf(fileID, '</body>\n');
fprintf(fileID, '</html>\n');

%% close the file handle
fclose(fileID);
    
%% ask if report should be opened
disp(['Report successfully written to "' outputReportFile '".']);
answer = questdlg(['Report successfully written to "' outputReportFile '". Do you want to open it?'], 'Open Report?', 'Yes', 'No', 'Yes');
if (strcmp(answer, 'Yes'))
    web(outputReportFile);
end