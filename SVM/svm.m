data = readtable("combined_features.csv");

% Select 10 random HGG patients
hgg = data(strcmp(data{:,2}, 'HGG'),:);
hggtestsample = datasample(hgg, 10, 'Replace', false);
hggtrainsample = setdiff(hgg, hggtestsample);

% Select 10 random LGG patients
lgg = data(strcmp(data{:,2}, 'LGG'),:);
lggtestsample = datasample(lgg, 10, 'Replace', false);
lggtrainsample = setdiff(lgg, lggtestsample);

% Reduce datasets of each class to be same size
setsize = min(height(hggtrainsample), height(lggtrainsample));

% Synthesise testing and training samples
testsample = [hggtestsample; lggtestsample];
trainsample = [datasample(hggtrainsample, setsize, 'Replace', false); datasample(lggtrainsample, setsize, 'Replace', false)];