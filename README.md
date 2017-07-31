# APPA
Autonomous Plant Pathology Assessment (APPA) is a software toolbox that processes high resolution RGB images to identify deficiencies on cultivated plants.

# Files
(root)

|- data: images to test the algorithm

|--- mat_files: .mat files for classification models needed by the main scripts

|- Matlab: Matlab implementation of the algorithm

|--- 3rdParty: colorspace is a tool to compute different colorspaces

|--- common: all functions used by the main scripts

|--- deficiency_detection.m: main script for the detection of Rectangles of Interest (ROI) inside the provided images

|--- Guo_segmentation.m: main script for the green pixels segmentation as described in {Guo W Rage U Ninomiya S, "Illumination 
invariant segmentation of vegetation for time series wheat images based on decision tree model", Computers and Electronics in Agriculture, 2013}

# How to Run
## deficiency_detection.m
Runs on MatLab 16b or newer. The script needs support of the latest MatLab versions for the superpixels implementation.
In order to use with your own dataset, you will have to train new SVM models. In this case, both got_svm_green_model and got_svm_yellow_model variables should be set to "false". Once executed, follow the instructions to train your models. You can save your newly created models and use those each time.

This script has two modes; groundtruth and simple data collection. If the variable "groundtruth" is set to "true", the algorithm will ask the feedback of the user each time a new ROI candidate appears in an image.
If the variable "groundtruth" is set to "false", the algorithm will save all ROI candidates in a prespecified location.

## Guo_segmentation.m
Two modes; train and test allow for the user to train a Random Forest classifier on his/her imageset before testing, or just use a pretrained model.
