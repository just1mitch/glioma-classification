% Takes a list of csv files (filelist) and an output csv to write data to
% Concatenates each csv horizontally together
function combine_features(filelist, output)
    combined = readtable(filelist{1});

    for file = 2:length(filelist)
        tbl = readtable(filelist{file});
        if strcmp(filelist{file}, ".\Features\conventional_features.csv")
            tbl = tbl(:,2:end);
        end
        combined = [combined, tbl];
    end
    writetable(combined, output)
end


