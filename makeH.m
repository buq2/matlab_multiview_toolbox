function H = makeH(x1,x2,method)
%Creates homography from x1 to x2 such that:
%wnorm(x2) = wnorm(H*w)
%
%x1 can be 3D points in which case we are estimating P (projection matrix)
%
%HZ Algorithm 4.2 p.109 (Normalized DLT for 2D homographies)
%HZ Algorithm 7.1 p.181 uses this algorithm for 3D->2D (initial estimation
%of P)

%If method = true, creates 3*n A matrix (default)
%x1 = x
%x2 = x'

%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.06.xx - Initial version

if nargin < 3
    method = false; %false = use 2 equations when makin A, true, use 3
end
dim = size(x1,1)-1;

%Normalization of points (scale and translation) improves accuracy
%as "weights" of the linear equation are approximately same size
[x1_ T1] = normalizePoints(x1);
[x2_ T2] = normalizePoints(x2);
if dim == 3
    %For three dimensional data we will do few tricks
    %TODO: Is this necessary? Is there better way?
    T2_tmp = T2;
    T2 = eye(4);
    T2([1 2],[1 2]) = T2_tmp([1 2],[1 2]);
    T2(1:2,end) = T2_tmp(1:2,end);
end

%Create matrix A and solve it
[U S V] = svd(makeA(x1_,x2_,method),false);
%S = diag(S);
%h = V(:,S == min(S)); %(Should not be used, does not work for 3D case)
h = V(:,9); %TODO: should this be V(:,end)?
if dim == 2
    H = zeros(3);
else
    H = zeros(3,4);
end
H(:) = h(:);
if dim == 3 %3D->2D
    warning('Not fully tested')
    H = T2\[H;[0 0 0 1]]'*T1;
    H = H(1:3,:);
else %2D->2D
    H = T2\H'*T1;
end