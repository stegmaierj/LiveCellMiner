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

function felder = optionen_felder_chromatindec
% function felder = optionen_felder_chromatindec
%
% 
% 
%
% The function optionen_felder_chromatindec is part of the MATLAB toolbox SciXMiner. 
% Copyright (C) 2010  [Ralf Mikut, Tobias Loose, Ole Burmeister, Sebastian Braun, Andreas Bartschat, Johannes Stegmaier, Markus Reischl]


% Last file change: 15-Aug-2016 11:31:19
% 
% This program is free software; you can redistribute it and/or modify,
% it under the terms of the GNU General Public License as published by 
% the Free Software Foundation; either version 2 of the License, or any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License along with this program;
% if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA.
% 
% You will find further information about SciXMiner in the manual or in the following conference paper:
% 
% 
% Please refer to this paper, if you use SciXMiner for your scientific work.

fc = 1;
felder(fc).name = 'ChromatinDec';
felder(fc).subfeld = [];
felder(fc).subfeldbedingung = [];
felder(fc).visible = [];
felder(fc).in_auswahl = 1;

% BEGIN: DO NOT CHANGE THIS%PART%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Element: Optionen  
felder(fc).visible(end+1).i_control_elements = 'CE_Auswahl_Optionen';
felder(fc).visible(end).pos = [300 510];
felder(fc).visible(end).bez_pos_rel = [-280 -3];
% END: DO NOT CHANGE THIS%PART%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Element: Optionen
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_AlignPlots';
%relative position in the window here: 300 points from left and 30 from the bottom 
felder(fc).visible(end).pos = [300 30];
felder(fc).visible(end).bez_pos_rel = [];

% Element: Optionen
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_ShowErrorBars';
%relative position in the window here: 300 points from left and 30 from the bottom 
felder(fc).visible(end).pos = [300 60];
felder(fc).visible(end).bez_pos_rel = [];

% Element: Optionen
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_SummarizeSelectedExperiments';
%relative position in the window here: 300 points from left and 30 from the bottom 
felder(fc).visible(end).pos = [300 90];
felder(fc).visible(end).bez_pos_rel = [];


% Element: Optionen
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_DarkMode';
%relative position in the window here: 300 points from left and 30 from the bottom 
felder(fc).visible(end).pos = [300 120];
felder(fc).visible(end).bez_pos_rel = [];


%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_ErrorStep';
felder(fc).visible(end).pos = [300 150];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_RegressionTimeRange';
felder(fc).visible(end).pos = [300 180];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_AlignedLength';
felder(fc).visible(end).pos = [300 210];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_SisterDistanceThreshold';
felder(fc).visible(end).pos = [300 240];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_MATransition';
felder(fc).visible(end).pos = [300 270];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_IPTransition';
felder(fc).visible(end).pos = [300 300];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_SmoothingWindow';
felder(fc).visible(end).pos = [300 330];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_SmoothingMethod';
felder(fc).visible(end).pos = [300 360];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_RecoveryMeasureMode';
felder(fc).visible(end).pos = [300 390];
felder(fc).visible(end).bez_pos_rel = [-280 -3];

%%%%%%%%%%%%%%%%%%
% Element: Linke/Rechte Einzüge verwenden
felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_SummaryOutputVariable';
felder(fc).visible(end).pos = [300 420];
felder(fc).visible(end).bez_pos_rel = [-280 -3];



% %%%%%%%%%%%%%%%%%%
% % Element: Linke/Rechte Einzüge verwenden
% felder(fc).visible(end+1).i_control_elements = 'CE_ChromatinDec_Popup1';
% felder(fc).visible(end).pos = [300 90];
% felder(fc).visible(end).bez_pos_rel = [-280 -3];



