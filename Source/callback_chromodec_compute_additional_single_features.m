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

%% get the manual synchronization time series
syncFeatureIndex = callback_chromodec_find_time_series(var_bez, 'manualSynchronization');
meanIntensityFeatureIndex = callback_chromodec_find_time_series(var_bez, 'MeanIntensity');
orientationFeatureIndex = callback_chromodec_find_time_series(var_bez, 'Orientation');
if (orientationFeatureIndex <= 0 || syncFeatureIndex <= 0 || meanIntensityFeatureIndex <= 0)
   return; 
end

deltaT = 3;

%% initialize a new feature and add a new specifier
d_org(:,end+1) = 0;
d_org(:,end+1) = 0;
d_org(:,end+1) = 0;
d_org(:,end+1) = 0;

%% add the specifier for the new single feature
if (size(d_org,2) == 1)
    dorgbez = char('IPToMALength_Frames', 'IPToMALength_Minutes', 'InterphaseMeanIntensity', 'AccumulatedOrientationDiffPMA');
else
    dorgbez = char(dorgbez, 'IPToMALength_Frames', 'IPToMALength_Minutes', 'InterphaseMeanIntensity', 'AccumulatedOrientationDiffPMA');
end
IPToMALengthFramesIndex = callback_chromodec_find_single_feature(dorgbez, 'IPToMALength_Frames');
IPToMALengthMinutesIndex = callback_chromodec_find_single_feature(dorgbez, 'IPToMALength_Minutes');
InterphaseMeanIntensityIndex = callback_chromodec_find_single_feature(dorgbez, 'InterphaseMeanIntensity');
AccumulatedOrientationDiffPMAIndex = callback_chromodec_find_single_feature(dorgbez, 'AccumulatedOrientationDiffPMA');

%% compute the number of frames between the IP and MA transition
for i=1:size(d_orgs,1)
    intIndices = find(d_orgs(i,:,syncFeatureIndex) == 1);
    pmaIndices = find(d_orgs(i,:,syncFeatureIndex) == 2);
    atiIndices = find(d_orgs(i,:,syncFeatureIndex) == 3);
    
    d_org(i, IPToMALengthFramesIndex) = length(pmaIndices);
    d_org(i, IPToMALengthMinutesIndex) = d_org(i, IPToMALengthFramesIndex) * deltaT;
    d_org(i, InterphaseMeanIntensityIndex) = mean(d_orgs(i, intIndices, meanIntensityFeatureIndex));
    d_org(i, AccumulatedOrientationDiffPMAIndex) = sum(abs(diff(d_orgs(i, pmaIndices, orientationFeatureIndex))));    
end

%% update the GUI for the new time series to show up
aktparawin;