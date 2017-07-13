function green_im = testGreenSegmentationGUO(tree, im)

% Given a random tree classifier and an image, the green pixels are separated from the rest
% INPUT
% im : image to test on
% tree : the random forest model
% OUTPUT
% green_im : the image holding only the green pixels

imr = im(:,:,1);
img = im(:,:,2);
imb = im(:,:,3);

im_test = [imr(:) img(:) imb(:)];

colorSpace = colorExtraction(im_test);
RGB = colorSpace.RGB;
YCbCr = colorSpace.YCbCr;
HSL = colorSpace.HSL;
HSV = colorSpace.HSV;
Lab = colorSpace.Lab;
Luv = colorSpace.Luv;

% Make sure the Test color spaces are the same as the ones you trained with
Test = [RGB,YCbCr,HSL,HSV,Lab,Luv];

label = predict(tree, Test);

r = zeros(length(label),1);
g = zeros(length(label),1);
b = zeros(length(label),1);

l = 0;

r(label==l) = RGB(label==l,1);
g(label==l) = RGB(label==l,2);
b(label==l) = RGB(label==l,3);

rmat = reshape(r, [size(im, 1) size(im, 2)]);
gmat = reshape(g, [size(im, 1) size(im, 2)]);
bmat = reshape(b, [size(im, 1) size(im, 2)]);

green_im = zeros(size(im,1), size(im,2), size(im,3));
green_im(:,:,1) = rmat/255;
green_im(:,:,2) = gmat/255;
green_im(:,:,3) = bmat/255;

imshow(green_im)

