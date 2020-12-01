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
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
syncFeature = parameter.gui.merkmale_und_klassen.ind_zr;
deltaT = 3;

set(gaitfindobj('CE_Auswahl_ZR'), 'value', oldSelection);
aktparawin;

%% get the selected time series
selectedTimeSeries = parameter.gui.merkmale_und_klassen.ind_zr;
regressionTimeRange = generate_rowvector(parameter.gui.chromatindec.regressionTimeRange);

%% process all time series and compute the 1st order derivatives using forward differences
for f=generate_rowvector(selectedTimeSeries)
    
    %% initialize a new feature and add a new specifier
    d_org(:,end+1) = 0;
    currentFeatureIndex = size(d_org,2);
    
    if (size(d_org,2) == 1)
        dorgbez = [kill_lz(var_bez(f, :)) '-AvgBeforeIP-' num2str(regressionTimeRange(1)) '-' num2str(regressionTimeRange(2))];
    else
        dorgbez = char(dorgbez, [kill_lz(var_bez(f, :)) '-AvgBeforeIP-' num2str(regressionTimeRange(1)) '-' num2str(regressionTimeRange(2))]);
    end
    
    for i=1:size(d_orgs,1)
       validFrames = find(d_orgs(i, :, syncFeature) == 1);
       
       %% skip cells that were not synched properly
       if (isempty(validFrames))
           d_org(i, currentFeatureIndex) = 0;
           continue;
       end
       
       
       selectedValues = d_orgs(i, validFrames((end-min(length(validFrames), max(regressionTimeRange))+1):end), f);
       
       d_org(i, currentFeatureIndex) = mean(selectedValues);
    end    
end

%% update the GUI for the new time series to show up
aktparawin;