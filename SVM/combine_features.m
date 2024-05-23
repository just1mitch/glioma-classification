% Takes a list of csv files (filelist) and an output csv to write data to
% Concatenates each csv horizontally together
function combine_features(filelist, output)
    combined = readtable(filelist{1});

    for file = 2:length(filelist)
        tbl = readtable(filelist{file});
        combined = [combined, tbl];
    end
    writetable(combined, output)
end


