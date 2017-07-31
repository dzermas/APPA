%% Interactive tool that gathers pixels and their RGBL*a*b* values for the SVM model training
function [training_set, label_set] = extractTrainingPixelsHighDim(im_train)

% Input:
%   im_train: RGB image used for selecting the training data
% Output:
%   training_set: 6xN array holding the color values of the selected pixels
%   label_set: 1xN vector holding the labels of the selected pixels

% Width and height of the image
height = size(im_train, 1);
width = size(im_train, 2);
% Training dataset
training_set = [];
label_set = [];
disp('Start training the dataset');
str = 'y';

while str == 'y'
    prompt_label = 'Select the label of the data that you will train. \n(0 stands for soil, 1 stands for deficient leaves). 0/1: ';
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
    im_rect = im_train(y1:1:y2,x1:1:x2,:);
    R = im_rect(:,:,1);
    G = im_rect(:,:,2);
    B = im_rect(:,:,3);
    % L*a*b transformation
    cform = makecform('srgb2lab');
    lab_im_rect = applycform(im_rect,cform);
    L = lab_im_rect(:,:,1);
    a = lab_im_rect(:,:,2);
    b = lab_im_rect(:,:,3);
    
    training_set = [training_set; R(:) G(:) B(:) L(:) a(:) b(:)];
    label_set = [label_set; choice*ones(size(R,1)*size(R,2),1)];
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
