function plotCorrespondanceTrifocal(img1,img2,img3,x1,x2,x3,method)
%Plots point correspondances between three (same size) images
%
%Matti Jukola
%2010.05.28

x1 = wnorm(x1);
x2 = wnorm(x2);
x3 = wnorm(x3);

if nargin < 7
    method = 2;
end

if method == 1
    %Using points
    imagesc([img1 img2 img3]);
    hold on
    plot(x1(1,:),x1(2,:),'.r');
    plot(x2(1,:),x2(2,:),'.r');
    plot(x3(1,:),x3(2,:),'.r');
    hold off
elseif method == 2
    %Using triangles
    s1 = size(img1);
    s2 = size(img2);
    s3 = size(img3);
    s3shift_x = round((s1(2)+s2(2))/2-s3(2)/2);
    s3shift_y = s1(1);
    s2shift_x = s1(2);
    pad = (s1(2)+s2(2))-s3(2)-s3shift_x;
    bigimg = zeros(s1(1)+s3(1),s1(2)+s2(2),size(img1,3),class(img1));
    for ii = 1:size(img1,3)
        bigimg(:,:,ii) = [img1(:,:,ii) img2(:,:,ii);zeros(s1(1),s3shift_x) img3(:,:,ii)  zeros(s1(1),pad)];
    end
    imagesc(bigimg)
    
    x2(1,:) = x2(1,:) + s2shift_x;
    x3(1,:) = x3(1,:) + s3shift_x;
    x3(2,:) = x3(2,:) + s3shift_y;
    
    points_x = [x1(1,:); x2(1,:); x3(1,:); x1(1,:)];
    points_y = [x1(2,:); x2(2,:); x3(2,:); x1(2,:)];
    
    hold on
    plot(points_x,points_y);
    hold off
else
    error('Unknown method')
end

