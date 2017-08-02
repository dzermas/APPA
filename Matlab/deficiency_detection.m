%% Find potential N deficiencies to create dataset for classification
clearvars;
close all;
clc;

warning('off','all');
addpath('common');
addpath(genpath('colorspace'));

%% Set variables
% Threshold for the minimum number of pixels in a yellow cluster
th = 300;
% Number of superpixels
spNum = 5000;
% How much should the image be subsampled? range (0,1]
resizeParam = 0.2;
% Decorrelation sensitivity
decorrParam = 0.01;
% Already got an SVM model for green/rest separation?
got_svm_green_model = true;
% Already got an SVM model for yellow/soil separation?
got_svm_model = true;
% Select how many subimages you want the initial image to be split into
winx = 4;
winy = 2;
% Just collect data or groundtruth them?
groundtruth = 1;

% Select folder with Images
folder_name_input = uigetdir('','Select folder with the images to be processed');
list = dir(strcat(folder_name_input,'/*.jpg')); %*.JPG

% Select folder to save results
folder_name_output = uigetdir('','Select folder to save resulting images');

% Load SVM model for the separation of green pixels
if got_svm_green_model
    load('../data/mat_files/svmstruct_green.mat');
else
    [file_names, files_path] = uigetfile('*','Select file to train','Multiselect','on');
    training_set = [];
    label_set = [];
    for i=1:length(file_names)
        im_whole = imread(strcat(files_path, file_names{i}));
        im = [imresize(im_whole, 0.5)];
        % Expand the color space
        imadj = imadjust(im,stretchlim(im));
        imdecorr_rgb = decorrstretch(imadj,'Tol',0.01);
        [tmp_training_set, tmp_label_set] = extractTrainingPixelsHighDim(imdecorr_rgb);
        training_set = [training_set; tmp_training_set];
        label_set = [label_set; tmp_label_set];
    end
    % Using the selected training data set to train the SVM
    disp('#### Training SVM ####');
    MaxIter = 10000;
    svmstruct_green = fitcsvm(double(training_set), label_set, ...
        'IterationLimit', MaxIter);
    disp('Done.');
end

% Load SVM model for the separation of yellow pixels
if got_svm_model
    load('../data/mat_files/svmstruct_yellow.mat');
else
    [file_names, files_path] = uigetfile('*','Select file to train','Multiselect','on');
    training_set = [];
    label_set = [];
    for i=1:length(file_names)
        im_whole = imread(strcat(files_path, file_names{i}));
        im = [imresize(im_whole, 0.5)];
        % Expand the color space
        imadj = imadjust(im,stretchlim(im));
        imdecorr_rgb = decorrstretch(imadj,'Tol',0.01);
        [tmp_training_set, tmp_label_set] = extractTrainingPixelsHighDim(imdecorr_rgb);
        training_set = [training_set; tmp_training_set];
        label_set = [label_set; tmp_label_set];
    end
    % Using the selected training data set to train the SVM
    disp('#### Training SVM ####');
    MaxIter = 1000000;
    svmstruct_yellow = fitcsvm(double(training_set), label_set, 'IterationLimit', MaxIter);
    disp('Done.');
end

for nim = 1:length(list)
    disp(strcat('start processing image :',list(nim).name));
    % Load data from workspace
    im_whole = imread(strcat(folder_name_input,'/',list(nim).name));
    im_ = imresize(im_whole, resizeParam);
    clear im_whole im_orig;
    
    candidates = 0;
    x_ = [1:round(size(im_,2)/winx):size(im_,2) size(im_,2)];
    y_ = [1:round(size(im_,1)/winy):size(im_,1) size(im_,1)];
    for i_ = 1:winx
        for j_ = 1:winy
            
            im = imcrop(im_, [x_(i_) y_(j_) x_(i_+1)-x_(i_) y_(j_+1)-y_(j_)]);
           
            %% Expand the color space
            imadj = imadjust(im,stretchlim(im));
            imdecorr_rgb = decorrstretch(imadj,'Tol',decorrParam);
            
            %% Segment green from rest
            tic
            % Smooth with superpixels
            [centroids, outputImage] = super_smooth(imdecorr_rgb, spNum);
            green = seg_green_SVM(imdecorr_rgb, centroids, svmstruct_green);
            green_BW = im2bw(green,1/255);
            disp(['Segmented green in :' num2str(toc)])
            % green = seg_mixed_highdim_f(outputImage);
            % green = seg_mixed_f(outputImage);
            % green = seg_green_GUO(im);
            %% Segment yellow from soil
            tic
            [~, yellow] = seg_yellow_SVM(outputImage, green_BW, svmstruct_yellow);
            yellow_BW = im2bw(yellow(:,:,1),1/255);
            disp(['Segmented yellow in :' num2str(toc)])
            % Visualize steps
            figure, hold on
            subplot(1,3,1), imshow(outputImage)
            subplot(1,3,2), imshow(green)
            subplot(1,3,3), imshow(yellow)
            %% Apply morphological image processing to clean up the image
            tic
            yellow_BW = bwmorph(yellow_BW,'close'); % Connect close clusters, user might as well want to try the effects of 'open'
            yellow_BW = bwareaopen(yellow_BW, th); % Remove clusters smaller than thresholded number of pxls     
            disp(['Morph operations in :' num2str(toc)])
            %% Find centroids of the surviving clusters in the image
            % Looking for connected components
            CC = bwconncomp(yellow_BW);
            % Calculate the centroids of the connected components
            S = regionprops(CC, 'Centroid');
            C = struct2cell(S);
            centroid = reshape(cell2mat(C), 2, length(C));
            % Update counter of candidates
            candidates = candidates + length(C);
            disp(strcat('number of candidates :',num2str(candidates))); 
            
            %% AUTOMATIC LEAF DETECTION
            figure, set(gcf,'renderer','zbuffer');
            imshow(im), hold on;
            cr_im = cell(size(S,1),1);
            cr_im_seg = cell(size(S,1),1);
            cr_im_t = cell(size(S,1),1);
            
            for i=1:size(S,1)
                [x,y] = ind2sub(size(yellow_BW),CC.PixelIdxList{1,i});
                xmax = max(x); ymax = max(y);
                xmin = min(x); ymin = min(y);
                mask = false(size(yellow_BW));
                mask(xmin:xmax,ymin:ymax) = true;
                cr_im{i} = imcrop(im,[ymin xmin ymax-ymin xmax-xmin]);

                % If the Bounding Box (BB) is too short or narrow, then skip it
                if size(cr_im{i},1) < 20 || size(cr_im{i},2) < 20
                    [c,H] = contour(mask,[0.5 0.5],'r');
                    continue
                end
                
                % Place BB around area of interest
                [c,H] = contour(mask,[0.5 0.5],'c');
                set (H, 'LineWidth', 2);
                                
                if groundtruth == 1
                    prompt = 'Class? 1 for Deficient/0 for Other: ';
                    class = input(prompt,'s'); % 1 Deficient/0 Other
                    % Save selected iamges to disk
                    imwrite(cr_im{i},strcat(folder_name_output,'/',num2str(class),'_', ...
                        list(nim).name,'_',num2str(i),'_',num2str(i_),'_',num2str(j_),'.jpg'));
                    if str2double(class) == 1
                        [c,H] = contour(mask,[0.5 0.5],'c');
                    elseif str2double(class) == 0
                        [c,H] = contour(mask,[0.5 0.5],'r');
                    end
                else
                    % Save selected images to disk
                    imwrite(cr_im{i},strcat(folder_name_output,'/', ...
                        list(nim).name,'_',num2str(i),'_',num2str(i_),'_',num2str(j_),'.jpg'));
                end
            end
            % pause
            close all
        end
    end
    disp(strcat('Total number of candidates :',num2str(candidates)));
end
