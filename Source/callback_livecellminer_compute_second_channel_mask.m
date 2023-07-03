function maskImageCh2 = callback_livecellminer_compute_second_channel_mask(maskImage, strelType, strelRadius, extractionMode, toroidalPadding)

    structuringElement = strel(strelType, strelRadius);

    %% compute the mask
    if (extractionMode == 0)
        maskImageCh2 = imdilate(maskImage, structuringElement);
    elseif (extractionMode == 1)
        maskImageCh2 = imerode(maskImage, structuringElement);
    elseif (extractionMode == 2)
        maskImageCh2 = imdilate(maskImage, structuringElement) - maskImage;
    elseif (extractionMode == 3)
        dilatedMaskImage = imdilate(maskImage, strel(strelType, toroidalPadding));
        maskImageCh2 = imdilate(dilatedMaskImage, structuringElement) - dilatedMaskImage;
    else
        disp('Error: Unknown mode for extraction of second channel features. Please double-check parameterization!');
        maskImageCh2 = maskImage;
    end
end