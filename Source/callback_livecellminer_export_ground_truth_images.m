
debugFigures = false;
outputFolder = uigetdir();

%% find the manual synchronization index
oldSelection = parameter.gui.merkmale_und_klassen.ind_zr;
set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'manualSynchronization'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
synchronizationIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'StdIntensity'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
stdIntensityIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'MeanIntensity'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
meanIntensityIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set_textauswahl_listbox(gaitfindobj('CE_Auswahl_ZR'),{'Area'});eval(gaitfindobj_callback('CE_Auswahl_ZR'));
areaIndex = parameter.gui.merkmale_und_klassen.ind_zr;

set(gaitfindobj('CE_Auswahl_ZR'),'value', oldSelection);
aktparawin;

%% check if precached ata exists
dataPrecached = exist('rawImagePatches', 'var') && exist('maskImagePatches', 'var');

%% initialize the color map for debugging
colorMapHSV = hsv(360);

%% process all selected cells
for i=ind_auswahl'
    
    %% load  the current raw snippet and the mask
    if (dataPrecached == false)
        currentImage = double(loadtiff(parameter.projekt.imageFiles{i,1}));
        currentMask = double(loadtiff(parameter.projekt.imageFiles{i,2}) > 0);
        numFrames = size(currentImage,3);
    else
        numFrames = size(rawImagePatches, 2);
    end
    
    currentFeatures = squeeze(d_orgs(i,:,:));
    
    %% perform the stage assignment
    intFrames = find(currentFeatures(:, synchronizationIndex) == 1);
    pmaFrames = find(currentFeatures(:, synchronizationIndex) == 2);
    atiFrames = find(currentFeatures(:, synchronizationIndex) == 3);
    
    if (isempty(intFrames) || isempty(pmaFrames) || isempty(atiFrames))
        continue;
    end
        
    %% approximate the prophase vs. metaphase transition
    pmaFeatures = currentFeatures(pmaFrames, areaIndex);
    meanArea = median(pmaFeatures);
    framesBelowMean = find(pmaFeatures < meanArea);
    proFrames = pmaFrames(1:framesBelowMean(1));
    metFrames = pmaFrames((framesBelowMean(1)+1):end);
    
    %% approximate the recovery
    %% get the reference feature value as the mean value of the interphase frames
    referenceFeatureValue = mean(currentFeatures(intFrames, stdIntensityIndex));

    %% compute the recovery as ratio or percentage depending on the selected mode
    normalizedFeatureValues = currentFeatures(atiFrames, stdIntensityIndex) / referenceFeatureValue;
    framesCloseToReference = find(abs(normalizedFeatureValues - 1) < 0.2);
    
    if (isempty(framesCloseToReference))
        continue;
    end
    
    anaFrames = atiFrames(1:framesCloseToReference(1));
    latiFrames = atiFrames((framesCloseToReference(1)+1):end);
    
    numIntFrames = length(intFrames) + length(latiFrames);
    numProFrames = length(proFrames);
    numMetFrames = length(metFrames);
    numAnaFrames = length(anaFrames);
    
    intAngles = 1:(89 / (numIntFrames-1)):90;
    proAngles = 91:(89 / (numProFrames-1)):180;
    metAngles = 181:(89 / (numMetFrames-1)):270;
    anaAngles = 271:(89 / (numAnaFrames-1)):360;
    
    completeAngles = zeros(numFrames,1);
    completeAngles([latiFrames; intFrames]) = round(intAngles);
    completeAngles(proFrames) = round(proAngles);
    completeAngles(metFrames) = round(metAngles);
    completeAngles(anaFrames) = round(anaAngles);
   
    raw_image = zeros(1, size(currentImage,3), size(currentImage,2), size(currentImage,1));
    dont_cares = zeros(1, size(currentImage,3), size(currentImage,2), size(currentImage,1));
    target_image = zeros(3, size(currentImage,3), size(currentImage,2), size(currentImage,1));
    
    for f=1:numFrames
        if (dataPrecached == true)
           raw_image(1, f, :, :) = rawImagePatches{i, f};
           dont_cares(1, f, :, :) = maskImagePatches{i, f};
           target_image(1, f, :, :) = maskImagePatches{i, f};
           target_image(2, f, :, :) = maskImagePatches{i, f} * completeAngles(f);
           target_image(3, f, :, :) = maskImagePatches{i, f} * currentFeatures(f, meanIntensityIndex);
        else
           raw_image(1, f, :, :) = currentImage(:,:,f);
           dont_cares(1, f, :, :) = currentMask(:,:,f);
           target_image(1, f, :, :) = currentMask(:,:,f);
           target_image(2, f, :, :) = currentMask(:,:,f) * completeAngles(f);
           target_image(3, f, :, :) = currentMask(:,:,f) * currentFeatures(f, meanIntensityIndex);
        end
    end
    
    currentCode = code_alle(i,:);
    
    hdf5write([outputFolder filesep zgf_y_bez(2, currentCode(2)).name '_' zgf_y_bez(3, currentCode(3)).name '_' strrep(zgf_y_bez(4, currentCode(4)).name, '.tif', '.h5')], '/raw_image', uint16(raw_image));
    hdf5write([outputFolder filesep zgf_y_bez(2, currentCode(2)).name '_' zgf_y_bez(3, currentCode(3)).name '_' strrep(zgf_y_bez(4, currentCode(4)).name, '.tif', '.h5')], '/dont_cares', uint8(dont_cares), 'WriteMode', 'append');
    hdf5write([outputFolder filesep zgf_y_bez(2, currentCode(2)).name '_' zgf_y_bez(3, currentCode(3)).name '_' strrep(zgf_y_bez(4, currentCode(4)).name, '.tif', '.h5')], '/target_image', uint16(target_image), 'WriteMode', 'append');
    
    %% fill the color map, i.e., the stage conditioning variable
    if (debugFigures == true)
        colorMap([latiFrames; intFrames], :) = colorMapHSV(round(intAngles), :);
        colorMap(proFrames, :) = colorMapHSV(round(proAngles), :);
        colorMap(metFrames, :) = colorMapHSV(round(metAngles), :);
        colorMap(anaFrames, :) = colorMapHSV(round(anaAngles), :);
        
        figure(2); clf;
        for j=1:30
           subplot(6,5,j); hold on;
           plot(pmaFrames, currentFeatures(pmaFrames, j), '-r');
           plot(minIndex, currentFeatures(minIndex, j), '*g');
           title(kill_lz(var_bez(j,:)));
        end

        %% debug figure for the stage assignment
        imageHeight = 90;
        imageWidth = 90;
        numRows = 9;
        numCols = 10;
        montageImage = zeros(90*numCols, 90*numRows, 3);
        montageMask = zeros(90*numCols, 90*numRows, 3);
        for j=1:numRows
            for k=1:numCols
                rangeX = ((k-1)*imageWidth+1):(k*imageWidth);
                rangeY = ((j-1)*imageHeight+1):(j*imageHeight);

                currentFrame = (j-1)*numCols + k;

                currentSnippet = imadjust(currentImage(:,:,currentFrame));
                montageImage(rangeY, rangeX, 1) = colorMap(currentFrame,1) * currentSnippet .* currentMask(:,:,currentFrame);
                montageImage(rangeY, rangeX, 2) = colorMap(currentFrame,2) * currentSnippet .* currentMask(:,:,currentFrame);
                montageImage(rangeY, rangeX, 3) = colorMap(currentFrame,3) * currentSnippet .* currentMask(:,:,currentFrame);

                montageMask(rangeY, rangeX, 1) = currentFeatures(currentFrame, meanIntensityIndex) * currentMask(:,:,currentFrame) / max(currentFeatures(:, meanIntensityIndex));
                montageMask(rangeY, rangeX, 2) = currentFeatures(currentFrame, meanIntensityIndex) * currentMask(:,:,currentFrame) / max(currentFeatures(:, meanIntensityIndex));
                montageMask(rangeY, rangeX, 3) = currentFeatures(currentFrame, meanIntensityIndex) * currentMask(:,:,currentFrame) / max(currentFeatures(:, meanIntensityIndex));                        
                test = 1;
            end
        end   

        figure(3);
        subplot(1,2,1);
        imagesc(montageImage);
        axis equal;
        axis tight;
        box off;

        subplot(1,2,2);
        imagesc(montageMask);
        colormap gray;
        axis equal;
        axis tight;
        box off;
        tes = 1;
    end
end