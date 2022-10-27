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
% D. Moreno-Andrés, A. Bhattacharyya, A. Scheufen, J. Stegmaier, “LiveCellMiner: A
% New Tool to Analyze Mitotic Progression", PLOS ONE, 17(7), e0270923, 2022.
%
%%

%% specify the input paths for the training data and the lstm model
[filename, pathname] = uiputfile('*.cdd', 'Select a file name to save the training data to!', [parameter.allgemein.pfad_gaitcad filesep 'application_specials' filesep 'livecellminer' filesep 'classifiers' filesep]);
dataPath = [pathname filename];

if (length(filename) == 1)
    disp('No valid output file selected for storing the training data. Please repeat and select a valid output file.');
    return;
end

%% load the previous data if available and wanted
appendData = false;
if (exist(dataPath, 'file'))
    answer = questdlg('Load previous data to extend it?', 'Load previous data?', 'Yes', 'No', 'Cancel', 'No');
    if (strcmp(answer, 'Yes'))
        load(dataPath, '-mat');
        appendData = true;
    end
end

%% loop through all manually corrected cells and add them to the training data
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_EM'),{'manuallyConfirmed'});eval(gaitfindobj_callback('CE_Auswahl_EM'));
manuallyConfirmedIndex = parameter.gui.merkmale_und_klassen.ind_em;

%% restore the old selection
set(gaitfindobj('CE_Auswahl_EM'),'value', oldSelection);
aktparawin;

%% find the synchronization index
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
synchronizationIndex = parameter.gui.merkmale_und_klassen.ind_zr;

%% restore the old selection
set(gaitfindobj('CE_Auswahl_ZR'),'value', oldSelection);
aktparawin;

%% check if precached images were already loaded
dataPrecached = exist('rawImagePatches', 'var') && exist('maskImagePatches', 'var') && exist('maskedImageCNNFeatures', 'var') && ~isempty(rawImagePatches) && ~isempty(maskImagePatches) && ~isempty(maskedImageCNNFeatures);

%% precache the image snippets
if (dataPrecached == false)
   callback_livecellminer_load_image_files;
   dataPrecached = true;
end

%% specify the image sizes
featureRange = 1:29;
oldImageSize = 90;
numFrames = size(d_orgs,2);
validIndices = ind_auswahl(d_org(ind_auswahl, manuallyConfirmedIndex) > 0);

%% initialize variable for the upsampled image 
currentImage = zeros(oldImageSize, oldImageSize, numFrames);
currentMask = zeros(oldImageSize, oldImageSize, numFrames);

%% initialize variables if they don't exist yet
if (~exist('sequencesCNN', 'var') || ~exist('sequencesClassical', 'var') || ~exist('stateLabels', 'var') || appendData == false)
    numSamples = length(validIndices);
    sequencesCNN = cell(numSamples, 1);
    sequencesClassical = cell(numSamples, 1);
    stateLabels = cell(numSamples, 1);
    validityLabels = cell(numSamples, 1);
    checkSum = zeros(numSamples, 1);
    currentSequence = 1;
else
    numSamples = length(validIndices);
    currentSequence = size(sequencesCNN, 1)+1;
end

%% process all selected indices and add them to the training data
dirtyFlag = false;
for i=validIndices'
        
    %% check if the current cell was manually confirmed (otherwise it's not used as GT) or if it was not synchronized
    if (d_org(i, manuallyConfirmedIndex) == 0 || min(d_orgs(i,:,synchronizationIndex)) == 0)
        if (min(d_orgs(i,:,synchronizationIndex)) == 0)
            test = 1;
        end
        
        continue;
    end
    
    %% summarize the CNN features for the current time series
    currentFeaturesCNN = zeros(1000, numFrames);
    for j=1:numFrames
        currentFeaturesCNN(:,j) = maskedImageCNNFeatures{i, j};
    end
    currentCheckSum = sum(currentFeaturesCNN(:) / max(0.1, currentFeaturesCNN(end)));

    %% skip adding the current detection if there is already an entry with the same checksum
    if (ismember(currentCheckSum, checkSum))
       disp(['Skipping entry ' num2str(i) ' as an entry with the same checksum already exists!']);
       continue;
    end
        
    %% set the features and targets
    sequencesCNN{currentSequence} = currentFeaturesCNN;
    sequencesClassical{currentSequence} = squeeze(d_orgs(i,:,featureRange))';
    stateLabels{currentSequence} = d_orgs(i,:,synchronizationIndex);
    checkSum(currentSequence) = currentCheckSum;
    
    if (max(d_orgs(i,:,synchronizationIndex)) <= 0)
        stateLabels{currentSequence}(:) = 0;
    end
    
    if (max(d_orgs(i,:,synchronizationIndex)) > 0)
        validityLabels(currentSequence) = cellstr('valid');
    else
        validityLabels(currentSequence) = cellstr('invalid');
    end
    
    %% display status and increment current sequence counter
    dirtyFlag = true;
    disp(['Finished processing ' num2str(currentSequence) '/' num2str(length(validIndices))]);    
    currentSequence = currentSequence + 1;
end

%% get the names of the classical features
classicalFeatureNames = var_bez(featureRange, :);

%% remove empty entries
sequencesCNN = sequencesCNN(1:(currentSequence-1));
sequencesClassical = sequencesClassical(1:(currentSequence-1));
stateLabels = stateLabels(1:(currentSequence-1));
checkSum = checkSum(1:(currentSequence-1));
validityLabels = validityLabels(1:(currentSequence-1));

%% save the updated training data
validityLabels = categorical(validityLabels);
dummyVariable = 0;

%% save data if any changes were made
if (dirtyFlag == true)
    save(dataPath, 'dummyVariable', '-v7.3', 'sequencesCNN', 'sequencesClassical', 'classicalFeatureNames', 'stateLabels', 'validityLabels', 'checkSum');
end

%% ask if the new model should directly be fit
answer = questdlg('Would you like to retrain the LSTM classifier?', 'Retrain classifier?', 'Yes', 'No', 'Cancel', 'Yes');
if (strcmp(answer, 'Yes'))
    callback_livecellminer_train_LSTM;
end

clear dataPath;
clear modelPath;