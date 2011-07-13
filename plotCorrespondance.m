function plotCorrespondance(img1,img2,x1,x2)
%Plots point correspondances between two images
%
%Matti Jukola
%2010.12.15
imagesc([img1 img2]);
x1 = wnorm(x1);
x2 = wnorm(x2);
hold on
plot([x1(1,:); x2(1,:)+size(img1,2)], [x1(2,:); x2(2,:)])
hold off
colormap gray