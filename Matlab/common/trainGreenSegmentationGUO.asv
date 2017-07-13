function tree = trainGreenSegmentationGUO(im)

% INPUT
% im : image to train on
% OUTPUT
% tree : the random forest model

% This interactive tool helps you select pixels to train on
[training_set, label_set] = extractTrainingPixels(im);
% Several colorspaces are extracted from the selected pixels
colorSpace = colorExtraction(training_set);
RGB = colorSpace.RGB;
YCbCr = colorSpace.YCbCr;
HSL = colorSpace.HSL;
HSV = colorSpace.HSV;
Lab = colorSpace.Lab;
Luv = colorSpace.Luv;

% You may select which of the color spaces you want to train with
Tbl = [RGB,YCbCr,HSL,HSV,Lab,Luv];
% Perform the training
tree = fitctree(Tbl,label_set);