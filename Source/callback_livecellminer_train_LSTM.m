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

%% specify the input paths for the training data and the lstm model
if (~exist(dataPath, 'file'))
    dataPath = uigetfile('*.cdd', 'Select training data to train an LSTM classifier for the currently selected cells!', [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'chromatindec' filesep 'classifiers' filesep]);
end
modelPath = strrep(dataPath, '.cdd', '.cdc');
    
%% hard coded parameters
performValidation = false;
numHiddenUnits = 125;

%% load the previous data
if (exist(dataPath, 'file'))
    load(dataPath, '-mat');
else
    disp('Please provide training data first, by manually annotating a few sequences and calling "Chromatindec -> Align -> Update LSTM Classifier"');
    return;
end

%% set the input sequence depending on the training mode
trainingMode = 2;
if (trainingMode == 1)
    sequences = sequencesClassical;
elseif (trainingMode == 2)
    sequences = sequencesCNN;
end

%% Perform the LSTM based classification (copied from MATLAB doc)
numObservations = numel(sequences);
idx = randperm(numObservations);
numTrainingImages = floor(0.9 * numObservations);

%% randomly select 90% / 10% of the data for training / validation
idxTrain = idx(1:numTrainingImages);
idxValidation = idx(numTrainingImages+1:end);
sequencesTrain = sequences(idxTrain);
sequencesValidation = sequences(idxValidation);

%% use class labels or one-hot encoded classes for regression and classification respectively
labelsClassificationTrain = validityLabels(idxTrain);
labelsClassificationValidation = validityLabels(idxValidation);
labelsRegressionTrain = stateLabels(idxTrain);
labelsRegressionValidation = stateLabels(idxValidation);

%% get the number of observations and the number of sequences
numObservationsTrain = numel(sequencesTrain);
sequenceLengths = zeros(1,numObservationsTrain);

%% identify the number of features and setup the LSTM hyperparameters
numFeatures = size(sequencesTrain{1},1);
numClasses = 2;
numResponses = 1;

%% classification network to identify invalid trajectories
classificationNetwork = [
    sequenceInputLayer(numFeatures)
    bilstmLayer(numHiddenUnits, 'OutputMode', 'last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

%% regression network to directly predict the synchronization states
regressionNetwork = [
    sequenceInputLayer(numFeatures)
    bilstmLayer(numHiddenUnits, 'OutputMode', 'sequence')
    fullyConnectedLayer(numResponses)
    regressionLayer];
    
%% set the training parameters
maxEpochs = 40;
miniBatchSize = 16;
numObservations = numel(sequencesTrain);
numIterationsPerEpoch = floor(numObservations / miniBatchSize);
optionsClassification = trainingOptions('adam', ...
    'MiniBatchSize', miniBatchSize, ...
    'InitialLearnRate', 1e-4, ...
    'GradientThreshold', 2, ...
    'MaxEpochs', maxEpochs, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {sequencesValidation,labelsClassificationValidation}, ...
    'ValidationFrequency', numIterationsPerEpoch, ...
    'Plots', 'training-progress', ...
    'Verbose', false);

optionsRegression = trainingOptions('adam', ...
    'MiniBatchSize', miniBatchSize, ...
    'InitialLearnRate', 1e-4, ...
    'GradientThreshold', 2, ...
    'MaxEpochs', maxEpochs, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {sequencesValidation,labelsRegressionValidation}, ...
    'ValidationFrequency', numIterationsPerEpoch, ...
    'Plots', 'training-progress', ...
    'Verbose', false);

%% train the lstm
[classificationLSTM, classificationInfo] = trainNetwork(sequencesTrain, labelsClassificationTrain, classificationNetwork, optionsClassification);
[regressionLSTM, regressionInfo] = trainNetwork(sequencesTrain, labelsRegressionTrain, regressionNetwork, optionsRegression);
save(modelPath, 'classificationLSTM', 'regressionLSTM');
disp(['Finished training classifier. The final model was saved to: ' modelPath]);

%% if validation is enabled, assess the performance of the trained LSTM
if (performValidation == true)
    
    %% predict the classes for the validation data set
    trainPred = predict(regressionLSTM, sequencesTrain);
    validationPred = predict(regressionLSTM, sequencesValidation);

    %% perform HMM based correction for the training set
    trainPredHMM = cell(size(trainPred, 1), 1);
    for i=1:size(trainPred, 1)
        currentPred = round(trainPred{i});
        currentPred(currentPred < 0) = 0;
        currentPred(currentPred > 3) = 3;
        trainPredHMM{i} = callback_livecellminer_perform_HMM_prediction(currentPred);
    end

    %% perform HMM based correction for the validation set
    validationPredHMM = cell(size(validationPred, 1), 1);
    for i=1:size(validationPred, 1)
        currentPred = round(validationPred{i});
        currentPred(currentPred < 0) = 0;
        currentPred(currentPred > 3) = 3;
        validationPredHMM{i} = callback_livecellminer_perform_HMM_prediction(currentPred);
    end

    %% compute the errors on the training set
    errorsTrain = [];
    errorsHMMTrain = [];
    for i=1:length(trainPred)
        rmsd = sqrt(mean(abs(labelsRegressionTrain{i} - round(trainPred{i})).^2));
        rmsdHMM = sqrt(mean(abs(labelsRegressionTrain{i} - round(trainPredHMM{i})).^2));
        errorsTrain = [errorsTrain; rmsd];
        errorsHMMTrain = [errorsHMMTrain; rmsdHMM];
    end

    %% compute the errors on the validation set
    errorsValidation = [];
    errorsValidationHMM = [];
    for i=1:length(validationPred)
        rmsd = sqrt(mean(abs(labelsRegressionValidation{i} - round(validationPred{i})).^2));
        rmsdHMM = sqrt(mean(abs(labelsRegressionValidation{i} - round(validationPredHMM{i})).^2));
        errorsValidation = [errorsValidation; rmsd];
        errorsValidationHMM = [errorsValidationHMM; rmsdHMM];
        
        figure(2); clf; hold on;
        plot(labelsRegressionValidation{i}, '.-g')
        plot(round(validationPred{i}), 'o-b');
        plot(round(validationPredHMM{i}), '*-m');
        
        pause(2);
    end

    %% display the training results
    disp(['Training error without HMM correction: ' num2str(mean(errorsTrain))]);
    disp(['Training error with HMM correction: ' num2str(mean(errorsHMMTrain))]);
    disp(['Validation error without HMM correction: ' num2str(mean(errorsValidation))]);
    disp(['Validation error with HMM correction: ' num2str(mean(errorsValidationHMM))]);
end