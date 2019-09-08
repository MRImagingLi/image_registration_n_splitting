%% share from: https://blog.csdn.net/qq_35860352/article/details/81121535
%%%%%%%%%读取两幅图片，并且比较两者的不同%%%%%%%%%%%%%%%%
moving=imread('1.Tiff');
moving=moving(:,:,1);%要求是单通道图像，
 
fixed=imread('2.Tiff');
fixed=fixed(:,:,1);
 
figure,imshowpair(moving,fixed,'falsecolor');
%figure,imshowpair(moving,fixed,'blend');
title('unregiistered');
[optimizer, metric] = imregconfig('multimodal');%参数modality指定fixed image, moving image之间的关系，有两种选择‘monomodal’, 'multimodal'两种，
%分别指定两幅图像是单一模态还是多模态
 
%%%%%%%%%%%%%粗配准%%%%%%%%%%%%%%%%%%%%%%%%%%%5
movingRegisteredDefault = imregister(moving, fixed, 'affine', optimizer, metric);
%参数optimizer是用于优化度量准则的优化算法,参数metric则是注明了度量两幅图片相似度的方法
%‘similarity’ 改变换包括了平移，旋转和尺度变换,‘affine’ 在similarity的基础上加入了shear（图像的剪辑）
figure, imshowpair(movingRegisteredDefault, fixed);
title('A: Default registration');
 
%%%%%%%%%%%%%%%%%精细配准%%%%%%%%%%%%%%%%%%5
disp('optimizer');
disp('metric');
optimizer.InitialRadius = optimizer.InitialRadius/3.5;%改变优化器的步长已达到对更加精细的变换
movingRegisteredAdjustedInitialRadius = imregister(moving, fixed, 'affine', optimizer, metric);
figure, imshowpair(movingRegisteredAdjustedInitialRadius, fixed);
title('Adjused InitialRadius');
 
optimizer.MaximumIterations = 300;%在上面的基础上改变最大迭代次数
movingRegisteredAdjustedInitialRadius300 = imregister(moving, fixed, 'affine', optimizer, metric);
figure, imshowpair(movingRegisteredAdjustedInitialRadius300, fixed);
title('B: Adjusted InitialRadius, MaximumIterations = 300, Adjusted InitialRadius.');
 
%%%%%%%%%%%%另一个方法：改变初始条件提高精度%%%%%%%%%%%%%%%%%%%
 
tformSimilarity = imregtform(moving,fixed,'similarity',optimizer,metric);%用similarity的变换方式做初始配准，还可以用rigid，transform的方式
Rfixed = imref2d(size(fixed));%imregtform把变化矩阵输出；然后用imref2d限制变换后的图像与参考图像有相同的坐标分布
movingRegisteredRigid = imwarp(moving,tformSimilarity,'OutputView',Rfixed);%imwarp函数执行几何变换，依据则是tformSimilarity的变换矩阵。
figure, imshowpair(movingRegisteredRigid, fixed);
title('C: Registration based on similarity transformation model.');
 
%%%%%%%接下来精准配准%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
movingRegisteredAffineWithIC = imregister(moving,fixed,'affine',optimizer,metric,...
    'InitialTransformation',tformSimilarity);
figure, imshowpair(movingRegisteredAffineWithIC,fixed);
title('D: Registration from affine model based on similarity initial condition.');
 
%%%%%%%%%%%%%%%总结对比以上4中方法输出结果，AC效果相当，BD效果相当，最精确配准%%%%%%%%%%%
% figure
% imshowpair(movingRegisteredDefault, fixed)
% title('A - Default settings.');
% 
% figure
% imshowpair(movingRegisteredAdjustedInitialRadius, fixed)
% title('B - Adjusted InitialRadius, 100 Iterations.');
% 
% figure
% imshowpair(movingRegisteredAdjustedInitialRadius300, fixed)
% title('C - Adjusted InitialRadius, 300 Iterations.');
% 
% figure
% imshowpair(movingRegisteredAffineWithIC, fixed)
% title('D - Registration from affine model based on similarity initial condition.');