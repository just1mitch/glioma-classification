% Get correct identifications
path = "path_to_name_mapping.csv";

metadata = readmatrix(path, OutputType='string');
metadata = [metadata(:, 6), metadata(:, 1)];

for i = 1:length(metadata)-1
    volume = metadata(i+1, 1).split('_');
    metadata(i+1, 1) = "volume_" +  volume(end);
end

writematrix(metadata, ".\classifications.csv", 'WriteMode', 'overwrite', Delimiter=',');