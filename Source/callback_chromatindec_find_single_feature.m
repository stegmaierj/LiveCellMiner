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

function featureId = callback_chromatindec_find_single_feature(dorgbez, featureName)

	%% check if feature is present among dorgbez
    featureId = 0;
    for i=1:size(dorgbez,1)
        if (contains(dorgbez(i,:), featureName, 'IgnoreCase', true))
            featureId = i;
            return;
        end
    end

	%% return 0 if feature was not found
    if (featureId == 0)
       disp('Desired single feature was not found!');
    end
end