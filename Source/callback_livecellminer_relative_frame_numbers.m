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

stepWidth = parameter.gui.livecellminer.frameStepWidth;
relativeXTick = 0:stepWidth:alignedLength;
relativeXTickLabels = cell(1,length(relativeXTick));
for j=1:length(relativeXTick)
    absoluteTime = relativeXTick(j);

    if (absoluteTime <= IPTransition)
        relativeXTickLabels{j} = ['-' num2str(IPTransition - relativeXTick(j))];
    elseif (absoluteTime > IPTransition && relativeXTick(j) <= (IPTransition+((MATransition-IPTransition)/2)))
        relativeXTickLabels{j} = num2str(relativeXTick(j) - IPTransition);
    elseif (absoluteTime > (IPTransition+((MATransition-IPTransition)/2)) && absoluteTime < MATransition)
        relativeXTickLabels{j} = ['-' num2str(MATransition - relativeXTick(j))];
    else                
        relativeXTickLabels{j} = num2str(relativeXTick(j) - MATransition);
    end

    if (str2double(relativeXTickLabels{j}) == 0)
        relativeXTickLabels{j} = '0';
    end
end

set(gca, 'XTick', relativeXTick, 'XTickLabels', relativeXTickLabels);