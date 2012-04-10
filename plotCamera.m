function h_out = plotCamera(P,siz,color,text_plot)
%Plots camera matrix P=K*[R T] as a 3D camera
%
%Inputs:
%      P - Camera matrix P=K*[R T]=K*[R -R*C] which should be visualized
%    siz - Length of camera cone. In same units as camera location C.
%             Defaults to 1 (which is usually very bad choice).
%  color - Color of camera cone. Either 'b','r',... or [1 0 0] etc.
%             Defaults 'k' (black)
%   text_plot - If given this text will be plotted to camera center C
%
%Matti Jukola 2010
%Updated 2011.10.11

if nargin < 2 || isempty(siz)
    siz = 1;
end
if nargin < 3 || isempty(color)
    color = 'k';
end

[K R C] = decomposeP(P);
C = wnorm(C);

%Assume that pricipal point is at the middle of the image plane
sizeimg = [K(1,3) K(2,3)]'*2; %[x y]'
sizeimg(sizeimg==0) = 1; %Force to have at least 1 pixel.


%Point distance from origo (Z axis) = 1
% points = [1   1   1   1;... %Upper-right
%           1  -1   1   1;... %Lower-right
%          -1  -1   1   1;... %Lower-left
%          -1   1   1   1]';  %Upper-left

x = [0 0 1 1; %Four corners of image plane
     0 1 1 0;
     1 1 1 1];
x(1:2,:) = bsxfun(@times, x(1:2,:), sizeimg);

n = wnorm(pinv(P)*x); %Vectors pointing away from camera
n(1:3,:) = bsxfun(@minus,n(1:3,:),C(1:3,:));
%Normalize to unit lenght
nnorm = n;
nnorm(1:3,:) = bsxfun(@rdivide, n(1:3,:), sqrt(sum(n.^2)));
nnorm(1:3,:) = nnorm(1:3,:)*siz;

X = nnorm;
X(1:3,:) = bsxfun(@plus,X(1:3,:),C(1:3)); %Add camera location to corner points

hold on
%Plot frame
h = plot3([X(1,:) X(1,1)],[X(2,:) X(2,1)], [X(3,:) X(3,1)],'color',color);

%Plot frame corners -> camera center
for ii = 1:size(X,2)
    h = [h plot3([C(1) X(1,ii)],[C(2) X(2,ii)],[C(3) X(3,ii)],'color', color)];
end

hold off

if nargout > 0
    h_out = h;
end

if nargin > 3
    text(C(1),C(2),C(3),text_plot)
end