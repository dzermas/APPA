function nch_vector = computeNCHvector(image, number_of_bins)
% Input:
%   image: NCH is computed on this image
%   number_of_bins: number of bins of the NCH histogram (usually 50-255)
% Output:
%   nch_vector: 6xnumber_of_bins array
[yRed, ~] = imhist(image(:,:,1),number_of_bins);
[yGreen, ~] = imhist(image(:,:,2), number_of_bins);
[yBlue, ~] = imhist(image(:,:,3), number_of_bins);

cform = makecform('srgb2lab');
imdecorr_lab = applycform(image,cform);
[yL, ~] = imhist(imdecorr_lab(:,:,1),number_of_bins);
[ya, ~] = imhist(imdecorr_lab(:,:,2), number_of_bins);
[yb, ~] = imhist(imdecorr_lab(:,:,3), number_of_bins);
% Concatentate histogram values in a single vector
nch_vector = [yRed' yGreen' yBlue' yL' ya' yb'] / (size(image,2)^2);