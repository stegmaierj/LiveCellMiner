function relativeFrameNumbers = callback_livecellminer_get_relative_frame_numbers(IPTransition, MATransition, alignedLength, stepWidth)


relativeXTick = 0:stepWidth:alignedLength;
relativeFrameNumbers = zeros(1, length(relativeXTick));
relativeXTickLabels = cell(1,length(relativeXTick));
for j=1:length(relativeXTick)
    absoluteTime = relativeXTick(j);

    if (absoluteTime <= IPTransition)
        relativeXTickLabels{j} = ['-' num2str(IPTransition - relativeXTick(j))];
        relativeFrameNumbers(j) = -(IPTransition - relativeXTick(j));
    elseif (absoluteTime > IPTransition && relativeXTick(j) <= (IPTransition+((MATransition-IPTransition)/2)))
        relativeXTickLabels{j} = num2str(relativeXTick(j) - IPTransition);
        relativeFrameNumbers(j) = relativeXTick(j) - IPTransition;
    elseif (absoluteTime > (IPTransition+((MATransition-IPTransition)/2)) && absoluteTime < MATransition)
        relativeXTickLabels{j} = ['-' num2str(MATransition - relativeXTick(j))];
        relativeFrameNumbers(j) = -(MATransition - relativeXTick(j));
    else                
        relativeXTickLabels{j} = num2str(relativeXTick(j) - MATransition);
        relativeFrameNumbers(j) = relativeXTick(j) - MATransition;
    end

    if (str2double(relativeXTickLabels{j}) == 0)
        relativeXTickLabels{j} = '0';
    end
end