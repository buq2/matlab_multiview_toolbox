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

%Add tangential distortion
if ~isempty(t)
    %error('Solution for tangential distortion not implemented')
    if exist('lsqnonlin','builtin')
        [x]  = lsqnonlin(@(param)tangential_optim(x, t, t_center, param),...
            x,...
            [],[],...
            optimset('Algorithm','levenberg-marquardt','Display','iter','maxiter',20));
    else
        x_new = LMFsolve(@(param)tangential_optim(x, t, t_center, param),x);
        x = reshape(x_new,size(x));
    end
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
    
%For small number of x1, use more accurate, non-interpolate, version
if ~fastflag || size(x,2) < 3
    d2 = solved2(d2,r);
else
    min_max = [min(d2) max(d2)];
    if min_max(2)-min_max(1) < 100
        d2_ = linspace(min_max(1),min_max(2),128);
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

%Slow but sure way to remove tangential distortion by optimizing
function err = tangential_optim(x_distorted, t, t_center, x_undistorted)
x_distorted_optim = distort(x_undistorted, [], [], 1, t, t_center);
err = wnorm(x_distorted) - wnorm(reshape(x_distorted_optim, size(x_distorted)));
err = err(1:2,:); %Last row always 0 due to homogenous coordinates (1-1)
err = err(:);
return