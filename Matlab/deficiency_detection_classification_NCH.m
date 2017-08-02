%% Main script for training and prediction of the N deficiency leaf detection
clearvars;
close all;
clc;

addpath('common')
warning('off','all');

% Select folder with Images
folder_name_input = uigetdir('','Select folder with the images to be processed');
list = dir(strcat(folder_name_input,'/*.JPG'));

%% Set variables
% Threshold for the minimum number of pixels in a yellow cluster
th = 200;
% Number of superpixels
spNum = 5000;
% How much should the image be subsampled? range (0,1]
resizeParam = 0.6;
% Decorrelation sensitivity
decorrParam = 0.01;
% Already got an SVM model for green/rest separation?
got_svm_green_model = true;
% Already got an SVM model for yellow/soil separation?
got_svm_model = true;
% Select how many subimages you want the initial image to be split into
winx = 8;
winy = 2;
% Select mode: 
% 1) For training write < mode = 'train'; >
% 2) For prediction write < mode = 'prediction'; >
mode = 'prediction';
number_of_bins = 100;
if strcmp(mode, 'prediction')
    load('../data/SVM_trained_model_NCH_100.mat');
end

% Load SVM model for the separation of green pixels
if got_svm_green_model
    load('../data/mat_files/svmstruct_green.mat');
else
    training_set = [];
    label_set = [];
    more = 'y';
    while strcmp(more,'y')
        [file_names, files_path] = uigetfile('*','Select file to train');
        im_whole = imread(strcat(files_path, file_names));
        im = imresize(im_whole, 0.6);
        % Expand the color space
        imadj = imadjust(im,stretchlim(im));
        imdecorr_rgb = decorrstretch(imadj,'Tol',0.01);
        [tmp_training_set, tmp_label_set] = extractTrainingPixelsHighDim(imdecorr_rgb);
        training_set = [training_set; tmp_training_set];
        label_set = [label_set; tmp_label_set];
        prompt = 'Want to process another image? (y/n)';
        more = input(prompt,'s');
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
    training_set = [];
    label_set = [];
    more = 'y';
    while strcmp(more,'y')
        [file_names, files_path] = uigetfile('*','Select file to train');
        im_whole = imread(strcat(files_path, file_names));
        im = [imresize(im_whole, 0.6)];
        % Expand the color space
        imadj = imadjust(im,stretchlim(im));
        imdecorr_rgb = decorrstretch(imadj,'Tol',0.01);
        [tmp_training_set, tmp_label_set] = extractTrainingPixelsHighDim(imdecorr_rgb);
        training_set = [training_set; tmp_training_set];
        label_set = [label_set; tmp_label_set];
        prompt = 'Want to process another image? (y/n)';
        more = input(prompt,'s');
    end
    % Using the selected training data set to train the SVM
    disp('#### Training SVM ####');
    MaxIter = 1000000;
    svmstruct_yellow = fitcsvm(double(training_set), label_set, 'IterationLimit', MaxIter);
    disp('Done.');
end

nch_vectors = [];
nch_labels = [];
for nim = 1:length(list)
    disp(strcat('start processing image :',list(nim).name));
    % Load data from workspace
    im_whole = imread(strcat(folder_name_input,'/',list(nim).name));
    im_ = imresize(im_whole, resizeParam);
    clear im_whole im_orig;
    
    image_total = uint8(zeros(size(im_)));
    x_ = [1:round(size(im_,2)/winx):size(im_,2) size(im_,2)];
    y_ = [1:round(size(im_,1)/winy):size(im_,1) size(im_,1)];
    for i_ = 1:winx
        for j_ = 1:winy
            
            im = imcrop(im_, [x_(i_) y_(j_) x_(i_+1)-x_(i_) y_(j_+1)-y_(j_)]);
           
            % Expand the color space
            imadj = imadjust(im,stretchlim(im));
            imdecorr_rgb = decorrstretch(imadj,'Tol',decorrParam);
            tic
            % Smooth with superpixels
            [centroids, outputImage] = super_smooth(imdecorr_rgb, spNum);
            
            %% Segment green from rest
            green = seg_green_SVM(imdecorr_rgb, centroids, svmstruct_green);
            green_BW = im2bw(green,1/255);
            disp(['Green clustering finished in :' num2str(toc)])
            % green = seg_mixed_highdim_f(outputImage);
            % green = seg_mixed_f(outputImage);
            % green = seg_green_GUO(im);
            %% Segment yellow from soil
            tic
            [~, yellow] = seg_yellow_SVM(outputImage, green_BW, svmstruct_yellow);
            yellow_BW = im2bw(yellow(:,:,1),1/255);
            disp(['Yellow clustering finished in :' num2str(toc)])
            % figure, hold on
            % subplot(1,3,1), imshow(outputImage)
            % subplot(1,3,2), imshow(green)
            % subplot(1,3,3), imshow(yellow)
            %% Apply morphological image processing to clean up the image
            yellow_BW = bwmorph(yellow_BW,'close'); % Connect close clusters
            yellow_BW = bwareaopen(yellow_BW, th); % Remove clusters smaller than thresholded number of pxls            
            %% Find centroid of the big clusters in the image
            % Looking for connected components
            CC = bwconncomp(yellow_BW);
            % Calculate the centroids of the connected components
            S = regionprops(CC, 'Centroid');
            C = struct2cell(S);
            centroid = reshape(cell2mat(C), 2, length(C));            
            
            %% AUTOMATIC LEAF DETECTION
            figure(1), set(gcf,'renderer','zbuffer');
            imshow(im), hold on;
            cr_im = cell(size(S,1),1);

            for i=1:size(S,1)
                [x,y] = ind2sub(size(yellow_BW),CC.PixelIdxList{1,i});
                xmax = max(x); ymax = max(y);
                xmin = min(x); ymin = min(y);
                mask = false(size(yellow_BW));
                mask(xmin:xmax,ymin:ymax) = true;
                cr_im{i} = imcrop(im,[ymin xmin ymax-ymin xmax-xmin]);

                if size(cr_im{i},1) < 20 || size(cr_im{i},2) < 20
                    [c,H] = contour(mask,[0.5 0.5],'r');
                    continue
                end
                
                % Train or Predict?
                % Select training
                if strcmp(mode,'train')
                    [c,H] = contour(mask,[0.5 0.5],'y');
                    set (H, 'LineWidth', 4);
                    image_resized = imresize(cr_im{i}, [100 100]);
                    %Get histValues for each channel
                    nch_vector = computeNCHvector(image_resized, number_of_bins);
                    nch_vectors = [nch_vectors; nch_vector];
                    prompt = 'Class? 1 N deficient/0 Not N deficient: ';
                    class = input(prompt,'s'); % 1 Unhealthy/0 Healthy
                    nch_labels = [nch_labels; str2double(class)];
                    if str2double(class) == 1
                        [c,H] = contour(mask,[0.5 0.5],'c');
                        set (H, 'LineWidth', 4);
                    elseif str2double(class) == 0
                        [c,H] = contour(mask,[0.5 0.5],'r');
                        set (H, 'LineWidth', 4);
                    end
                % Select prediction 
                elseif strcmp(mode,'prediction')
                    image_resized = imresize(cr_im{i}, [100 100]);
                    nch_vector = computeNCHvector(image_resized, number_of_bins);
                    [prediction,score] = predict(SVM_trained_model_NCH_100, nch_vector);
                    if prediction == 1
                        [c,H] = contour(mask,[0.5 0.5],'c');
                        set (H, 'LineWidth', 4);
                    elseif prediction == 2
                        [c,H] = contour(mask,[0.5 0.5],'r');
                        set (H, 'LineWidth', 4);
                    end
                end
            end
            disp(['Predictions finished in :' num2str(toc)])
            hold off;
            drawnow
            temp_image = frame2im(getframe(gca));
            image_total(y_(j_):y_(j_+1), x_(i_):x_(i_+1), 1:3) = temp_image(1:end-1,1:end,1:3);
            close all
        end
    end
    figure,imshow(image_total)
end
