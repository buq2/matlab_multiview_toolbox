pth = 'imgs_proprietary/panorama';
pics = {'7','2','1','3','9'};
pics = strcat(strcat('scili_', pics),'.jpg');
X = cell(numel(pics),1);
X_ = cell(numel(pics),1);
H = cell(numel(pics),1);
for ii = 1:numel(pics)-1
    img1 = imread(fullfile(pth,pics{ii}));
    img2 = imread(fullfile(pth,pics{ii+1}));
    [H_ x1 x2] = autoHomography(img1,img2);
    X{ii} = x1;
    X_{ii} = x2;
    H{ii} = H_;
    figure
    subplot(2,1,1)
    imagesc(img1)
    hold on
    plotp(x1)
    hold off
    subplot(2,1,2)
    imagesc(img2)
    hold on
    plotp(x2)
    hold off
end
%% Lets use the image '1' as center
img1 = imread(fullfile(pth,pics{3}));
img2 = imread(fullfile(pth,pics{3+1}));
maxsize = [1024 1024];
%Center figure coordinates
[px py] = meshgrid(1:size(img1,2),1:size(img1,1));
img1coord = convertToHom([px(:) py(:)]');
%Coordinates of another image
imgxcoord = img1coord;
%As we calculate homography H from left image to right...
%Join 1 and 3
Hinv = inv(H{3});
imgxcoord = wnorm(Hinv*imgxcoord);
%Calculate min and max of x and y coordinates
minmaxx = [min(imgxcoord(1,:)) max(imgxcoord(1,:))];
minmaxy = [min(imgxcoord(2,:)) max(imgxcoord(2,:))];
%Create new coordinates for both images using new image boarders
s = size(img1);
s = s(1:2);
[px py] = meshgrid(min(1,minmaxx(1)):max(s(2),minmaxx(2)),min(1,minmaxy(1)):max(s(1),minmaxy(2)));
res1 = zeros(size(px));
res2 = zeros(size(px));
newcoords = convertToHom([px(:) py(:)]');
newcoordsTrans = wnorm(H{3}*newcoords);
%Now interpolation
res1(:) = interp2(reshape(imgcoord(1,:),s),reshape(imgcoord(2,:),s),single(img1(:,:,1)),newcoords(1,:),newcoords(2,:));
res2(:) = interp2(reshape(imgcoord(1,:),s),reshape(imgcoord(2,:),s),single(img2(:,:,1)),newcoordsTrans(1,:),newcoordsTrans(2,:));
%Combination of these images
res = res1;
res(isnan(res)) = res2(isnan(res));












