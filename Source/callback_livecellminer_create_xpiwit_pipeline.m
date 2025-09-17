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

function [XPIWITDetectionPipeline] = callback_livecellminer_create_xpiwit_pipeline(logMinSigma, logMaxSigma, seedDetectionThreshold, imageSpacing)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% specify paths to the external processing tools XPIWIT and Cellpose (only has to be setup once for the entire system)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    XPIWITDetectionPipeline = [tempdir 'CellDetection_minSigma=' sprintf('%.02f', logMinSigma) '_maxSigma=' sprintf('%.02f', logMaxSigma) '_seedDetThresh=' sprintf('%f', seedDetectionThreshold) '_micronsPerVoxel=' sprintf('%.02f', imageSpacing) '.xml'];
    
    currentFileDir = fileparts(mfilename('fullpath'));
    templateFile = sprintf('%s/toolbox/XPIWITPipelines/CellDetection_Template.xml', currentFileDir);

    fileIDTemplate = fopen(templateFile, 'rb');
    %fileIDTemplate = fopen([strrep(parameter.allgemein.pfad_gaitcad, '\', '/') '/application_specials/livecellminer/toolbox/XPIWITPipelines/CellDetection_TemplateTriet.xml'], 'rb');
    fileID = fopen(XPIWITDetectionPipeline, 'wb');

    while ~feof(fileIDTemplate)
        currentLine = fgetl(fileIDTemplate);
        currentLine = strrep(currentLine, '%IMAGE_SPACING%', sprintf('%f', imageSpacing));
        currentLine = strrep(currentLine, '%LOG_STD_THRESHOLD%', sprintf('%f', seedDetectionThreshold));
        currentLine = strrep(currentLine, '%LOG_MIN_SIGMA%', sprintf('%.02f', logMinSigma));
        currentLine = strrep(currentLine, '%LOG_MAX_SIGMA%', sprintf('%.02f', logMaxSigma));

        fprintf(fileID, '%s\n', currentLine);
    end

    fclose(fileIDTemplate);
    fclose(fileID);
end