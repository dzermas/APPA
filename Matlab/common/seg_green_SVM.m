% Multiclustering segmentation method with a combined RGB_LAB colorspace (R^6 clustering)
function clustered_green = seg_green_SVM(im, centroids, svmstruct_green)
% Input:
%   im: original image
%   centroids: a struct that hold info on the centroids of all the superpixels
%       - centroids.rgb: the mean RGB value 1x3 of a superpixel
%       - centroids.idx: the index of pixels belonging to the superpixel
%   svmstruct_green: SVM model based on the fitcsvm Matlab function
% Output:
%   clustered_green: image with only the original green colors

d_rgb = uint8(centroids.rgb);

% L*a*b transformation
cform = makecform('srgb2lab');
d_lab = applycform(d_rgb,cform);

% Prepare data for kmeans
d = single([d_rgb d_lab]);

%% Kmeans
% repeat the clustering 3 times to avoid local minima
reps = 3;
nClasses = 15;

[cluster_idx, cluster_center] = kmeans(d, nClasses,...
    'Distance','sqEuclidean', 'Replicates', reps);


rgb_label = uint8(zeros(size(im,1), size(im,2), size(im,3)));
for i=1:size(d,1)
    [x,y] = ind2sub([size(im,1) size(im,2)], centroids.idx{i});
    for j=1:length(x)
        rgb_label(x(j),y(j),:) = cluster_idx(i);
    end
end

%% Extract clusters
segmented_images = cell(1,nClasses);

for k = 1:nClasses
    color = im;
    color(rgb_label ~= k) = 0;
    segmented_images{k} = color;
end

%% SVM classification - Classifying the cluster centroids
% The SVM classification is setup such that label == 1 is green pixels!!!
label = predict(svmstruct_green, cluster_center);
clustered_rest = uint8(zeros(size(im)));
clustered_green = uint8(zeros(size(im)));
for i=1:nClasses
    switch label(i)
        case 0
            clustered_rest = clustered_rest + segmented_images{i};
        case 1
            clustered_green = clustered_green + segmented_images{i};            
    end
    % imshow(clustered_green)
    % pause
end