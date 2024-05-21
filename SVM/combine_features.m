filelist = {"classifications.csv", "..\Features\shapeFeatures.csv", "..\Features\textureFeatures.csv", "..\Features\intensityFeatures.csv"};

combined = readtable(filelist{1});

for file = 2:length(filelist)
    tbl = readtable(filelist{file});
    combined = [combined, tbl];
end
writetable(combined, "combined_features.csv")