function cosphi = calculateCosPhi(x1,x2,K)
%Calculate cos(phi) where phi is angle between two rays which both
%intersect at camera center and at image plane on points x1 and x2.
%(Calculates angle between two projected rays from image plane to camera
%center).
%
%Inputs:
%      x1 - Point(s) 1, homogenous 3xn matrix
%      x2 - Point(s) 2
%      K  - Camera calibration matrix
%
%Output:
%      cos(phi) - Cos(phi) of angle phi between two rays
%
%HZ2 (8.9) p.210
%
%Example:
% %Create random camera matrix
% r = rand(3,1);
% C = rand(4,1);
% C = wnorm(C);
% R = rodrigues(r);
% K = triu(rand(3));
% P = K*[R -R*C(1:3)];
% 
% %Create two random points
% X1 = wnorm(rand(4,1));
% X2 = wnorm(rand(4,1));
% 
% %Using known camera center C, calculate angle between rays using 
% %vectors
% q = X1-C;
% w = X2-C;
% q = q/norm(q);
% w = w/norm(w);
% cosphi1 = dot(q,w)
% 
% %Calculate angle using this function, result should be same
% x1 = P*X1;
% x2 = P*X2;
% cosphi2 = calculateCosPhi(x1,x2,K)
%
%Matti Jukola 2011.10.10

w = inv(K*K.'); %Image of absolute conic
cosphi = zeros(1,size(x1,2));

for ii = 1:size(x1,2)
    cosphi(ii) = x1(:,ii)'*w*x2(:,ii)/(sqrt(x1(:,ii)'*w*x1(:,ii))*sqrt(x2(:,ii)'*w*x2(:,ii)));
end