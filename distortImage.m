function outimg = distortImage(img,K,r,t,sx,r_center,t_center)
%Distorts undistorted image, output image is same size as original.
%NOTE: This function uses undistortCamera which uses function undistort.
%      To undistort image, distortion parameters should (usually) have been 
%      calculated (minimized) using function distortCamera
%
% r - Radial distortion coefficients
%HZ2 7.4 p. 191
%MASKS 3.3.3 p.58
%Devernay & Faugeras - Automatic calibration and removal of distortion from scenes of structured environments
%http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%
%Inputs:
%   img      - Undistorted image. Can be color on gray valued
%   K        - Camera calibration matrix. Points x will be
%              first multiplied with inv(K) (wnorm(inv(K)*x)) this will
%              affect the scale of the x and center of distortion.
%              This is same method as in 'rect.m'/'apply_distortion.m' in 
%              Bouguets calibration toolbox. After applying this 
%              transformation we do not usually use different distortion
%              center (as it is now same as pricipal point). After
%              distortion we apply K*x
%   r        - Radial distortion coefficients
%   t        - Tangential distortion coefficients
%   sx       - Radial distortion aspect ratio. If symmetrical sx = 1
%   r_center - Radial distortion center (from principal point)
%   t_center - Tangential distortion center (from principal point)
%
%Outputs
%   outimg   - Undistorted image. Same size as original.
%                Part of the data is clipped out.
%
%Matti Jukola 2011.02.19, 2011.03.08

if nargin < 4
    t = [];
end
if nargin < 5
    sx = 1;
end
if nargin < 6
    r_center = [0 0];
end
if nargin < 7
    t_center = [0 0];
end

s = size(img);
[Ximg Yimg] = meshgrid(0:s(2)-1,0:s(1)-1); %Upper left is (0,0)
XX = convertToHom([Ximg(:) Yimg(:)]');

Xdistorted = undistortCamera(XX,K,r,t,sx,r_center,t_center);
Xdistorted = wnorm(Xdistorted);

outimg = interpImage(Ximg,Yimg,img,Xdistorted(1,:),Xdistorted(2,:));