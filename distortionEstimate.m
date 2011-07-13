function r = distortionEstimate(x,X,P,K)
%Estimate radial distortion from image points (x), world points (X), 
%camera matrix (estimate, or homography H, see below) (P) 
%and calibration matrix (estimate) (K)
%
%Inputs:
%      x - Image points 3xn (can be cell array of points)
%      X - World points 4xn (or if P is homograhphy matrix (3x3), 3xn planar
%          points). (can be cell array of points)
%      P - Camera matrix  (can be cell array of camera matrices)
%           (or Homography matrix H which is multiplied with inverse of 
%            calibration matrix e.g P = inv(K)*H, if X are planar points)
%      K - Calibration matrix
%Outpus:
%      r - distortion parameters (estimate)
%
%Note: It is highly recommended to use real camera matrix instead of 
%      homography matrix as homography matrix estimation tends to ruin
%      distortion estimations.
%      Camera matrix P should be form P = [R -R*t] (not multiplied with K)
%
%Comparison to Zhangs notation
% x = u^, v^ (observed image coordinates)
% x_optim = u, v (ideal points)
% x_norm = x,y (normalized ideal points)
% rc = u0,v0 (distortion center)
%
%Zhang - Flexible Camera Calibration By Viewing a Plane From Unknown Orientations
%    
%Matti Jukola 2011.02.01

%Fiddle with inputs in case of cell arrays were provided
if iscell(X)
    %Assume that all others are too
    num_points = 0;
    for ii = 1:numel(X)
        num_points = num_points + size(X{ii},2);
    end
    
    x_optim = zeros(3,num_points);
    x_norm = zeros(3,num_points);
    x_tmp = zeros(3,num_points);
    
    idx = 1;
    for ii = 1:numel(X);
        n = size(X{ii},2);
        
        if size(X{ii},1) == 3 && (size(P{ii},1) == 3 && size(P{ii},2) == 4)
            %Assume planar points
            X{ii} = convertToHom([X{ii}(1:2,:);zeros(1,size(X{ii},2))]);
        end
        
        tmp = wnorm(K*P{ii}*X{ii});
        x_optim(:,idx:idx+n-1) = tmp;
        
        tmp = wnorm(K\x_optim(:,idx:idx+n-1));
        x_norm(:,idx:idx+n-1) = tmp;
        
        x_tmp(:,idx:idx+n-1) = x{ii};
        
        idx = idx+n;
    end
    x = x_tmp;
else 
    if size(X,1) == 3 && (size(P,1) == 3 && size(P,2) == 4)
        %Assume planar points
        X = convertToHom([X(1:2,:);zeros(1,size(X,2))]);
    end
    x_optim = wnorm(K*P*X);
    x_norm = wnorm(K\x_optim);
    x = wnorm(x);
end



%Distortion center
rc = K(1:2,3);

x2y2 = x_norm(1,:).^2+x_norm(2,:).^2;
u_u0 = x_optim(1,:)-rc(1);
v_v0 = x_optim(2,:)-rc(2);
u_u = x(1,:)-x_optim(1,:);
v_v = x(2,:)-x_optim(2,:);

D = [u_u0'.*x2y2' u_u0'.*x2y2'.^2;
     v_v0'.*x2y2' v_v0'.*x2y2'.^2];
d = [u_u';
     v_v'];

r = D\d;