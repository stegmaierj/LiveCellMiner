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

function [] = callback_livecellminer_save_parameters_as_csv(parameters, outFileName)

    %% open output file
    fileID = fopen(outFileName, 'wb');
    
    %% get the field names
    currentFieldNames = fieldnames(parameters);

    %loop through the fields
    for i=1:numel(currentFieldNames)
        
        %% print the fieldname
        fprintf(fileID, '%s;', currentFieldNames{i});
        
        %% get the current data entry
        currentData = parameters.(currentFieldNames{i});
  
        %% write data depending on the data type after string conversion
        if (islogical(currentData))
            fprintf(fileID, '%s;', num2str(currentData));
        elseif (isnumeric(currentData))
            fprintf(fileID, '%s;', num2str(currentData));
        elseif (ischar(currentData))
            fprintf(fileID, '%s;', currentData);
        end

        %% start new line after each feature
        fprintf(fileID, '\n');
    end
    
    %% close the file handle
    fclose(fileID);
end