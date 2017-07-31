function [prediction, color] = seg_yellow_SVM(im, im_t, svmstruct_yellow)
% Input:
%   im: original image
%   im_t: binary image with 1 where the green pixels are and 0 elsewhere
%   svmstruct_yellow: SVM model based on the fitcsvm Matlab function
% Output:
%   prediction: Nx1 vector with the labels of the classification, 1 when pixel is yellow, 0 otherwise
%   color: image with only the original yellow colors

% Supervised classification between yellow and brown pixels
im_R = im(:,:,1);
im_G = im(:,:,2);
im_B = im(:,:,3);

% L*a*b transformation
cform = makecform('srgb2lab');
lab_im = applycform(im,cform);
%lab_im = colorspace('Luv',double(im));
im_L = lab_im(:,:,1);
im_a = lab_im(:,:,2);
im_b = lab_im(:,:,3);

value = [im_R(~im_t) im_G(~im_t) im_B(~im_t) im_L(~im_t) im_a(~im_t) im_b(~im_t)];
value = double(value);

[x,y] = find(~im_t);

% Clustering using projection value
prediction = predict(svmstruct_yellow, value);
prediction = logical(prediction);
x = x(prediction); y = y(prediction);
yellow = zeros(size(im,1), size(im,2), size(im,3));
for i=1:length(x)
    yellow(x(i),y(i),:) = 255;
end

color = im;
color(yellow ~= 255) = 0;