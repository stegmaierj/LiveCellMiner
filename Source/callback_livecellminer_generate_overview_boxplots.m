


manualSyncIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
experimentId = callback_livecellminer_find_output_variable(bez_code, 'Experiment');
positionId = callback_livecellminer_find_output_variable(bez_code, 'Position');

selectedFeature = parameter.gui.merkmale_und_klassen.ind_em(1);
showBoxPlots = false;
numExperiments = length(unique(code_alle(:,experimentId)));
numPositions = unique(code_alle(:,plateId));

colorMap = lines(numPositions);

figure;
currentExperiment = 1;
for e=unique(code_alle(:,experimentId))'

    dataMatrix = [];
    grouping = [];
    groupNames = cell(1,1);
    currentGroup = 1;

    for p=unique(code_alle(:,plateId))'
        
        validIndices = find(squeeze(d_orgs(:,1,manualSyncIndex)) > 0 & code_alle(:,experimentId) == e & code_alle(:,plateId) == p);
        
        dataMatrix = [dataMatrix; d_org(validIndices, selectedFeature)];
        grouping = [grouping; currentGroup * ones(size(validIndices))];
        groupNames{currentGroup} = [zgf_y_bez(positionId, p).name];
        
        currentGroup = currentGroup+1;
    end
    
    subplot(1,numExperiments, currentExperiment);
    if (showBoxPlots == true)
        boxplot(dataMatrix, grouping, 'Labels', groupNames);
    else
       plotObject = violinplot(dataMatrix, grouping);
        for l=1:numPositions
           plotObject(l).ViolinColor = colorMap(l,:);
        end

        set(gca, 'XLim', [min(grouping)-0.5, max(grouping)+0.5]);
        set(gca, 'XTick', unique(grouping), 'XTickLabels', groupNames);
        xlabel(''); 
    end
    ylabel(kill_lz(dorgbez(selectedFeature, :)));
    title(strrep(zgf_y_bez(experimentId, e).name, '_', '-'));
    currentExperiment = currentExperiment+1;
end
    
