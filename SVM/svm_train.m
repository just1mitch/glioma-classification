% Train and test a linear SVM
TESTSIZE = 10;
ITERATIONS = 1000;
DATAFILE = "combined_features.csv";

% Combine data in one csv (only needed once to create data)
% name_mapping_path = "path_to_name_mapping.csv";
% create_classifications(name_mapping_path);
% filelist = {".\Features\classifications.csv", ".\Features\conventional_features.csv", ".\Features\shapeFeatures.csv", ".\Features\textureFeatures.csv", ".\Features\intensityFeatures.csv"};
% combine_features(filelist, DATAFILE)

data = readtable(DATAFILE);

% Select 10 random HGG patients
hgg = data(strcmp(data{:,2}, 'HGG'),:);
hggtestsample = datasample(hgg, TESTSIZE, 'Replace', false);
hggtrainsample = setdiff(hgg, hggtestsample);

% Select 10 random LGG patients
lgg = data(strcmp(data{:,2}, 'LGG'),:);
lggtestsample = datasample(lgg, TESTSIZE, 'Replace', false);
lggtrainsample = setdiff(lgg, lggtestsample);

% Synthesise testing sample
testsample = [hggtestsample; lggtestsample];
testsample = testsample(:, 2:end);


% Calculate minimum set size of either class, to ensure model is trained
% with equal number of examples from each class
setsize = min(height(hggtrainsample), height(lggtrainsample));


% Used initially to generate classifier code
% classificationLearner(trainsample(:, 2:end), 'Grade');

bestclassifier = [];
bestaccuracy = 0;
avgaccuracy = 0;

% Run the classifier n=ITERATIONS times, and take the best classifier
% 'Best classifier' is determined by the classifier with highest training
% accuracy
for i = 1:ITERATIONS
    % Reduce datasets of each class to be same size
    % Training set changes each iteration by random sample from entire
    % dataset
    trainsample = [datasample(hggtrainsample, setsize, 'Replace', false); datasample(lggtrainsample, setsize, 'Replace', false)];

    % Generate SVM Classifier and its accuracy based on training sample
    [classifier, accuracy] = trainClassifier(trainsample(:, 2:end));
    if accuracy > bestaccuracy
        disp("New Highest Accuracy: " + accuracy + "(Iteration " + i + ")");
        bestclassifier = classifier;
        bestaccuracy = accuracy;
    end
    avgaccuracy = avgaccuracy + accuracy;
end

avgaccuracy = avgaccuracy / ITERATIONS;

% Check test data with best generated classifier
[yfit, ~] = bestclassifier.predictFcn(testsample);
answers = [repmat({'HGG'}, TESTSIZE, 1); repmat({'LGG'}, TESTSIZE, 1)];
results = strcmp(yfit, answers); % 1 for correct, 0 for false
results_accuracy = sum(results) / (TESTSIZE*2);

% Print results
disp("============== Linear SVM Classifier Results ==============");
disp("Training Sample Size: (" + setsize + " HGG, " + setsize + " LGG)");
disp("Testing Sample Size: (" + TESTSIZE + " HGG, " + TESTSIZE + " LGG)");
disp("Average SVM Training Accuracy (" + ITERATIONS + " Iterations): " + avgaccuracy * 100 + "%")
disp("Highest Training Accuracy: " + bestaccuracy * 100 + "%");
disp("Testing Accuracy with Best SVM: " + results_accuracy * 100 + "%");
