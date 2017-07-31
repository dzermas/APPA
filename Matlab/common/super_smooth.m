%% Uses the superpixels method of Matlab to avoid any dependencies to external libraries such as vlfeat
function [centroids, outputImage] = super_smooth(im, spNum)
% Input:
%   im: original image
%   spNum: number of superpixels to roughly segment the original image (the actual number of sp is <= spNum)
% Output:
%   centroids: a struct that hold info on the centroids of all the superpixels
%       - centroids.rgb: the mean RGB value 1x3 of a superpixel
%       - centroids.idx: the index of pixels belonging to the superpixel
%   outputImage: the resulting segmented image, useful for visualization purposes

% Superpixels
[L,N] = superpixels(im,spNum);

outputImage = zeros(size(im),'like',im);
idx = label2idx(L);
numRows = size(im,1);
numCols = size(im,2);
rgb = zeros(N,3);
for labelVal = 1:N
    redIdx = idx{labelVal};
    greenIdx = idx{labelVal}+numRows*numCols;
    blueIdx = idx{labelVal}+2*numRows*numCols;
    outputImage(redIdx) = mean(im(redIdx));
    outputImage(greenIdx) = mean(im(greenIdx));
    outputImage(blueIdx) = mean(im(blueIdx));
    rgb(labelVal,:) = [mean(im(redIdx)) mean(im(greenIdx)) mean(im(blueIdx))];
end    

centroids.rgb = rgb;
centroids.idx = idx;

%figure
%imshow(outputImage,'InitialMagnification',67)