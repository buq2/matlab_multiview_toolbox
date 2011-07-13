function plotCorrespondance2(img1,img2,x1,x2)
%Plots correspondances from rectangular area, selected from first image
%
%Matti Jukola
%2010.12.19
imagesc(img1)
colormap gray
xy = sort(ginput(2));
idx = x1(1,:)>xy(1,1) & x1(1,:)<xy(2,1) & x1(2,:)>xy(1,2) & x1(2,:)<xy(2,2);
plotCorrespondance(img1,img2,x1(:,idx),x2(:,idx))