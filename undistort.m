function x = undistort(x,r,r_center,sx,t,t_center,fastflag)
%Basic lens distortion fix
%NOTE: This is inverse for distort.m, but only if numel(r) = 1 or 2 
%      (it is easy to implement more coefficients). Tangential distortion
%      solving is not implemented.
%NOTE: This function is experimental. Choosing undistorted distance is
%      implemented using @min (which is completely wrong)
%HZ 7.4 p. 191
%Devernay & Faugeras - Automatic calibration and removal of distortion from scenes of structured environments
%http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%
%Inputs:
%   x        - Undistorted points
%   r        - Radial distortion coefficients
%   r_center - Center of radial distortion
%   sx       - Radial distortion aspect ratio
%   t        - Tangential distortion coefficients
%   t_center - Tangential distortien center
%   fastflag - If true (default false), uses fast method (interpolation)
%               for solving distortion radius.
%
%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.06.xx - Initial version 
%  2010.09.27 - First working version (still experimental)
%             - Added radial distortion aspect ratio
%  2011.01.16 - Added correct solution for numel(r) == 1 or 2

if nargin < 3 || isempty(r_center);r_center = mean(x(1:2,:),2);end
if nargin < 4 || isempty(sx);sx = 1;end
if nargin < 5; t = []; end
if nargin < 6; t_center = r_center; end
if nargin < 7; fastflag = false; end

if ~isempty(t) && numel(t) ~= 2
    error('Basic undistortion function supports two (2) tangential distortion coefficients')
end

if ~isempty(t)
   org_x = x(1:2,:); 
end

r_center = r_center(:);

without_r_center = bsxfun(@minus,x(1:2,:),r_center);

%Radial distortion distance
if sx == 1
    d2 = sqrt(sum(without_r_center.^2,1));
else
    tmp = without_r_center;
    tmp(1,:) = tmp(1,:)./sx;
    d2 = sqrt(sum(tmp.^2,1));
end
    
if ~fastflag
    d2 = solved2(d2,r);
else
    min_max = [min(d2) max(d2)];
    if min_max(2)-min_max(1) < 100
        %At least 100 points
        d2_ = linspace(min_max(1),min_max(2),100);
    else
        %Point for each "pixel"
        d2_ = min_max(1):min_max(2);
        if d2_(end) ~= min_max(2) 
            d2_ = [d2_ min_max(2)]; 
        end
    end
    d2_ = solved2(d2_,r);
    
    %Interpolate
    d2(:) = interp1q(linspace(min_max(1),min_max(2),numel(d2_))',d2_(:),d2(:));
    %d2(:) = interp1(linspace(min_max(1),min_max(2),numel(d2_))',d2_(:),d2(:),'cubic');
end

d2 = d2.^2;

%Radial distortion
l = ones(size(d2));
for ii = 1:numel(r)
   l = l+r(ii)*d2.^ii;
end

%Remove radial distortion
without_r_center(1:2,:) = bsxfun(@rdivide,without_r_center(1:2,:),l);
x(1:2,:) = bsxfun(@plus,without_r_center(1:2,:),r_center);

%Add tangential distortion
if ~isempty(t)
    error('Solution for tangential distortion not implemented')
    %t_center = t_center(:);
    %without_t_center = bsxfun(@minus,org_x,t_center);
    %d2 = sum(without_t_center.^2,1);
    %x(1,:) = x(1,:) + 2*t(1)*org_x(1,:).*org_x(2,:)+t(2).*(d2+2.*org_x(1,:).^2);
    %x(2,:) = x(2,:) + 2*t(2)*org_x(2,:).*org_x(2,:)+t(1).*(d2+2.*org_x(2,:).^2);
end
return

function d2 = solved2(d2,r)
switch numel(r)
    case 2
        for ii = 1:numel(d2)
            %collect(d*(1+k1*d^2+k2*d^4)-u,d)
            tmp = roots([r(2) 0 r(1) 0 1 -d2(ii)]);
            if numel(tmp) == 1
                d2(ii) = tmp;
                continue
            end
            idx = tmp == real(tmp);
            if sum(idx) == 1
                d2(ii) = tmp(idx);
            else
                tmp = sqrt(unique(tmp(idx).^2));
                d2(ii) = min(tmp);
                %error('Only partial solution, edit function');
            end
        end
    case 1
        for ii = 1:numel(d2)
            %collect(d*(1+k1*d^2)-u,d)
            tmp = roots([r(1) 0 1 -d2(ii)]);
            if numel(tmp) == 1
                d2(ii) = tmp;
            end
            idx = tmp == real(tmp);
            if sum(idx) == 1
                d2(ii) = tmp(idx);
            else
                error('Only partial solution, edit function');
            end
        end
end
return
