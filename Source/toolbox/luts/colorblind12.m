function resultColorMap = colorblind12(numColors)

addpath('../hex_and_rgb_v1.1.1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Add colors here. 
%% There can also be more than 3 colors by just adding another line.
hexColors = ['#88CCEE'; '#CC6677'; '#DDCC77'; '#117733'; ...
             '#332288'; '#AA4499'; '#44AA99'; '#999933'; ...
             '#882255'; '#661100'; '#6699CC'; '#888888'];
baseColors = hex2rgb(hexColors);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%% NO CHANGES NEEDED BELOW %%%%%%%

%% handle input parameters
if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      numColors = size(get(groot,'DefaultFigureColormap'),1);
   else
      numColors = size(f.Colormap,1);
   end
end

%% get the number of base colors
numBaseColors = size(baseColors, 1);

%% if enough base colors are available, simply return the base colors
if (numColors <= numBaseColors)
    resultColorMap = baseColors(1:numColors, :);

%% if more colors are requested, interpolate evenly between the base colors
else
    resultColorMap = zeros(numColors,3);
    resultColorMap(:,1) = interp1(1:numBaseColors, baseColors(:,1), 1:((numBaseColors-1)/(numColors-1)):numBaseColors);
    resultColorMap(:,2) = interp1(1:numBaseColors, baseColors(:,2), 1:((numBaseColors-1)/(numColors-1)):numBaseColors);
    resultColorMap(:,3) = interp1(1:numBaseColors, baseColors(:,3), 1:((numBaseColors-1)/(numColors-1)):numBaseColors);
end