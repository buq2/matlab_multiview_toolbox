function h_out = plotCamera(P,siz,K)
%Plots camera matrix P and calibration matrix K as a 3D camera
%
%Matti Jukola 2010

if nargin < 2 || isempty(siz)
    siz = 0.2;
end
if nargin < 3
    K = eye(3);
    K(1,3) = 1;
    K(2,3) = 1;
end

[tmpK R C] = decomposeP(P);
%Point distance from origo (Z axis) = 1
points = [1   1   1   1;... %Upper-right
          1  -1   1   1;... %Lower-right
         -1  -1   1   1;... %Lower-left
         -1   1   1   1]';  %Upper-left
     
%Scale image planes x-axis to 1 length 1
K = K./K(1,3)/2;
points(1,:) = points(1,:)*K(1,3); %Scale image planes x-axis
points(2,:) = points(2,:)*K(2,3); %y-axis
points(3,:) = points(3,:)*mean([K(1,1) K(2,2)]); %Focal

%Scale camera
points(1:3,:) = points(1:3,:).*siz;

%Rotate camera
proj = [inv(R) zeros(3,1);0 0 0 1];
p = wnorm(proj*points);
p = bsxfun(@plus,p(1:3,:),C(1:3));

hold on
%Plot frame
h = plot3([p(1,:) p(1,1)],[p(2,:) p(2,1)], [p(3,:) p(3,1)],'k');

%Plot frame corners -> camera center
for ii = 1:size(p,2)
    h = [h plot3([C(1) p(1,ii)],[C(2) p(2,ii)],[C(3) p(3,ii)],'k')];
end

hold off

if nargout > 0
    h_out = h;
end