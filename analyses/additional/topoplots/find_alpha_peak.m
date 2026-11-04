function [peakHz, hasPeak] = find_alpha_peak(freq, dB)
%FIND_ALPHA_PEAK The child's alpha peak in a spectrum in dB, smoothed over 1 Hz.
%   Takes the most prominent local maximum from 8 to 13 Hz. With no local maximum there,
%   hasPeak is false and peakHz is the highest point of the band, so a child without a
%   peak stays in the maps with a low value instead of dropping out.
    binsPerHz = round(1 / median(diff(freq)));
    smooth = movmean(dB(:), binsPerHz);
    [isPeak, prominence] = islocalmax(smooth);
    inBand = freq(:) >= 8 & freq(:) <= 13;
    candidates = find(isPeak & inBand);
    hasPeak = ~isempty(candidates);
    if hasPeak
        [~, best] = max(prominence(candidates));
        peakHz = freq(candidates(best));
    else
        band = find(inBand);
        [~, best] = max(smooth(band));
        peakHz = freq(band(best));
    end
end
