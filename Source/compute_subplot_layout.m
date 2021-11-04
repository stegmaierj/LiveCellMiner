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

function [numRows, numColumns] = compute_subplot_layout(numSubPlots)

    switch(numSubPlots)
        case 1
            numRows = 1;
            numColumns = 1;
        case 2
            numRows = 1;
            numColumns = 2;
        case 3
            numRows = 1;
            numColumns = 3;
        case 4
            numRows = 2;
            numColumns = 2;
        case 5
            numRows = 2;
            numColumns = 3;
        case 6
            numRows = 2;
            numColumns = 3;
        case 7
            numRows = 2;
            numColumns = 4;
        case 8
            numRows = 2;
            numColumns = 4;
        case 9
            numRows = 3;
            numColumns = 3;
        case 10
            numRows = 2;
            numColumns = 5;
        case 11
            numRows = 3;
            numColumns = 4;
        case 12
            numRows = 3;
            numColumns = 4;
        case 13
            numRows = 3;
            numColumns = 5;
        case 14
            numRows = 3;
            numColumns = 5;
        case 15
            numRows = 3;
            numColumns = 5;
        case 16
            numRows = 4;
            numColumns = 4;
        otherwise
            numRows = ceil(sqrt(numSubPlots));
            numColumns = ceil(sqrt(numSubPlots));
    end
end