% Get correct classifications for glioma scans
% Saves the classifications to a csv called 'classifications.csv
function create_classifications(path)    
    metadata = readmatrix(path, OutputType='string');
    metadata = [metadata(:, 6), metadata(:, 1)];
    
    for i = 1:length(metadata)-1
        volume = metadata(i+1, 1).split('_');
        metadata(i+1, 1) = "volume_" +  volume(end);
    end
    
    writematrix(metadata, ".\classifications.csv", 'WriteMode', 'overwrite', Delimiter=',');
end