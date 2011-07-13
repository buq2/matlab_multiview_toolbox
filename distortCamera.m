function x = distortCamera(x,K,r,t,sx,r_center,t_center)
%Lens distortion for projected points when calibration matrix is known
%
% r - Radial distortion coefficients
%HZ2 7.4 p. 191
%MASKS 3.3.3 p.58
%Devernay & Faugeras - Automatic calibration and removal of distortion from scenes of structured environments
%http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%
%Inputs:
%   x        - Undistorted points. Can be either unhomogenous 2xn or
%              homogenous 3xn.
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
%Matti Jukola 2010.12.2x

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
if size(x,1) ~= 3
    x = convertToHom(x);
end

x = wnorm(K\x);
x = distort(x,r,r_center,sx,t,t_center);
x = wnorm(K*x);