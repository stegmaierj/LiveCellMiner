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

%% get the manual synchronization time series
syncFeatureIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
meanIntensityFeatureIndex = callback_livecellminer_find_time_series(var_bez, 'MeanIntensity');
orientationFeatureIndex = callback_livecellminer_find_time_series(var_bez, 'Orientation');
if (orientationFeatureIndex <= 0 || syncFeatureIndex <= 0 || meanIntensityFeatureIndex <= 0)
   return; 
end

prompt = {'Enter the frame interval (min):'};
dlgtitle = 'Time Interval Settings';
dims = [1 35];
definput = {'3'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

numFramesOrientation = 8; %% uses the last numFramesOrientation before MA to compute the sum of angles
deltaT = str2double(answer{1}); %% duration between two frames in minutes

%% initialize a new feature and add a new specifier
d_org(:,end+1) = 0;
d_org(:,end+1) = 0;
d_org(:,end+1) = 0;
d_org(:,end+1) = 0;

%% add the specifier for the new single feature
if (size(d_org,2) == 1)
    dorgbez = char('IPToMALength_Frames', 'IPToMALength_Minutes', 'InterphaseMeanIntensity', 'MeanOrientationDiffPMA');
else
    dorgbez = char(dorgbez, 'IPToMALength_Frames', 'IPToMALength_Minutes', 'InterphaseMeanIntensity', 'MeanOrientationDiffPMA');
end
IPToMALengthFramesIndex = callback_livecellminer_find_single_feature(dorgbez, 'IPToMALength_Frames');
IPToMALengthMinutesIndex = callback_livecellminer_find_single_feature(dorgbez, 'IPToMALength_Minutes');
InterphaseMeanIntensityIndex = callback_livecellminer_find_single_feature(dorgbez, 'InterphaseMeanIntensity');
MeanOrientationDiffPMAIndex = callback_livecellminer_find_single_feature(dorgbez, 'MeanOrientationDiffPMA');

%% compute the number of frames between the IP and MA transition
for i=1:size(d_orgs,1)
    intIndices = find(d_orgs(i,:,syncFeatureIndex) == 1);
    pmaIndices = find(d_orgs(i,:,syncFeatureIndex) == 2);
    atiIndices = find(d_orgs(i,:,syncFeatureIndex) == 3);
    
    if (isempty(intIndices) || isempty(pmaIndices) || isempty(atiIndices))
        continue;
    end
    
    d_org(i, IPToMALengthFramesIndex) = length(pmaIndices);
    d_org(i, IPToMALengthMinutesIndex) = d_org(i, IPToMALengthFramesIndex) * deltaT;
    d_org(i, InterphaseMeanIntensityIndex) = mean(d_orgs(i, intIndices, meanIntensityFeatureIndex));
    d_org(i, MeanOrientationDiffPMAIndex) = mean(abs(diff(d_orgs(i, pmaIndices, orientationFeatureIndex))));   
end

%% update the GUI for the new time series to show up
aktparawin;