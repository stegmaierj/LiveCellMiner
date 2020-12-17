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

helpText = {'1;2;3: Toggles the visualization of raw, mask, raw+mask overlay'; ...
            'Left Arrow: Load previous montage'; ...
            'Right Arrow: Load next montage'; ...
            'Left click: Set the IP and MA transition points';...
            'Right click: Reject current cell track (highlighted in red)';...
            'G: Add currently visible cells to the confirmed ground truth (used for the LSTM classifier)';...
            'H: Show this help dialog so you probably already know about this button :-)'; ...
            '';...
            'Hint: In case key presses show no effect, left click once on the image and try hitting the button again. This only happens if the window loses the focus.'};

helpdlg(helpText);