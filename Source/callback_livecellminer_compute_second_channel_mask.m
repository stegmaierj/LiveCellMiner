function maskImageCh2 = callback_livecellminer_compute_second_channel_mask(maskImage, strelType, strelRadius, extractionMode, toroidalPadding)

    structuringElement = strel(strelType, abs(strelRadius));

    %% compute the mask
    if (extractionMode == 0)
        maskImageCh2 = imdilate(maskImage, structuringElement);
    elseif (extractionMode == 1)
        maskImageCh2 = imerode(maskImage, structuringElement);
    elseif (extractionMode == 2 || extractionMode == 3)
        if (toroidalPadding > 0 && extractionMode == 3)
            maskImage = imdilate(maskImage, strel(strelType, abs(toroidalPadding)));
        elseif (toroidalPadding < 0 && extractionMode == 3)
            maskImage = imerode(maskImage, strel(strelType, abs(toroidalPadding)));
        end

        if (strelRadius > 0)
            maskImageCh2 = imdilate(maskImage, structuringElement) - maskImage;
        else
            maskImageCh2 = maskImage - imerode(maskImage, structuringElement);
        end        
    else
        disp('Error: Unknown mode for extraction of second channel features. Please double-check parameterization!');
        maskImageCh2 = maskImage;
    end
end