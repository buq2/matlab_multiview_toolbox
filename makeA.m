function A = makeA(x,x2,method)
%DLT algorithm for calculating 2D->2D Homography or 3D->2D Homography
%Used for calculating 2D->2D homographys or 
%initial estimation for projection matrix P
%
%x = x (2D->2D) or x (3D->2D)
%x2 = x' (2D->2D) or X (3D->2D)
%
%HZ2 Algorithm 4.1 p.91 (note also Algorithm 4.2 p.109)
%HZ2 (4.1) and (4.3) p.89 for 2D->2D case
%HZ2 (7.2) p.178 for 3D->2d case

%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.04.xx - Initial version

if nargin < 3
    method = false;
end
if method
    nn = 3; %Use three quations HZ (4.1) or (7.1)
else
    nn = 2; %Use two equations HZ (4.3) or (7.2)
end
if size(x,1) == 4
   vecLen = 4;
else
   vecLen = 3;
end

A = zeros(nn.*numel(x)/vecLen,vecLen*3);

x = x';
x2 = x2';
if nn == 3
    A(2:3:end,1:vecLen) = bsxfun(@times,x,x2(:,end));
    A(3:3:end,1:vecLen) = bsxfun(@times,x,-x2(:,2));
    A(1:3:end,vecLen+1:vecLen*2) = bsxfun(@times,x,-x2(:,end));
    A(3:3:end,vecLen+1:vecLen*2) = bsxfun(@times,x,x2(:,1));
    A(1:3:end,vecLen*2+1:end) = bsxfun(@times,x,x2(:,2));
    A(2:3:end,vecLen*2+1:end) = bsxfun(@times,x,-x2(:,1));
else
    A(2:2:end,1:vecLen) = bsxfun(@times,x,x2(:,end));
    A(1:2:end,vecLen+1:vecLen*2) = bsxfun(@times,x,-x2(:,end));
    A(1:2:end,vecLen*2+1:end) = bsxfun(@times,x,x2(:,2));
    A(2:2:end,vecLen*2+1:end) = bsxfun(@times,x,-x2(:,1));
end