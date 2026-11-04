function save_statistics(S, outFile)
%SAVE_STATISTICS Write the per-electrode map statistics, replacing earlier rows of the same measures.
    if isfile(outFile)
        old = readtable(outFile, 'TextType', 'string');
        S = [old(~ismember(old.measure, unique(S.measure)), :); S];
    end
    writetable(S, outFile);
end
