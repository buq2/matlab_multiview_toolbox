function x = distort(x,r,r_center,sx,t,t_center)
%Basic lens distortion
%
% r - Radial distortion coefficients
%HZ2 7.4 p.191
%MASKS 3.3.3 p.58
%Devernay & Faugeras - Automatic calibration and removal of distortion from scenes of structured environments
%http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%
%Inputs:
%   x        - Undistorted points (if homogenous, third component will be
%              ignored so use wnorm(x) before calling this function with
%              3xn matrices)
%   r        - Radial distortion coefficients
%   r_center - Center of radial distortion. Default [0 0]
%   sx       - Radial distortion aspect ratio. If symmetrical sx = 1
%   t        - Tangential distortion coefficients
%   t_center - Center of tangential distortion
%
%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.06.xx - Initial version 
%  2010.09.27 - First working version (still experimental)
%             - Added radial distortion aspect ratio
%  2010.12.2x - Output now equal to Bouguets toolbox

if nargin < 3 || isempty(r_center);r_center = [0 0];end
if nargin < 4 || isempty(sx);sx = 1;end
if nargin < 5; t = []; end
if nargin < 6; t_center = r_center; end

if ~isempty(t) && numel(t) ~= 2
    error('Basic distortion function supports only two (2) tangential distortion coefficients')
end

if ~isempty(t)
   org_x = x(1:2,:); 
end

r_center = r_center(:);

without_r_center = bsxfun(@minus,x(1:2,:),r_center);

%Radial distortion distance
if sx == 1
    d2 = sum(without_r_center.^2,1);
else
    tmp = without_r_center;
    tmp(1,:) = tmp(1,:)./sx;
    d2 = sum(tmp.^2,1);
end

%Radial distortion
%1+r^2*r(1)+r^4*r(2)+...
l = ones(size(d2));
for ii = 1:numel(r)
   l = l+r(ii)*d2.^ii;
end
%Add radial distortion
without_r_center(1:2,:) = bsxfun(@times,without_r_center(1:2,:),l);
x(1:2,:) = bsxfun(@plus,without_r_center,r_center);

%solve('xd+(xd-xc)*(k1+k2+k3)+p-xu','xd') = (xu - p + xc*(k1 + k2 + k3))/(k1 + k2 + k3 + 1)
%Add tangential distortion
if ~isempty(t)
    t_center = t_center(:);
    without_t_center = bsxfun(@minus,org_x,t_center);
    d2 = sum(without_t_center.^2,1);
    xy2 = 2*org_x(1,:).*org_x(2,:);
    x(1,:) = x(1,:) + t(1)*xy2 + t(2)*(d2+2.*org_x(1,:).^2);
    x(2,:) = x(2,:) + t(2)*xy2 + t(1)*(d2+2.*org_x(2,:).^2);
end
