function [newpic x2_to_x3] =  createPanorama(x1,x2,img1,img2)
H = makeH(x1,x2);

[xx1 yy1] = meshgrid(1:size(img1,2),1:size(img1,1));
xx1 = [xx1(:) yy1(:) ones(numel(xx1),1)]';
xx1 = wnorm(H*xx1);
xx1 = xx1(1:2,:);

new_coords_x = [min(min(xx1(1,:)),1) max(max(xx1(1,:)),size(img2,2))];
new_coords_x(1) = floor(new_coords_x(1));
new_coords_x(2) = ceil(new_coords_x(2));
new_coords_y = [min(min(yy1(1,:)),1) max(max(xx1(2,:)),size(img2,1))];
new_coords_y(1) = floor(new_coords_y(1));
new_coords_y(2) = ceil(new_coords_y(2));


newpic = zeros(new_coords_y(2)-new_coords_y(1)+1,...
        new_coords_x(2)-new_coords_x(1)+1,size(img1,3));
    
    
    
%Coordniates for undistorted image
[xx2 yy2] = meshgrid(1:size(img2,2),1:size(img2,1));

%Coordinates for new image
[nxx nyy] = meshgrid(new_coords_x(1):new_coords_x(2),new_coords_y(1):new_coords_y(2));

%Add undistorted image
for ii = 1:size(img1,3)
    newpic(:,:,ii) = interp2(xx2,yy2,double(img2(:,:,ii)),nxx,nyy,'nearest');
end
%Faster than interpolating, but this is cheating ;)
%newpic((1:size(img2,1))-new_coords_y(1)+1,...
%       (1:size(img2,2))-new_coords_x(1)+1, ...
%        :) = double(img2);

%Add distorted image
clear xx1
newpic2 = newpic;
nxx = [nxx(:) nyy(:) ones(numel(nxx),1)]';
nxx = wnorm(inv(H)*nxx);
[xx2 yy2] = meshgrid(1:size(img1,2),1:size(img1,1));
for ii = 1:size(img1,3) 
    newpic2(:,:,ii) = reshape(interp2(xx2,yy2,double(img1(:,:,ii)),nxx(1,:), nxx(2,:),'nearest'),[size(newpic2,1) size(newpic2,2)]);
end

newpic(isnan(newpic)) = newpic2(isnan(newpic));

x2_to_x3 = eye(3);
x2_to_x3(1,3) = -new_coords_x(1)+1;
x2_to_x3(2,3) = -new_coords_y(1)+1;