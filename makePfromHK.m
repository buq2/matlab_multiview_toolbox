function [P optim] = makePfromHK(H,K,optim,x,X,optimparam)
%Calculates camera matrix P (and rotation matrix R and camera center C
%so that P = [R -R*C], note that P is not multiplied with K) 
%from planar homography H and camera calibration
%matrix K.
%
%This function is quite close to actual camera calibration. Main difference
%is that we assume that K is already known quite well.
%
%We assume that the plane (which has points X, for which x = H*X) has normal 
%vector [0 0 1 1]' (as Z is usually 0) and that camera center should be at
%positive Z. This makes the algorithm more stable, as camera can not
%easily flip to the other side of the plane.
%
%Inputs:
%      H     - Homography matrix (3x3), can be cell, in which case
%                camera matrix will be computed dor each H independently
%                (no bundle adjustment of calibration matrix)
%      K     - Camera calibration matrix
%      optim - (optional) If true, nonlinear optimization is performed to 
%                mimize reprojection error
%      x     - (optional) Image points
%      X     - (optional) World points
%      optimparam - Optimization parameter struct with following fields
%        r       - Initial radial distortion for nonlinear 
%                  optimization. Default no radial distortion.
%        r_optim - True/false, if true radial distortion will be optimized.
%                  Default false. If true also r must be set.
%        t       - Initial tangential distortion for nonlinear optimization
%                  Default, no tangential distortion.
%        t_optim - True/false, if true tangential distortion will be
%                  optimized. Default false. If true also t must be set.
%        K_optim - True/false 3x3 matrix used in deciding which parameters
%                  in camera calibration should be optimized. Default
%                  zeros(3)
%        f_optim - True/false. If true focal length will be optimized.
%                  In this mode K(1,1) and K(2,2) can be multiplied with
%                  constant. Result will be returned as new K. If you also
%                  want to use K_optim, you should either leave K(1,1)
%                  and K(2,2) both as'false' (in which case only focal length
%                  changes) or 'true' (in which case f should be left as
%                  false as K(1,1) and K(2,2) will be both optimized).
%
%
%Outputs:
%      P - Camera matrix
%      optim - If non linear optimization was used, optimized values
%              will be placed in this struct as fields 'K','r' and 't'
%Note: Homography should have been calculated from undistorted coordinates
%       to increase accuracy.
%       You can try to use function 'distortionEstimate' to estimate radial
%       distortion and 'undistort' to undistort the image coordinates.
%       Below is small code bit that can be used to estimate distortion and
%       undistort pixel coordinates (x) in one row:
%       K*undistort(K\x,distortionEstimate(x,X,inv(K)*H,K))
%       where X are planar points (3xn) which were used to calculate
%       homography H. Unfortunately this is quite inaccurate.
%
%Zhang - Flexible Camera Calibration By Viewing a Plane From Unknown Orientations
%
%Also good reference is:
%Liljequist -  Planes, Homographies and Augmented Reality
%
%Matti Jukola 2011.02.01

%By making sure that the last value of H has always the same sign,
%we ensure that camera is always at the same side of the normal vector of
%the plane. (This is because last column of H is related to camera
%location. We assume that calibration matrixs' last element is also 1.)
H = H./H(end);

if nargin < 3
    optim = false;
end
if nargin < 6
    optimparam = [];
end

if iscell(H)
    P = cell(size(H));
    R = cell(size(H));
    C = cell(size(H));
    for ii = 1:numel(H)
        [P{ii} R{ii} C{ii}] = makePfromHK(H{ii},K);
    end
    return
end

%P = K*[r1 r2 r3 -R*C]
%if X_i = [x_i y_i 0 w_i]'
%x_i = P*X_i = K*[r1 r2 -R*C]*[x_i y_i w_i]';

%As H has been computed up to unknwon multiplier lambda:
%[h1 h2 h3] = lambda*K*[r1 r2 t] 
h1 = H(:,1);
h2 = H(:,2);
h3 = H(:,3);
iK = inv(K);

%Solve lambda (rotation matrix is orthonormal, so norm of first two columns
%should be 1)
lambda1 = 1/norm(iK*h1);
lambda2 = 1/norm(iK*h2);
lambda = mean([lambda1 lambda2]);

%And use it to get initial rotation matrix for this homography
r1 = lambda*iK*h1;
r2 = lambda*iK*h2;
%As rotation matrix is orthonormal r3 can be calculated from first two
%columns
r3 = cross(r1,r2);

R = [r1 r2 r3];
%Approximate best 3x3 rotation matrix (Zhang App C)
%Rectify rotation matrix
[U S V] = svd(R);
R = U*V'; %Assume S = eye(3)
%This R does not generally satisfy all properties of rotation matrix

%Calculate translation vector and camera center
t = lambda*iK*h3; %TODO: is this lambda the "new" one or the "old" one?

if optim
    %if t(3) < 0 %If camera at negative Z
    %    %Flip camera to the positive side
    %    t(3) = -t(3);
    %end
        
    if size(X,1) == 3
        X = wnorm(X);
        X = convertToHom([X(1:2,:); zeros(1,size(X,2))]);
    end
    ang = rodrigues(R);
    param = [ang(:)' t'];
    
    %Do we also optimize some other parameters
    if ~isempty(optimparam)
        
        %Radial distortion
        if isfield(optimparam,'r_optim') && optimparam.r_optim
            param = [param optimparam.r(:)'];
        else
            optimparam.r_optim = false;
            if ~isfield(optimparam,'r') || all(optimparam.r == 0)
                optimparam.r = [];
            end
        end
        
        %Tangential distrotion
        if isfield(optimparam,'t_optim') && optimparam.t_optim
            param = [param optimparam.t(:)'];
        else
            optimparam.t_optim = false;
            if ~isfield(optimparam,'t') || all(optimparam.t == 0)
                optimparam.t = [];
            end
        end
        
        if isfield(optimparam,'K_optim')
            %Make sure that only upper triangular matrix can be changed
            %(minus K(end) = 1)
            optimparam.K_optim = optimparam.K_optim & triu(ones(3));
            optimparam.K_optim(end) = 0;
            
            k = K(optimparam.K_optim);
            param = [param k(:)'];
        else
            optimparam.K_optim = [];
        end
        
        if isfield(optimparam,'f_optim') && optimparam.f_optim
            %Focal length can change
            param = [param 1]; %By default mutliply focal length with 1
        else
            optimparam.f_optim = false;
        end
    end   
    
    %Optimize
    %param = lsqnonlin(@(p)nonlinfun(optimparam,x,X,K,p),...
    %    param(:),...
    %    [],[],...
    %    optimset('TolX',1e-10,'TolFun',1e-10,'Algorithm','levenberg-marquardt','Display','iter','maxiter',20));
    if exist('lsqnonlin','builtin')
        [param,resnorm,residual,exitflag,output,lambda,jacobian]  = lsqnonlin(@(p)nonlinfun(optimparam,x,X,K,p),...
            param(:),...
            [],[],...
            optimset('TolX',1e-15,'TolFun',1e-10,'Algorithm','levenberg-marquardt','Display','iter','maxiter',20));
    else
        %param = LMFsolve(@(p)nonlinfun(optimparam,x,X,K,p), param(:));
        param = LMFnlsq2(@(p)nonlinfun(optimparam,x,X,K,p), param(:),'XTol',1e-16,'Basdx',25e-6,'MaxIter',1000,'FunTol',1e-14);
    end
    
    %Get rotation matrix
    R = rodrigues(param(1:3));
    
    %Get translation vector
    t = param(4:6);
    
    %Did we use optimparam?
    optim = struct;
    idx = 7;
    if ~isempty(optimparam)
        if optimparam.r_optim
            num = numel(optimparam.r);
            optim.r = param(idx:idx+num-1);
            idx = idx + num;
        end
        if optimparam.t_optim
            num = numel(optimparam.t);
            optim.t = param(idx:idx+num-1);
            idx = idx + num;
        end
        if ~isempty(optimparam.K_optim)
            optim.K = K;
            num = sum(optimparam.K_optim(:));
            optim.K(optimparam.K_optim) = param(idx:idx+num-1);
            idx = idx + num;
        end
        if optimparam.f_optim
            %Did we already save K?
            if isempty(optimparam.K_optim)
                optim.K = optim.K;
            end
            
            %Multiply focal length
            num = 1;
            optim.K(1,1) = optim.K(1,1)*param(idx);
            optim.K(2,2) = optim.K(2,2)*param(idx);
            idx = idx+num;
        end
    end
end

P = [R t];
return

function er = nonlinfun(optimparam,x,X,K,param)
%Nonlinear error function for nonlinear optimization
%param vector contains
%[ang1 ang2 ang3 t1 t2 t3 r1 r2]
R = rodrigues(param(1:3));
t = param(4:6);
t = t(:);

distortion = false;
if ~isempty(optimparam)
    idx = 7;
    if optimparam.r_optim
        distortion = true;
        num = numel(optimparam.r);
        optimparam.r = param(idx:idx+num-1);
        idx = idx + num;
    end
    if optimparam.t_optim
        distortion = true;
        num = numel(optimparam.t);
        optimparam.t = param(idx:idx+num-1);
        idx = idx + num;
    end
    if ~isempty(optimparam.r) || ~isempty(optimparam.t)
        distortion = true;
    end
    if ~isempty(optimparam.K_optim)
        num = sum(optimparam.K_optim(:));
        K(optimparam.K_optim) = param(idx:idx+num-1);
        idx = idx + num;
    end
    if optimparam.f_optim
        %Multiply focal length
        num = 1;
        K(1,1) = K(1,1)*param(idx);
        K(2,2) = K(2,2)*param(idx);
        idx = idx+num;
    end
end

x_ = wnorm(K*[R t]*X);
if distortion
    x_ = distortCamera(x_,K,optimparam.r,optimparam.t);
end

er = x(1:2,:)-x_(1:2,:);
er = er(:); %Required for LMFsolve
return








