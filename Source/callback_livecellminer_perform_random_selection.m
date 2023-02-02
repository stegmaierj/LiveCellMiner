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

%% ask for the number of cells to select
prompt = {'Number of Cell Pairs (both sisters will be selected):', 'Random Seed (adapt to reproduce previous selection):'};
dlgtitle = 'Random Cell Selection';
dims = [1 35];
definput = {'100', num2str(randi(100000))};
answer = inputdlg(prompt,dlgtitle,dims,definput);


rng(str2double(answer{2}));
numSelectedCells = str2double(answer{1});
numCells = size(d_orgs,1);

selectedIndices2 = sort(randperm(numCells/2, numSelectedCells) * 2);
selectedIndices1 = selectedIndices2 - 1;

selectedIndices = zeros(numSelectedCells*2, 1);
selectedIndices(1:2:(2*numSelectedCells)) = selectedIndices1;
selectedIndices(2:2:(2*numSelectedCells)) = selectedIndices2;

%% copy selected indices to the actual selection of LCM
ind_auswahl = selectedIndices;
aktparawin;

