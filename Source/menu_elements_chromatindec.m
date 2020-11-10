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

function elements = menu_elements_chromatindec(parameter)
% function elements = menu_elements_chromatindec(parameter)
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


newcolumn = parameter.allgemein.uihd_column;
mc = 1;

%main element in the menu
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
%the tag must be unique
elements(mc).tag = 'MI_ChromatinDec';
%name in the menu
elements(mc).name = 'ChromatinDec';
%list of the functions in the menu, -1 is a separator
elements(mc).menu_items = {'MI_ChromatinDec_Import', 'MI_ChromatinDec_Align', 'MI_ChromatinDec_Show', 'MI_ChromatinDec_Process'};
%is always enabled if a project exists
%further useful option: elements(mc).freischalt = {'1'}; %is always enabled
elements(mc).freischalt = {'1'}; 

%%%%%%%% IMPORT %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Import';
elements(mc).tag = 'MI_ChromatinDec_Import';
elements(mc).menu_items = {'MI_ChromatinDec_External_Dependencies', 'MI_ChromatinDec_Import_Project', 'MI_ChromatinDec_Fuse_Projects'};


%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Set External Dependencies';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_set_external_dependencies;';
elements(mc).tag = 'MI_ChromatinDec_External_Dependencies';
%is enabled if at least one time series exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Import New Experiment';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_batch_processing;';
elements(mc).tag = 'MI_ChromatinDec_Import_Project';
%is enabled if at least one time series exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Fuse Experiments';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_fuse_projects;';
elements(mc).tag = 'MI_ChromatinDec_Fuse_Projects';
%is enabled if at least one time series exist
elements(mc).freischalt = {};

%%%%%%%%%% ALIGN %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Align';
elements(mc).tag = 'MI_ChromatinDec_Align';
elements(mc).menu_items = {'MI_ChromatinDec_PreloadImageSnippets', 'MI_ChromatinDec_PerformAutoSync', 'MI_ChromatinDec_ShowAutoSyncOverview', 'MI_ChromatinDec_FindInconsistentSynchronizations',  'MI_ChromatinDec_PerformManualSynchronization', 'MI_ChromatinDec_UpdateLSTMClassifier'};


%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Preload Image Snippets and CNN Features';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_load_image_files;';
elements(mc).tag = 'MI_ChromatinDec_PreloadImageSnippets';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Perform Auto Sync';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_perform_auto_sync;';
elements(mc).tag = 'MI_ChromatinDec_PerformAutoSync';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Find Inconsistent Synchronizations';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_find_invalid_synchronization_indices;';
elements(mc).tag = 'MI_ChromatinDec_FindInconsistentSynchronizations';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Show Auto-Sync Overview';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_show_auto_sync_overview;';
elements(mc).tag = 'MI_ChromatinDec_ShowAutoSyncOverview';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Perform Manual Synchronization';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_manual_synchronization_gui;';
elements(mc).tag = 'MI_ChromatinDec_PerformManualSynchronization';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};


%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Update LSTM Classifier';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_update_auto_sync_classifier;';
elements(mc).tag = 'MI_ChromatinDec_UpdateLSTMClassifier';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};


%%%%%%%%%% SHOW %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Show';
elements(mc).tag = 'MI_ChromatinDec_Show';
elements(mc).menu_items = {'MI_ChromatinDec_ShowHeatMaps', 'MI_ChromatinDec_ShowLinePlots', 'MI_ChromatinDec_ShowCombLinePlots', 'MI_ChromatinDec_ShowCombBoxPlots', 'MI_ChromatinDec_ShowCombHistogramPlots'};


%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Heatmaps';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'visualizationMode = 1; callback_chromatindec_show_heatmaps;';
elements(mc).tag = 'MI_ChromatinDec_ShowHeatMaps';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Line Plots';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'visualizationMode = 2; callback_chromatindec_show_heatmaps;';
elements(mc).tag = 'MI_ChromatinDec_ShowLinePlots';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};


%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Comb. Line Plots';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'visualizationMode = 2; callback_chromatindec_show_combined_plots;';
elements(mc).tag = 'MI_ChromatinDec_ShowCombLinePlots';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Comb. Box Plots';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'showHistogram = false; callback_chromatindec_show_combined_boxplots;';
elements(mc).tag = 'MI_ChromatinDec_ShowCombBoxPlots';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Comb. Histogram Plots';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'showHistogram = true; callback_chromatindec_show_combined_boxplots;';
elements(mc).tag = 'MI_ChromatinDec_ShowCombHistogramPlots';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};


%%%%%%% PROCESS %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Process';
elements(mc).tag = 'MI_ChromatinDec_Process';
elements(mc).menu_items = {'MI_ChromatinDec_PerformFeatureNormalization', 'MI_ChromatinDec_SmoothFeatures', 'MI_ChromatinDec_ComputeAdditionalSingleFeatures', 'MI_ChromatinDec_ComputeLinearRegressionSlope', 'MI_ChromatinDec_ComputeRelativeRecoveryTimeSeries', 'MI_ChromatinDec_AddOligoIDOutputVariable', 'MI_ChromatinDec_AddRepeatsOutputVariable', 'MI_ChromatinDec_SelSingleFeatureRange'};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Perform Feature Normalization';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_normalize_selected_time_series;';
elements(mc).tag = 'MI_ChromatinDec_PerformFeatureNormalization';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Smooth Selected Time Series';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_smooth_features;';
elements(mc).tag = 'MI_ChromatinDec_SmoothFeatures';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Compute Linear Regression Slope';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_compute_linear_regression_slope;';
elements(mc).tag = 'MI_ChromatinDec_ComputeLinearRegressionSlope';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Compute Rel. Recovery Time Series';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_compute_relative_recovery_time_series;';
elements(mc).tag = 'MI_ChromatinDec_ComputeRelativeRecoveryTimeSeries';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Compute Additional Single Features';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_compute_additional_single_features;';
elements(mc).tag = 'MI_ChromatinDec_ComputeAdditionalSingleFeatures';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Add OligoID Output Variable';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_add_oligoid_output_variable;';
elements(mc).tag = 'MI_ChromatinDec_AddOligoIDOutputVariable';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Add Repeats Output Variable';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_add_combined_experiment_output_variable;';
elements(mc).tag = 'MI_ChromatinDec_AddRepeatsOutputVariable';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};

%%%%%%%%%%%%%%%%%%%%%%%%
mc = mc+1;
elements(mc).uihd_code = [newcolumn mc];
elements(mc).handle = [];
elements(mc).name = 'Select Data Points using Feature Range';
elements(mc).delete_pointerstatus = 0;
elements(mc).callback = 'callback_chromatindec_select_based_on_single_feature_range;';
elements(mc).tag = 'MI_ChromatinDec_SelSingleFeatureRange';
%is enabled if at least one single feature exist
elements(mc).freischalt = {};



