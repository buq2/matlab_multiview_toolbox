function [er_or_erx ery] = calculatePKdist(x,X,P,K,r,t,sx,r_center,t_center)
%Calculates reprojection error for each image point x ([wx wy w]') and real world point
%X ([wX wY wZ w]') when projection matrix P, camera calibration matrix K
%and distortion parameters (r, r_center, sx, t, t_center) are known.
%
%Inputs:
%   x        - Image points, 3xn matrix or cell array of 3xn_i matrices
%   X        - Real world points, 4xn matrix or cell array
%   P        - Projection matrix, 3x4 or cell array
%              Default [eye(3) zeros(3,1)]
%   K        - Camera matrix, 3x3 or cell array
%              Default eye(3)
%   r        - Radial distortion coefficients, array
%              Default 0. Distortion center is by default pricipal
%              point.
%   t        - Tangential distortion coefficients, array
%              Default 0. Distortion center is by default pricipal
%              point.
%   sx       - Radial distortion aspect ratio, scalar
%              Default 1
%   r_center - Center of radial distortion from principal point, [x y]
%              Default [0 0]
%   t_center - Center of tangential distortion from principal point, [x y]
%              Default [0 0].
%
%Outpus:
%   er_or_erx - Reprojection error for each pixel squared or if nargout = 2
%               reprojection difference in x direction (not squared, can be
%               negative)
%   ery       - Reprojection difference in y direction (not squared, can be
%               negative)
%
%NOTE: Output is identical to Bouguets calibration toolboxes 'Analyse
%error' function when calling this function:
%[er_x er_y] = calculatePKdist(x,X,P,K,r,t);
%plot(er_x,er_y,'r.')
%Where:
%r = kc([1 2 5])
%t = kx(3:4)
%P = [res.Rc_* res.Tc_*]
%K = KK
%x = x_*
%X = X_*
%
%Matti Jukola 2010.12.22

if nargin < 3 || isempty(P)
    P = [eye(3) zeros(3,1)];
end
if nargin < 4 || isempty(K)
    K = eye(3);
end
if nargin < 5
    r = 0;
end
if nargin < 6
    t = [];
end
if nargin < 7
    sx = 1;
end
if nargin < 8
    r_center = [0 0];
end
if nargin < 9
    t_center = [0 0];
end

%Error value for each pixel

%If x is cell array, for each cell call calculatePKdist
if iscell(x)
    er_or_erx = zeros(cellfun(@(a)size(a,2),x),1);
    if nargout > 1
        ery = zeros(size(er_or_erx));
    end
    num = 1;
    for ii = 1:numel(x)
        %If cell arrays were provided, "unpack" them
        X_ = unpack(X,ii);
        P_ = unpack(P,ii);
        K_ = unpack(K,ii);
        r_ = unpack(r,ii);
        r_center_ = unpack(r_center,ii);
        sx_ = unpack(sx,ii);
        t_ = unpack(t,ii);
        t_center_ = unpack(t_center,ii);
        
        if nargout == 1
            tmp1 = calculatePKdist(x{ii},X_,P_,K_,r_,t_,sx_,r_center_,t_center_);
            er_or_erx(num:num+numel(tmp1)-1) = tmp1;
        else
            [tmp1 tmp2] = calculatePKdist(x{ii},X_,P_,K_,r_,t_,sx_,r_center_,t_center_);
            er_or_erx(num:num+numel(tmp1)-1) = tmp1;
            ery(num:num+numel(tmp1)-1) = tmp2;
        end
        num = num+numel(tmp1);
    end
    return
end

if size(X,1) == 3
    warning('Assuminng planar 3D points, converting to homogenous 3D points Z=0')
    X = [X(1:2,:); zeros(1,size(X,2)); X(3,:)];
end

%Project points
x_ = K*P*X;

x_ = wnorm(x_);
x = wnorm(x);

%If there is some distortion, apply it to projected points
if ~all(r==0) || (~isempty(t) && ~all(t==0))
    x_ = distortCamera(x_,K,r,t,sx,r_center,t_center);
end

%Calculate difference
if nargout == 1
    er_or_erx = sum((x(1:2,:)-x_(1:2,:)).^2)';
else
    er_or_erx = x(1,:)-x_(1,:);
    ery = x(2,:)-x_(2,:);
end
return


function out = unpack(s,ii)
if iscell(s)
    out = s{ii};
else
    out = s;
end












