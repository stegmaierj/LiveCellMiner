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

%% enable/disable debug figures
debugFigures = false;
maxMAShift = 3;

%% load the previous data
syncMethods = {'Classical', 'Classical + Auto Rejection', 'LSTM + HMM + Auto Rejection', 'Hybrid (Classical+Auto Rejection for MA; LSTM + HMM for IP)'};
[selectedSyncMethod, ~] = listdlg('Name', 'Select the sync. method to use!', 'SelectionMode','single','ListString', syncMethods, 'ListSize',[350, 100]);
if (isempty(selectedSyncMethod))
    disp('No synchronization method selected, aborting ...');
    return;
end

syncMethod = syncMethods{selectedSyncMethod};
useClassicalSync = ~isempty(strfind(syncMethod, 'Classical')); %#ok<STREMP> 
useAutoRejection = ~isempty(strfind(syncMethod, 'Auto Rejection')); %#ok<STREMP> 
useHybrid = ~isempty(strfind(syncMethod, 'Hybrid')); %#ok<STREMP> 

%% specify image data base
imageDataBase = [parameter.projekt.pfad filesep parameter.projekt.datei '.h5'];

%% path to the pretrained model
if (useAutoRejection == true)
    
    [modelFile, modelPath] = uigetfile('*.cdc', 'Select LSTM classifier for the current data set!');

    if (modelFile == 0)
        disp('LSTM classifier for discarding invalid tracks and auto sync was not found. Perform manual annotations first and train a classifier using "Chromatindec -> Align -> Update LSTM Classifier"');
        return;
    end
    modelPath = [modelPath modelFile];
    
    if (exist(modelPath, 'file'))
        load(modelPath, '-mat');
    else
        disp('LSTM classifier for discarding invalid tracks and auto sync was not found. Perform manual annotations first and train a classifier using "Chromatindec -> Align -> Update LSTM Classifier"');
        return;
    end
end

%% add new time series for the synchronization time point
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
if (synchronizationIndex <= 0)
   d_orgs(:,:,end+1) = 0;
   var_bez = char(var_bez(1:size(d_orgs,3)-1,:), 'manualSynchronization');
   aktparawin;
end

%% identify features required for the automatic synchronization
positionXIndex = callback_livecellminer_find_time_series(var_bez, 'xpos'); 
positionYIndex = callback_livecellminer_find_time_series(var_bez, 'ypos');
synchronizationIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization'); 
areaIndex = callback_livecellminer_find_time_series(var_bez, 'Area');
circularityIndex = callback_livecellminer_find_time_series(var_bez, 'Circularity');
meanIntensityIndex = callback_livecellminer_find_time_series(var_bez, 'MeanIntensity');
stdIntensityIndex = callback_livecellminer_find_time_series(var_bez, 'StdIntensity');
entropyIndex = callback_livecellminer_find_time_series(var_bez, 'Entropy');
clusterFeatures = [areaIndex, circularityIndex, meanIntensityIndex, stdIntensityIndex];

%% check if a manually confirmed feature exists to skip auto-alignment for manually corrected ones.
manuallyConfirmedIndex = callback_livecellminer_find_single_feature(dorgbez, 'manuallyConfirmed');

%% counters to check how many cells were properly sync'ed
MATransition = parameter.projekt.timeWindowMother;
validSynchronization = 0;
invalidSynchronization = 0;
numFrames = size(d_orgs, 2);

%% process all cells contained in d_orgs (step size of 2 to ensure consistent synchronization for siblings)
f = waitbar(0, ['Performing auto-sync with the ' syncMethod ' method ...']);
for i=1:2:size(d_orgs,1)
    
    waitbar((i / size(d_orgs,1)), f, ['Performing auto-sync with the ' syncMethod ' method ...']);
    
    %% always process both daughters together as differing synchronization does not make sense
    if (mod(i, 2) == 0)
        continue;
    end
    
    %% skip synchronization if the cell was already manually synched
    if (manuallyConfirmedIndex > 0 && d_org(i, manuallyConfirmedIndex) > 0)
       continue; 
    end
    
    %% initialize transition time points for the different methods
    IPClassical = -1;
    IPLSTM = -1;
    MAClassical = -1;
    MALSTM = -1;
    InvalidLSTMSync = false;

    %% check if classifier exists
    if (exist('classificationLSTM', 'var') && useAutoRejection == true)
        
        %% specify filename for the image data base
        imageDataBase = callback_livecellminer_get_image_data_base_filename(i, parameter, code_alle, zgf_y_bez, bez_code);
        if (~exist(imageDataBase, 'file'))
            fprintf('Image database file %s not found. Starting the conversion script to have it ready next time. Please be patient!', imageDataBase);
            callback_livecellminer_convert_image_files_to_hdf5;
        end

        currentFeaturesCNN = h5read(imageDataBase, callback_livecellminer_create_hdf5_path(i, code_alle, zgf_y_bez, 'cnn'));
        validTrajectoryProbability = predict(classificationLSTM, currentFeaturesCNN);

        %% check if LSTM predicted an invalid track
        if (validTrajectoryProbability(1) > validTrajectoryProbability(2))
            InvalidLSTMSync = true;
        end
                
        %% if LSTM + HMM sync is selected, use the pretrained network for prediction
        if (useClassicalSync == false || useHybrid == true)
            autoSyncPrediction = predict(regressionLSTM, currentFeaturesCNN);
            autoSyncPrediction = round(autoSyncPrediction);
            autoSyncPrediction(autoSyncPrediction < 0) = 0;
            autoSyncPrediction(autoSyncPrediction > 3) = 3;
            autoSyncPredictionHMMCorrected = callback_livecellminer_perform_HMM_prediction(autoSyncPrediction);
            
            bestIP = min(find(autoSyncPredictionHMMCorrected == 2)); %#ok<MXFND> 
            bestMA = min(find(autoSyncPredictionHMMCorrected == 3)); %#ok<MXFND> 
            
            %% check if track is reasonable and contains all stages
            if (length(unique(autoSyncPredictionHMMCorrected)) < 3 || ...
                sum(autoSyncPredictionHMMCorrected <= 0) > 0 || ...
                sum(autoSyncPredictionHMMCorrected==1) > parameter.gui.livecellminer.IPTransition)
                InvalidLSTMSync = true;
            end

            %% save best IP and MA predicted by the LSTM
            IPLSTM = bestIP;
            MALSTM = bestMA;
        end
    end
   
    if (useClassicalSync)
        %% Perform classical synchronization
        %% identify the current values for the std. dev. feature
        currentValues1 = squeeze(d_orgs(i,:, clusterFeatures));
        currentValues2 = squeeze(d_orgs(i+1,:, clusterFeatures));
        currentValues = zscore(0.5 * (currentValues1 + currentValues2));
    
        %% find best IP transition based on extensive search for the threshold value that
        %% minimizes intraclass variance
        bestIP = 1;
        bestMA = MATransition;
        bestScore = inf;
        for m=1:(MATransition-1)
            intFrames = 1:m;
            proMetFrames = (m+1):MATransition;
    
            meanInt = mean(currentValues(intFrames, :));
            meanProMet = mean(currentValues(proMetFrames, :));
    
            currentScore = 0;
            for o=intFrames
                currentScore = currentScore + sum((currentValues(o, :) - meanInt) .^ 2);
            end
            for o=proMetFrames
                currentScore = currentScore + sum((currentValues(o, :) - meanProMet) .^ 2);
            end
    
            if (currentScore < bestScore)
                bestScore = currentScore;
                bestIP = m;
            end          
        end
    
        %% remember the best IP transition of the classical method
        IPClassical = bestIP;
    
        %% apply heuristic for the meta to anaphase transition
        anaPhaseFrames = MATransition:numFrames;
    
        %% use chromatin distance as a criterion to determine the late ana phase
        if (parameter.gui.livecellminer.sisterDistanceThreshold >= 0)
            sisterDistance = sqrt(sum((squeeze(d_orgs(i, :, positionXIndex:positionYIndex)) - squeeze(d_orgs(i+1, :, positionXIndex:positionYIndex))).^2, 2));
            bestMA = max(MATransition, min(find(sisterDistance >= parameter.gui.livecellminer.sisterDistanceThreshold))-1); %#ok<MXFND> 
            MAClassical = bestMA;
        else
            bestMA = MATransition;
            
            %% check if current sync point is early anaphase
            area11 = d_orgs(i, anaPhaseFrames(1), areaIndex);
            area12 = d_orgs(i, anaPhaseFrames(2), areaIndex);
            area21 = d_orgs(i+1, anaPhaseFrames(1), areaIndex);
            area22 = d_orgs(i+1, anaPhaseFrames(2), areaIndex);
            intensity11 = d_orgs(i, anaPhaseFrames(1), meanIntensityIndex);
            intensity12 = d_orgs(i, anaPhaseFrames(2), meanIntensityIndex);
            intensity21 = d_orgs(i+1, anaPhaseFrames(1), meanIntensityIndex);
            intensity22 = d_orgs(i+1, anaPhaseFrames(2), meanIntensityIndex);
            
            %% shift meta-ana transition time point by a frame if:
            %% 1. the area of both daughters is smaller in the next frame OR
            %% 2. the intensity of both daughters is higher in the next frame
            %% both cases indicate a stronger compaction of the chromatin and a
            %% void selecting early ana phase as the transition.
            if ((area11 > area12 || area21 > area22) || ...
                (intensity11 < intensity12 && intensity21 < intensity22))
                bestMA = bestMA + 1;
            end
            MAClassical = bestMA;
        end
    end

    %% select the transition time points to be used depending on the selected method
    if (strcmp('Classical', syncMethod) || strcmp('Classical + Auto Rejection', syncMethod))
        bestIP = IPClassical;
        bestMA = MAClassical;
    elseif (strcmp('LSTM + HMM + Auto Rejection', syncMethod))
        bestIP = IPLSTM;
        bestMA = MALSTM;
    elseif (strcmp('Hybrid (Classical+Auto Rejection for MA; LSTM + HMM for IP)', syncMethod))
        bestIP = IPLSTM;
        bestMA = MAClassical;
    end

    %% avoid unrealistically large MA transition shifts
    if (isempty(bestMA) || ...
        isempty(bestIP) || ...
        abs(bestMA - MATransition) > maxMAShift || ...
        InvalidLSTMSync == true)
        d_orgs(i:(i+1), :, synchronizationIndex) = -1;
        invalidSynchronization = invalidSynchronization+2;
        continue;
    else
    
        %% set the synchronization time points
        d_orgs(i:(i+1), 1:(bestIP-1), synchronizationIndex) = 1;
        d_orgs(i:(i+1), bestIP:bestMA, synchronizationIndex) = 2;
        d_orgs(i:(i+1), (bestMA+1):end, synchronizationIndex) = 3;
    end

    %% show debug figures if enabled
    if (debugFigures == true)

        figure(2); clf; 
        subplot(1,2,1);
        hold on;
        plot(1:numFrames, currentValues(:,1), '-g');
        plot(bestIP, currentValues(bestIP,1), '*r');

        %% load the current cell images to visualize the transition points
        currentImage = loadtiff(parameter.projekt.imageFiles{i,1});
        currentMask = loadtiff(parameter.projekt.imageFiles{i,2});

        ipRect = [0, 0, 90, 90];
        maRect = [0, 0, 90, 90];

        debugImage = zeros(810, 900);
        currentIndex = 1;
        for j=1:9
            for k=1:10

                rangeX = (1:90) + (k-1)*90;
                rangeY = (1:90) + (j-1)*90;

                debugImage(rangeY, rangeX) = imadjust(currentImage(:,:,currentIndex)); %imadjust(currentImage(:,:,currentIndex)) .* currentMask(:,:,currentIndex);

                if (currentIndex == bestIP)
                    ipRect(1) = (k-1)*90 + 1;
                    ipRect(2) = (j-1)*90 + 1;
                end

                if (currentIndex == bestMA)
                    maRect(1) = (k-1)*90 + 1;
                    maRect(2) = (j-1)*90 + 1;
                end

                currentIndex = currentIndex+1;
            end
        end

        subplot(1,2,2); hold on;
        imagesc(debugImage);
        colormap gray;
        rectangle('Position', ipRect, 'EdgeColor','r');
        rectangle('Position', maRect, 'EdgeColor','g');
        set(gca, 'YDir', 'reverse');
        axis tight;
    end
    
    validSynchronization = validSynchronization+2;
end

close(f);
disp(['Successfully identified synchronization time points for ' num2str(validSynchronization) '/' num2str(size(d_orgs,1)) ' cells.']);
disp(['Synchronization was ambiguous for ' num2str(invalidSynchronization) '/' num2str(size(d_orgs,1)) ' cells.']);

disp('Use "LiveCellMiner -> Process -> Show Auto-Sync Overview" to analyze how the valid synchronizations distribute over the experiments/oligos!');
disp('Use "LiveCellMiner -> Process -> Perform Manual Synchronization" to manually align selected cells!');
disp('Class-based selection can be performed using "Edit -> Select -> Data Points using Classes"');

aktparawin;