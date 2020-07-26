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

function outputVariableId = callback_chromatindec_find_output_variable(bez_code, outputVariableName)

	%% check if the specified output variable is present in the char list
    outputVariableId = 0;
    for i=1:size(bez_code,1)
        if (contains(bez_code(i,:), outputVariableName, 'IgnoreCase', true))
            outputVariableId = i;
            return;
        end
    end

	%% return 0 if not found
    if (outputVariableId == 0)
       disp('Output variables either for Experiment or for OligoID are missing!');
    end
end