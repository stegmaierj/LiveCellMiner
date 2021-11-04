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

syncIndex = callback_livecellminer_find_time_series(var_bez, 'manualSynchronization');
manuallyCheckedIndex = callback_livecellminer_find_single_feature(dorgbez, 'manuallyConfirmed');

zgf_y_bez_old = zgf_y_bez;
d_orgs_old = d_orgs(:,:,syncIndex);
d_org_old = d_org(:,manuallyCheckedIndex);
code_alle_old = code_alle;
bez_code_old = bez_code;

outputFileName = [parameter.projekt.pfad filesep parameter.projekt.datei '_SyncExport.mat'];
save(outputFileName, 'zgf_y_bez_old', 'd_orgs_old', 'd_org_old', 'code_alle_old', 'bez_code_old');

disp(['Synchronization saved to : ' outputFileName]);