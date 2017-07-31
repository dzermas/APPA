%% Dimitris Zermas 4/3/2017
% Implementation of the paper: Guo W Rage U Ninomiya S, "Illumination 
% invariant segmentation of vegetation for time series wheat images based 
% on decision tree model", Computers and Electronics in Agriculture, 2013

clearvars;
close all;
clc;

addpath('common')
addpath('3rdParty/colorspace')
warning('off','all');

% Select folder with Images
folder_name = uigetdir('','Select folder with the images to be processed');
list = dir(strcat(folder_name,'/*.JPG'));

% 'train' or 'test'?
mode = 'test';

% Number of image splits
winx = 1;
winy = 1;

clc
for nim = 1:length(list)
    disp(strcat('start processing image :',list(nim).name));
    % Load data from workspace
    im_whole = imread(strcat(folder_name,'/',list(nim).name));
    im_ = imresize(im_whole, 0.5);
    clear im_whole im_orig;
    
    x_ = [1:round(size(im_,2)/winx):size(im_,2) size(im_,2)];
    y_ = [1:round(size(im_,1)/winy):size(im_,1) size(im_,1)];
    for i_ = 1:winx
        for j_ = 1:winy
            % Subimage
            im = imcrop(im_, [x_(i_) y_(j_) x_(i_+1)-x_(i_) y_(j_+1)-y_(j_)]);
            
            % Train random forest
            if (strcmp(mode, 'train'))
                tree = trainGreenSegmentationGUO(im);
                save('../data/mat_files/tree_model.mat', 'tree');
            elseif (strcmp(mode, 'test'))
                % Test random forest
                load('tree_model.mat');
                green_im = testGreenSegmentationGUO(tree, im);
            else
                disp('Set correct mode');
                return;
            end
        end
    end
end
