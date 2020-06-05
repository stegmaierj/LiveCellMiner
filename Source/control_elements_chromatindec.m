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

function els = control_elements_chromatindec(parameter)
% function els = control_elements_chromatindec(parameter)
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

els = [];

%number of the handle - added as the last column for the handle matrix 
newcolumn = parameter.allgemein.uihd_column;

%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the first control element (here: a checkbox)
ec = 1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_ShowErrorBars';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Show Error Bars?';
%example for a checkbox
els(ec).style = 'checkbox';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.showErrorBars';
%default value at the start
els(ec).default = 1;
%help text in the context menu
els(ec).tooltext = 'If enabled, error bars are shown';
%callback for any action at the element, can be empty
%the function should be exist tn the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text, not neceessary for
%checkboxes
els(ec).bezeichner = [];

%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the first control element (here: a checkbox)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_DarkMode';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Dark mode?';
%example for a checkbox
els(ec).style = 'checkbox';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.darkMode';
%default value at the start
els(ec).default = 0;
%help text in the context menu
els(ec).tooltext = 'If enabled, plots will be displayed in a dark color scheme';
%callback for any action at the element, can be empty
%the function should be exist tn the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text, not neceessary for
%checkboxes
els(ec).bezeichner = [];


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the first control element (here: a checkbox)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_SummarizeSelectedExperiments';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Summarize experiments?';
%example for a checkbox
els(ec).style = 'checkbox';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.summarizeSelectedExperiments';
%default value at the start
els(ec).default = 1;
%help text in the context menu
els(ec).tooltext = 'If enabled, all corresponding oligos of selected experiments will be summarized';
%callback for any action at the element, can be empty
%the function should be exist tn the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text, not neceessary for
%checkboxes
els(ec).bezeichner = [];


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the first control element (here: a checkbox)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_AlignPlots';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Align Plots?';
%example for a checkbox
els(ec).style = 'checkbox';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.alignPlots';
%default value at the start
els(ec).default = 1;
%help text in the context menu
els(ec).tooltext = 'If enabled, plots will be aligned automatically';
%callback for any action at the element, can be empty
%the function should be exist tn the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text, not neceessary for
%checkboxes
els(ec).bezeichner = [];


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_RegressionTimeRange';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Rel. Regression Time Range';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.regressionTimeRange';
%default value at the start
els(ec).default = [1, 5];
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'Frames relative to the sync. time point to use for linear regression. 1-5 uses the feature values of the 5 frames after the sync timepoint for linear regression.';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;

%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_ErrorStep';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Error Bar Step';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.errorStep';
%default value at the start
els(ec).default = 5;
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'Step size used for error bar plotting.';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_AlignedLength';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Aligned Length';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.alignedLength';
%default value at the start
els(ec).default = 120;
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'Length of the heat maps or line plots in the aligned setting.';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;

%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_IPTransition';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'IP Transition';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.IPTransition';
%default value at the start
els(ec).default = 30;
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'Interphase-Prophase transition frame used to plot the aligned feature maps.';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;

%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_SmoothingMethod';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Smoothing Method';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.SmoothingMethod';
%default value at the start
els(ec).default = 'rloess';
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'The smoothing method to be used (moving, lowess, loess, sgolay, rlowess, rloess).';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;

%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_SmoothingWindow';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Smoothing Window';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.SmoothingWindow';
%default value at the start
els(ec).default = 5;
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'Window size used for smoothing of time series (default: 5).';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_MATransition';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'MA Transition';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.MATransition';
%default value at the start
els(ec).default = 60;
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = 'Metaphase-Anaphase transition frame used to plot the aligned feature maps.';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_RecoveryMeasureMode';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Recovery Measure Mode';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.recoveryMeasureMode';
%default value at the start
els(ec).default = 1;
%defines if the values should be integer values (=1) or not
els(ec).ganzzahlig = 1;
%defines the possible values, Inf is also possible
els(ec).wertebereich = {1, Inf};
%help text in the context menu
els(ec).tooltext = '1: current vs. target ratio, 2: always increasing ratio, 3: signed percentage deviation, 4: absolute percentage deviation.';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;


%%%%%%%%%%%%%%%%%%%%%%%
% ChromatinDec for the second control element (here: a edit field for numbers)
ec = ec+1; 
%Tag for the handling of the elements, the name must be unique
els(ec).tag = 'CE_ChromatinDec_SummaryOutputVariable';
%number of the handle - added as the last column for the handle matrix 
els(ec).uihd_code = [newcolumn ec]; 
els(ec).handle = [];
%name shown in the GUI
els(ec).name = 'Summary Output Variable';
%example for a checkbox
els(ec).style = 'edit';
%the variable can be use for the access to the element value
els(ec).variable = 'parameter.gui.chromatindec.summaryOutputVariable';
%default value at the start
els(ec).default = 'Experiment';
%help text in the context menu
els(ec).tooltext = 'Default: Experiment, Alternative Option: ExperimentsCombined';
%callback for any action at the element, can be empty
%the function should be exist in the path of the chromatindec package
els(ec).callback = '';
%width of the element in points
els(ec).breite = 200;
%hight of the element in points
els(ec).hoehe = 20;
%optional handle of an additional GUI element with an explanation text
els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
els(ec).bezeichner.handle = [];
%width of the explanation text for the element in points
els(ec).bezeichner.breite = 250;
%height of the explanation text for the element in points
els(ec).bezeichner.hoehe = 20;


% %%%%%%%%%%%%%%%%%%%%%%%
% % ChromatinDec for the third control element (here: a popup field)
% ec = ec+1; 
% %Tag for the handling of the elements, the name must be unique
% els(ec).tag = 'CE_ChromatinDec_Popup1';
% %number of the handle - added as the last column for the handle matrix 
% els(ec).uihd_code = [newcolumn ec]; 
% els(ec).handle = [];
% %name shown in the GUI
% els(ec).name = 'Element_Popup1';
% %example for a checkbox
% els(ec).style = 'popupmenu';
% %the variable can be use for the access to the element value
% els(ec).variable = 'parameter.gui.chromatindec.popup1';
% %default value at the start
% els(ec).default = 3;
% %defines the entries of the popup
% els(ec).listen_werte = 'Option A (red)|Option B (green)|Option C (blue)';
% %help text in the context menu
% els(ec).tooltext = 'Help text for popup 1';
% %callback for any action at the element, can be empty
% %the function should be exist tn the path of the chromatindec package
% els(ec).callback = '';
% %width of the element in points
% els(ec).breite = 250;
% %hight of the element in points
% els(ec).hoehe = 20;
% %optional handle of an additional GUI element with an explanation text
% els(ec).bezeichner.uihd_code = [newcolumn+1 ec];
% els(ec).bezeichner.handle = [];
% %width of the explanation text for the element in points
% els(ec).bezeichner.breite = 250;
% %height of the explanation text for the element in points
% els(ec).bezeichner.hoehe = 20;




