%%
% ChromatinDec.
% Copyright (C) 2020 A. Bhattacharyya, D. Moreno-Andres, J. Stegmaier
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

%% enable/disable debug figures
debugFigures = false;

%% load the previous data
modelPath = [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'chromatindec' filesep 'autoSyncLSTMModel.mat'];
syncMethod = questdlg('Which synchronization method do you want to use?', 'Select Synchronization Mode', 'Classical', 'Classical + Auto Rejection', 'LSTM + HMM + Auto Rejection', 'Classical + Auto Rejection');
useClassicalSync = ~isempty(strfind(syncMethod, 'Classical'));
useAutoRejection = ~isempty(strfind(syncMethod, 'Auto Rejection'));

%% path to the pretrained model
if (useAutoRejection == true)
    if (exist(modelPath, 'file'))
        load(modelPath);
    else
        disp('LSTM classifier for discarding invalid tracks and auto sync was not found. Perform manual annotations first and train a classifier using "Chromatindec -> Align -> Update LSTM Classifier"');
    end
end

%% add new time series for the synchronization time point
if (size(d_orgs,3) < 30)
   d_orgs(:,:,end+1) = 0;
   var_bez = char(var_bez(1:size(d_orgs,3)-1,:), 'manualSynchronization');
   aktparawin;
end

%% identify features required for the automatic synchronization
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
synchronizationIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'MeanIntensity'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
meanIntensityIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'StdIntensity'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
stdIntensityIndex = parameter.gui.merkmale_und_klassen.ind_zr;

clusterFeatures = [7, 10:12];

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'Entropy'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
entropyIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'Area'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
areaIndex = parameter.gui.merkmale_und_klassen.ind_zr;

%% restore the old selection
set(gaitfindobj('CE_Auswahl_ZR'),'value', oldSelection);
aktparawin;

%% check if a manually confirmed feature exists to skip auto-alignment for manually corrected ones.
try
    oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
    set_textauswahl_listbox(gaitfindobj('CE_Auswahl_EM'),{'manuallyConfirmed'});eval(gaitfindobj_callback('CE_Auswahl_EM'));
    manuallyConfirmedIndex = parameter.gui.merkmale_und_klassen.ind_em;

    %% restore the old selection
    set(gaitfindobj('CE_Auswahl_EM'),'value', oldSelection);
    aktparawin;
catch
    manuallyConfirmedIndex = 0;
end

%% counters to check how many cells were properly sync'ed
MATransition = 30;
validSynchronization = 0;
invalidSynchronization = 0;
numFrames = size(d_orgs, 2);

%% process all cells contained in d_orgs (step size of 2 to ensure consistent synchronization for siblings)
f = waitbar(0, ['Performing auto-sync with the ' syncMethod ' method ...']);
for i=ind_auswahl'%1:2:size(d_orgs,1)
    
    waitbar((find(ind_auswahl == i) / length(ind_auswahl)), f, ['Performing auto-sync with the ' syncMethod ' method ...']);
    
    %% always process both daughters together as differing synchronization does not make sense
    if (mod(i, 2) == 0)
        continue;
    end
    
    %% skip synchronization if the cell was already manually synched
    if (manuallyConfirmedIndex > 0 && d_org(i, manuallyConfirmedIndex) > 0)
       continue; 
    end
    
    %% check if classifier exists
    if (exist('classificationLSTM', 'var') && useAutoRejection == true)
        currentFeaturesCNN = zeros(1000, numFrames);
        for j=1:numFrames
            currentFeaturesCNN(:,j) = maskedImageCNNFeatures{i, j};
        end 
        validTrajectoryProbability = predict(classificationLSTM, currentFeaturesCNN);
        
        if (validTrajectoryProbability(1) > validTrajectoryProbability(2))
            %% set the synchronization time points
            d_orgs(i:(i+1), :, synchronizationIndex) = -1;
            invalidSynchronization = invalidSynchronization+2;
            continue;
        end
        
        %% if LSTM + HMM sync is selected, use the pretrained network for prediction
        if (useClassicalSync == false)
            autoSyncPrediction = predict(regressionLSTM, currentFeaturesCNN);
            autoSyncPrediction = round(autoSyncPrediction);
            autoSyncPrediction(autoSyncPrediction < 0) = 0;
            autoSyncPrediction(autoSyncPrediction > 3) = 3;
            autoSyncPredictionHMMCorrected = callback_chromatindec_perform_HMM_prediction(autoSyncPrediction);
            
            if (length(unique(autoSyncPredictionHMMCorrected)) < 3 || sum(autoSyncPredictionHMMCorrected <= 0) > 0)
                d_orgs(i:(i+1), :, synchronizationIndex) = -1;
                invalidSynchronization = invalidSynchronization+2;
                continue;
            end
            
            d_orgs(i, :, synchronizationIndex) = autoSyncPredictionHMMCorrected;
            d_orgs(i+1, :, synchronizationIndex) = autoSyncPredictionHMMCorrected;
            validSynchronization = validSynchronization+2;
            continue;
        end
    end
   
    %% Perform classical synchronization
    %% identify the current values for the std. dev. feature
    currentValues1 = squeeze(d_orgs(i,:, clusterFeatures));
    currentValues2 = squeeze(d_orgs(i+1,:, clusterFeatures));
    currentValues = zscore(0.5 * (currentValues1 + currentValues2));

    %% find best IP transition based on extensive search for the threshold value that
    %% minimizes intraclass variance
    bestIP = 1;
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

    %% apply heuristic for the meta to anaphase transition
    anaPhaseFrames = MATransition:numFrames;
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

    %% set the synchronization time points
    d_orgs(i:(i+1), 1:(bestIP-1), synchronizationIndex) = 1;
    d_orgs(i:(i+1), bestIP:bestMA, synchronizationIndex) = 2;
    d_orgs(i:(i+1), (bestMA+1):end, synchronizationIndex) = 3;

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

disp('Use "ChromatinDec -> Process -> Show Auto-Sync Overview" to analyze how the valid synchronizations distribute over the experiments/oligos!');
disp('Use "ChromatinDec -> Process -> Perform Manual Synchronization" to manually align selected cells!');
disp('Class-based selection can be performed using "Edit -> Select -> Data Points using Classes"');

aktparawin;