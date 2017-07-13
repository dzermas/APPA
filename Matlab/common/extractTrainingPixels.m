function [training_set, label_set] = extractTrainingPixels(im_train, colorSpaceMask)

%% Input:
% im_train: RGB image used for selecting the training data
% colorSpaceMask: array of booleans indicating which color variables are
% active for training.
% colorSpaceMask(1) = 1R
% G
% B

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Train svm structure for classification later
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Width and height of the image
height = size(im_train, 1);
width = size(im_train, 2);
% Training dataset
training_set = zeros(0,2);
label_set = zeros(0,1);
prompt_start = 'Start training the dataset? y/n [y]: ';
str = input(prompt_start, 's');
if isempty(str)
    str = 'y';
end
if str == 'y'
    while str == 'y'
        prompt_label = 'Select the label of the data that you will train. \n(0 stands for soil, 1 stands for green pixels). 0/1: ';
        choice = input(prompt_label);
        if ~isnumeric(choice) || isempty(choice)
            disp('Please input a valid label, i.e, a number.');
            continue;
        end
        if (choice ~= 0) && (choice ~= 1)
           disp('!!! Please only select class 0 or 1.');
           continue;
        end
        disp('#### Select part of the image that corresponds to your choice ####');
        figure(1);
        imshow(im_train);
        rect = getrect;
        % Make the rectangle to be a proper selection
        % (x1,y1)
        %   *-------.
        %   |       |
        %   .-------* (x2,y2)       ! Return rect = [x1,y1,x2,y2]     
        %
        x2 = int32(min(rect(1,1)+rect(1,3), width));
        y2 = int32(min(rect(1,2)+rect(1,4), height));
        x1 = int32(max(rect(1,1), 1));
        y1 = int32(max(rect(1,2), 1));
        close(figure(1))
        prompt_dis = 'Do you want to discard this selection? y/n [n]';
        str = input(prompt_dis, 's');
        if (~isempty(str)) && str == 'y'
            continue
        end
        % Put select pixels in a big data array. Also create the label array.
        % Note: Duplicate training entries are acceptable.
        r = im_train(y1:1:y2,x1:1:x2,2);
        b = im_train(y1:1:y2,x1:1:x2,2);
        g = im_train(y1:1:y2,x1:1:x2,3);
        training_set = [training_set; r(:) b(:) g(:)];
        label_set = [label_set; choice*ones(size(r,1)*size(r,2),1)];
        % Determine if continue to select data
        while 1
            prompt_cont = 'Do you still want to select your training data set? y/n [y] ';
            temp_str = input(prompt_cont, 's');
            if isempty(temp_str)
                str = 'y';
                break;
            end
            if temp_str == 'y' || temp_str == 'n'
                str = temp_str;
                break;
            end
            disp('Please select y/n.');
        end
        clc;
    end
end
