function [X x] = randXfromP(P,nump,minmaxdist)
%Generate random 3D-points which can be seen by camera P
%
%Points X are relatively uniformly distributed in 3D space and
%uniformly distributed in image plane.
%
%Inputs:
%      P          - Camera matrix K*[R T]
%      nump       - Number of random points to be generated
%      minmaxdist - Minimum and maximum distance of the points from camera
%                      center. Default [1 2].
%
%Outputs:
%      X    - Random 3D points
%      x    - Projections of X. x = P*X
%
%Example:
% P = [ 0.009602093029649   0.001596008578686   0.001637923704800   1.811600991924575
%      -0.000148673776647   0.008727862555539   0.002414395628251   0.613527103778344
%       0.000003545742606   0.000001182622775   0.000009275188016   0.005709331634379]*10^5;
% [tmpX tmpx] = randXfromP(P,1000,[5 10]);
% figure(1)
% plotp(tmpX)
% plotCamera(P,5) %Minimum distance (corners)
% plotCamera(P,10) %Maxdist (corners)
% figure(2)
% plotp(tmpx)
% axis tight
%
%
%Matti Jukola 2011.10.11

if nargin < 3
    minmaxdist = [1 2];
end

%Decompose P to get calibration matrix
[K R C] = decomposeP(P);

%Assume that pricipal point is at the middle of the image plane
sizeimg = [K(1,3) K(2,3)]'*2; %[x y]'
sizeimg(sizeimg==0) = 1; %Force to have at least 1 pixel.

%Random 2D points
x = bsxfun(@times,rand(2,nump),sizeimg);
x = convertToHom(x);

%Project x to 3D
n = wnorm(pinv(P)*x); %Vectors pointing away from camera
n(1:3,:) = bsxfun(@minus,n(1:3,:),C(1:3,:));
%Normalize to unit lenght
nnorm = n;
nnorm(1:3,:) = bsxfun(@rdivide, n(1:3,:), sqrt(sum(n.^2)));

%Random distance from camera
dist = rand(1,nump);
dist = sqrt(dist); %Uniform in 3D space
n(1:3,:) = bsxfun(@times,nnorm(1:3,:),dist);
n(1:3,:) = n(1:3,:).*(minmaxdist(2)-minmaxdist(1))+nnorm(1:3,:).*minmaxdist(1);

%Finally create X by adding camera center
X = n;
X(1:3,:) = bsxfun(@plus,X(1:3,:),C(1:3,:));

