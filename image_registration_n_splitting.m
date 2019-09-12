%% image registering and splitting 
% Using different methods to realize image registration
% 
% Original image contains 2 subimages which supposed to be the same.
% The task is to register the 2 subimages and split them to 2 directories
%
% Author: Zhang Zhihong
% Date: 20190907
% Modified: zzh_20190912
% 
% Copyright ? 2019 Zhang zhihong
% Reference: 
%           https://blog.csdn.net/qq_35860352/article/details/81121535
%           https://blog.csdn.net/jidushanzhu/article/details/78041939
%


%% initialize
clc
clear


%% parameter and path
DO_REGISTER = 1;    % do registering
DO_SPLIT = 1;   % do splitting
ROI = [55 45 950 1950];    % splitting ROI， [xmin ymin width hight]
METHOD = 'point-pairs';	%'correlation', 'point-pairs'
INPUT_FILE_TYPE = '.tif';
OUTPUT_FILE_TYPE = '.tif';
% INPUT_FILE_TYPE = '.png';
% OUTPUT_FILE_TYPE = '.png';
SPLIT_TEST_FLAG =  1;

register_reference_img = './test/1.tif';    % image for registering 

registerParasPath = './tform/';    % transformation matrix's saving path
load_registerParas = 'registration_tform_20190912_built-in.mat';     % transformation matrix to be saved or loaded
save_registerParas = ['registration-tform_', date, '_', METHOD];     % transformation matrix to be saved or loaded

original_path = './test/';   % original images path
left_path = './result/left/';  % saving path for splitting result
right_path = './result/right/';

%% image registering
if DO_REGISTER == 1   
    original_pic = imread(register_reference_img);
    width = size(original_pic,2);
    
    I1 = original_pic(:,1:round(width/2),:);    % left, fixed reference image
    I2 = original_pic(:,round(width/2)+1:width,:); % right, unregistered image
    
    if ndims(original_pic)==2    % gray or rgb
        fixed = rescale(I1);  % reference image (fixed image)
        moving = rescale(I2);   % moving image (unregistered image)
    elseif ndims(original_pic)==3
        fixed = rescale(rgb2gray(I1));
        moving = rescale(rgb2gray(I2));
    end
 
    if strcmp(METHOD, 'correlation')
        % using built-in registration functions with default parameter
        % If the spatial scaling of your images differs by more than 10%, resize them with imresize before registering them.
        
        [optimizer, metric] = imregconfig('multimodal');	% registration parameter
        
        % change the following parameters to get better performance
        % minimize the step to get better result ,for 'multimodal' (time increase)
        optimizer.InitialRadius = optimizer.InitialRadius/3.5; 
        % increase iterations to get better result (default 100) (time increase)
        optimizer.MaximumIterations = 300; 
        
        % registered = imregister(moving, fixed, 'affine', optimizer, metric);  %directly get registered output

        rough_tform = imregtform(moving,fixed,'affine',optimizer,metric);
        
        % fine tune
        tform = imregtform(moving,fixed,'affine',optimizer,metric,'InitialTransformation',rough_tform);
        
        save([registerParasPath save_registerParas], 'tform'); % save tform matrix 
        
        Rref = imref2d(size(fixed));
        registered = imwarp(moving,tform, 'OutputView',Rref);	% image transform
        
        % show registering result    
        figure
        imshowpair(fixed, registered, 'falsecolor');
        title('Registration based on correlation method.')

    elseif strcmp(METHOD, 'point-pairs')
        % using selected point pairs to calculating transformation matrix
        % and do registration
        
        % clear existing selection points
        clear fixedPoints movingPoints % clear old existed pairs
        
        % choose points pairs, remember to export to worksapce!
        cpselect(moving,fixed);	
        uiwait(msgbox('1. Export points to workspace. 2. Click OK after closing the CPSELECT window.','Waiting...')); % 创建一个按钮，等待用户反映

        % point pairs
        fixedPoints = round(fixedPoints);
        movingPoints = round(movingPoints);
        
        % finetune point pairs: movingPoints->fine_movingPoints
        fine_movingPoints = cpcorr(movingPoints,fixedPoints,moving,fixed); 

         % calculate transformation matrix
        tform = fitgeotrans(fine_movingPoints,fixedPoints,'affine');   
        save([registerParasPath save_registerParas], 'tform'); % save tform matrix
        
        % register
        Rref = imref2d(size(fixed));
        registered = imwarp(moving,tform, 'OutputView',Rref);	% image transform
        
        % show registering result    
        figure
        imshowpair(fixed, registered, 'falsecolor');
        title('Registration based on point-pairs method.')
    else
        disp('please choose methods between ''point-pairs'' and ''correlation''')
    end
end


%% image splitting
if DO_SPLIT == 1   
    files = dir([original_path, '*', INPUT_FILE_TYPE]);
    file_names = {files.name};
    file_num = length(file_names);

    % load registerParas
    if DO_REGISTER ~= 1
        load([registerParasPath load_registerParas])
        [optimizer, metric] = imregconfig('monomodal');	% registration parameters
    end
            
    for i = 1:file_num

        original_pic = imread([original_path, file_names{i}]);
        width = size(original_pic,2);

        I1 = original_pic(:,1:round(width/2),:);    % left, fixed reference image
        I2 = original_pic(:,round(width/2)+1:width,:); % right, unregistered image

        fixed = I1;  % reference image
        moving = I2;   % moving image

        % transform
        Rfixed = imref2d(size(fixed));
        registered = imwarp(moving,tform,'OutputView',Rfixed); 
        
%         % directly output the registered result
%         [optimizer, metric] = imregconfig('monomodal');	% registration parameter
%         registered = imregister(moving,fixed,'affine',optimizer,metric);
        
        % crop to ROI
        ref_ROI = imcrop(fixed, ROI);
        registered_ROI = imcrop(registered, ROI);

        % image save
        imwrite(ref_ROI,[left_path, file_names{i}(1:end-length(INPUT_FILE_TYPE)), OUTPUT_FILE_TYPE]);
        imwrite(registered_ROI, [right_path, file_names{i}(1:end-length(INPUT_FILE_TYPE)), OUTPUT_FILE_TYPE]);

        if mod(i, round(file_num/10))==0
            fprintf("%.f%% done!\n", 100*i/file_num)
        end
    end
end

%% test result
if SPLIT_TEST_FLAG
    i = randi(file_num);
    test_file_path_left = [left_path, file_names{i}(1:end-length(INPUT_FILE_TYPE)), OUTPUT_FILE_TYPE];
    test_file_path_right = [right_path, file_names{i}(1:end-length(INPUT_FILE_TYPE)), OUTPUT_FILE_TYPE];    
    x1 = imread(test_file_path_left);
    x2 = imread(test_file_path_right);
    
    if ndims(original_pic)==2    % gray or rgb
        x1 = rescale(x1);  % reference image (fixed image)
        x2 = rescale(x2);   % moving image (unregistered image)
    elseif ndims(original_pic)==3
        x1 = rescale(rgb2gray(x1));
        x2 = rescale(rgb2gray(x2));
    end
    
    figure
    imshowpair(x1, x2, 'falsecolor');
    title('split result.')
end