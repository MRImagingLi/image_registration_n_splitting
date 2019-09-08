%% share from: https://blog.csdn.net/qq_35860352/article/details/81121535
%%%%%%%%%��ȡ����ͼƬ�����ұȽ����ߵĲ�ͬ%%%%%%%%%%%%%%%%
moving=imread('1.Tiff');
moving=moving(:,:,1);%Ҫ���ǵ�ͨ��ͼ��
 
fixed=imread('2.Tiff');
fixed=fixed(:,:,1);
 
figure,imshowpair(moving,fixed,'falsecolor');
%figure,imshowpair(moving,fixed,'blend');
title('unregiistered');
[optimizer, metric] = imregconfig('multimodal');%����modalityָ��fixed image, moving image֮��Ĺ�ϵ��������ѡ��monomodal��, 'multimodal'���֣�
%�ֱ�ָ������ͼ���ǵ�һģ̬���Ƕ�ģ̬
 
%%%%%%%%%%%%%����׼%%%%%%%%%%%%%%%%%%%%%%%%%%%5
movingRegisteredDefault = imregister(moving, fixed, 'affine', optimizer, metric);
%����optimizer�������Ż�����׼����Ż��㷨,����metric����ע���˶�������ͼƬ���ƶȵķ���
%��similarity�� �ı任������ƽ�ƣ���ת�ͳ߶ȱ任,��affine�� ��similarity�Ļ����ϼ�����shear��ͼ��ļ�����
figure, imshowpair(movingRegisteredDefault, fixed);
title('A: Default registration');
 
%%%%%%%%%%%%%%%%%��ϸ��׼%%%%%%%%%%%%%%%%%%5
disp('optimizer');
disp('metric');
optimizer.InitialRadius = optimizer.InitialRadius/3.5;%�ı��Ż����Ĳ����Ѵﵽ�Ը��Ӿ�ϸ�ı任
movingRegisteredAdjustedInitialRadius = imregister(moving, fixed, 'affine', optimizer, metric);
figure, imshowpair(movingRegisteredAdjustedInitialRadius, fixed);
title('Adjused InitialRadius');
 
optimizer.MaximumIterations = 300;%������Ļ����ϸı�����������
movingRegisteredAdjustedInitialRadius300 = imregister(moving, fixed, 'affine', optimizer, metric);
figure, imshowpair(movingRegisteredAdjustedInitialRadius300, fixed);
title('B: Adjusted InitialRadius, MaximumIterations = 300, Adjusted InitialRadius.');
 
%%%%%%%%%%%%��һ���������ı��ʼ������߾���%%%%%%%%%%%%%%%%%%%
 
tformSimilarity = imregtform(moving,fixed,'similarity',optimizer,metric);%��similarity�ı任��ʽ����ʼ��׼����������rigid��transform�ķ�ʽ
Rfixed = imref2d(size(fixed));%imregtform�ѱ仯���������Ȼ����imref2d���Ʊ任���ͼ����ο�ͼ������ͬ������ֲ�
movingRegisteredRigid = imwarp(moving,tformSimilarity,'OutputView',Rfixed);%imwarp����ִ�м��α任����������tformSimilarity�ı任����
figure, imshowpair(movingRegisteredRigid, fixed);
title('C: Registration based on similarity transformation model.');
 
%%%%%%%��������׼��׼%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
movingRegisteredAffineWithIC = imregister(moving,fixed,'affine',optimizer,metric,...
    'InitialTransformation',tformSimilarity);
figure, imshowpair(movingRegisteredAffineWithIC,fixed);
title('D: Registration from affine model based on similarity initial condition.');
 
%%%%%%%%%%%%%%%�ܽ�Ա�����4�з�����������ACЧ���൱��BDЧ���൱���ȷ��׼%%%%%%%%%%%
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