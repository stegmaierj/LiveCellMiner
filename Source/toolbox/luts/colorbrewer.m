function resultColorMap = colorbrewer(numColors)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Add colors here. 
%% There can also be more than 3 colors by just adding another line.
baseColors = [165,0,38; ...
              215,48,39; ...
              244,109,67; ...
              253,174,97; ...
              254,224,144; ...
              255,255,191; ...
              224,243,248; ...
              171,217,233; ...
              116,173,209; ...
              69,117,180; ...
              49,54,149] / 255;
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
    resultColorMap = baseColors(round(1:(numBaseColors/numColors):numBaseColors), :);

%% if more colors are requested, interpolate evenly between the base colors
else
    resultColorMap = zeros(numColors,3);
    resultColorMap(:,1) = interp1(1:numBaseColors, baseColors(:,1), 1:((numBaseColors-1)/(numColors-1)):numBaseColors);
    resultColorMap(:,2) = interp1(1:numBaseColors, baseColors(:,2), 1:((numBaseColors-1)/(numColors-1)):numBaseColors);
    resultColorMap(:,3) = interp1(1:numBaseColors, baseColors(:,3), 1:((numBaseColors-1)/(numColors-1)):numBaseColors);
end