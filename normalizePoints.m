function [x T] = normalizePoints(x,method)
%Point normalization
%Method == 1: HZ2 7.1 Data normalization p. 180 
%             HZ2 4.4.4 Normalizing transformations p.107
%   Not implemented: ideal points and points far away (HZ 4.9.2 (ii) p. 128)
%Method == 2: 3D Computer Vision: p. 45

%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.04.xx - Initial version

%NOTE: You should call wnorm for points before calling this function
%      otherwise transformation matrix is not optimal

if nargin < 2
    method = 1;
end

dim = size(x,1)-1; %2 or 3 (point dimension)

T = eye(dim+1); %Ready transformation matrix

m = mean(x(1:dim,:),2); %Mean of points (note that homogenous coordinate is not used)

T(1:dim,dim+1) = -m(1:dim); %Center points

xx = bsxfun(@minus,x(1:dim,:),m(1:dim)); %Remove mean

if method == 1
    d = mean(sqrt(sum(xx.^2,1)));
    d = repmat(d,[dim 1]);
else
    d = sqrt(mean(xx.^2,2));
end
if any(d == 0)
    d(d==0) = 1;
end

if method == 1
    T = diag([sqrt(dim)./d; 1])*T;
elseif method == 2
    T = diag([1./d; 1]);
    T(1:dim,end) = -m.*(1./d);
else 
    error('Unknown method')
end
x = T*x; %Transform points




