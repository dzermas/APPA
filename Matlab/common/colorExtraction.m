%% function that generates 10 different colorspaces

function colorSpace = colorExtraction(im)

colorSpace.RGB = colorspace('RGB',double(im));
colorSpace.YCbCr = colorspace('YCbCr',double(im));
colorSpace.HSL = colorspace('HSL',double(im));
colorSpace.HSV = colorspace('HSV',double(im));
colorSpace.Lab = colorspace('Lab',double(im));
colorSpace.Luv = colorspace('Luv',double(im));

RGB = colorSpace.RGB;

Ex = zeros(size(RGB,1),size(RGB,2),4);
%Excess green : 
Ex(:,2) = 2*RGB(:,2) - RGB(:,1) - RGB(:,3);
%Excess red : 
Ex(:,1) = 1.4*RGB(:,1) - RGB(:,2); 
%Excess blue : 
Ex(:,3) = 1.4*RGB(:,3) - RGB(:,2);
%Excess green minus excess red : 
Ex(:,4) = Ex(:,2) - Ex(:,1);

colorSpace.Ex = Ex;