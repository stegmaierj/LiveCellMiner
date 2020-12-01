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

%% identify the selected time series
selectedFeatures = parameter.gui.merkmale_und_klassen.ind_zr;

%% get the synchronization feature
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
syncFeature = parameter.gui.merkmale_und_klassen.ind_zr;

%% resore the selection
set(gaitfindobj('CE_Auswahl_ZR'), 'value', selectedFeatures);
aktparawin;

%% different modes of computing the relative deviation / recovery 
%% mode 1: ratio of current vs. target
%% mode 2: signed percentage deviation of current vs. target
%% mode 3: absolute percentage deviation of current vs. target
mode = parameter.gui.chromatindec.recoveryMeasureMode;
if (mode == 1)
    featureSuffix = '-RecoveryRatio';
elseif (mode == 2)    
    featureSuffix = '-RecoveryRatioInc';
elseif (mode == 3)
    featureSuffix = '-RecoverySignedPercDev';
elseif (mode == 4)
    featureSuffix = '-RecoveryAbsPercDev';
else
    disp('Invalid mode selected, aborting feature computation!');
    return;
end

%% process all selected features
for f=generate_rowvector(selectedFeatures)

    %% initialize a new feature and add a new specifier
    d_orgs(:,:,end+1) = 0;
    var_bez = char(var_bez(1:size(d_orgs,3)-1, :), [kill_lz(var_bez(f, :)) featureSuffix]);

    %% process all data points and use the frame after the synchronization time point for normalization.
    for i=1:size(d_orgs,1)

        %% find normalization time point
        interPhaseFrames = find(d_orgs(i,:,syncFeature) == 1);

        %% skip if no valid sync point was selected
        if (isempty(interPhaseFrames))
            continue;
        end

        %% get the reference feature value as the mean value of the interphase frames
        referenceFeatureValue = mean(d_orgs(i, interPhaseFrames, f));

        %% compute the recovery as ratio or percentage depending on the selected mode
        if (mode == 1)
            normalizedFeatureValues = d_orgs(i, :, f) / referenceFeatureValue;
        elseif (mode == 2)
            normalizedFeatureValues = d_orgs(i, :, f);
            smallerIndices = find(normalizedFeatureValues <= referenceFeatureValue);
            largerIndices = find(normalizedFeatureValues > referenceFeatureValue);
            
            normalizedFeatureValues(smallerIndices) = normalizedFeatureValues(smallerIndices) ./ referenceFeatureValue;
            normalizedFeatureValues(largerIndices) = referenceFeatureValue ./ normalizedFeatureValues(largerIndices);
        elseif (mode == 3)
            normalizedFeatureValues = 100 * (d_orgs(i, :, f) - referenceFeatureValue) / referenceFeatureValue;
        elseif (mode == 4)
            normalizedFeatureValues = 100 * abs(d_orgs(i, :, f) - referenceFeatureValue) / referenceFeatureValue;
        end        
        
        %% set the feature values
        if (sum(isinf(normalizedFeatureValues)) == 0)
            d_orgs(i, :, end) = normalizedFeatureValues;
        else
            disp(['Inf detected, removing cell ' num2str(i) ' from the valid cells!!']);
            d_orgs(i, :, syncFeature) = 0;
        end
    end
end

%% update the time series
aktparawin;