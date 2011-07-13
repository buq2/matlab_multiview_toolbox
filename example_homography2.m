%Lets generate our data
img1 = single(imread('cameraman.tif'));
img2 = single(imread('pout.tif'));

%Image corners
coordsStraigth = [0 0 1 1;
                  0 1 1 0;
                  1 1 1 1];
              
%Some nifty transformation for images
ang = -15/180*pi;
T1 = [cos(ang) -sin(ang) 0.3;sin(ang) cos(ang) +0.6; 0 0 1];
ang = 7/180*pi;
T2 = [cos(ang) -sin(ang) -0.15;sin(ang) cos(ang) 0.3; 0 0 1];

%Apply transformation to corners
latlon1 = T1*coordsStraigth;
latlon2 = T2*coordsStraigth;
latlon1 = latlon1(1:2,:)';
latlon2 = latlon2(1:2,:)';

%You whould start here with your real data
%Plot image corners
figure(1)
plot(latlon1(:,1),latlon1(:,2),'r.')
hold on
plot(latlon2(:,1),latlon2(:,2),'g.')
hold off
set(gca,'ydir','reverse')

%Calculate transformation from image 2 to image 1 (image 1 should be 'straight')
T = cp2tform(latlon2,latlon1,'projective');

%Image transform
%Calculate where image 2 coordinates are transformed
[img2TcoordsX img2TcoordsY] = tformfwd(T,coordsStraigth(1,:),coordsStraigth(2,:));
%Calculate new image boarders (image 1 has [0 0;0 1;...] corners)
xmin = min([min(img2TcoordsX) 0]);
xmax = max([max(img2TcoordsX) 1]);
ymin = min([min(img2TcoordsY) 0]);
ymax = max([max(img2TcoordsY) 1]);

%Aspect ration and size of output image
aspectratio = (xmax-xmin)/(ymax-ymin);
outsize = [1024 round(1024/aspectratio)];

%Transform image 2
%Note that aspect ratio should be calculated before actual transformation ('Size')
img2trans = imtransform(img2,T,'udata',[0 1],'vdata',[0 1],'xdata',[xmin xmax],'ydata',[ymin ymax],'FillValues',NaN,'Size',outsize);

%We want to have image 1 in same size image. Make transformation which has
%eye(3) transformation matrix
coordsStraigth = [0 0 1 1;
                  0 1 1 0]';
Tnull = cp2tform(coordsStraigth,coordsStraigth,'projective');
img1trans = imtransform(img1,Tnull,'udata',[0 1],'vdata',[0 1],'xdata',[xmin xmax],'ydata',[ymin ymax],'FillValues',NaN,'Size',outsize);

%Plot separated images
figure(2)
subplot(1,2,1)
imagesc(img2trans)
subplot(1,2,2)
imagesc(img1trans)

%Now combine images. One way is to just replace NaNs with image data
imgcomb = img1trans;
imgcomb(isnan(imgcomb)) = img2trans(isnan(imgcomb));
figure(3)
imagesc(imgcomb)