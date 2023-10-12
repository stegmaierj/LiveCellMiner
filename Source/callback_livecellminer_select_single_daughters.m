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

answer = questdlg('Which cells should be selected?', 'Which cells should be selected?', 'Odd Indices?', 'Even Indices?', 'Random Indices?', 'Odd Indices?');

numSelectedCells = length(ind_auswahl);
oddIndices = ind_auswahl(mod(ind_auswahl,2) == 1);
evenIndices = ind_auswahl(mod(ind_auswahl,2) == 0);

% Handle response
switch answer
    case 'Odd Indices?'
        if (isempty(oddIndices))
            disp('There are no odd indices in the current selection.');
            return;
        else
            disp('Selecting all daughters with an odd index.');
            ind_auswahl = oddIndices;
        end        
    case 'Even Indices?'
        if (isempty(evenIndices))
            disp('There are no even indices in the current selection.');
            return;
        else
            disp('Selecting all daughters with an even index.');
            ind_auswahl = evenIndices;
        end
        
    case 'Random Indices?'

        if (length(evenIndices) ~= length(oddIndices))
            disp('Invalid base selection, the number of odd and even indices does not match.');
        else
            disp('Randomly selecting either odd or even index for each daughter pair.');

            randomIndices = zeros(numSelectedCells/2, 1);
            for i=1:(numSelectedCells/2)
                if (rand <= 0.5)
                    randomIndices(i) = oddIndices(i);
                else
                    randomIndices(i) = evenIndices(i);
                end
            end
    
            ind_auswahl = randomIndices;
        end
end

aktparawin;