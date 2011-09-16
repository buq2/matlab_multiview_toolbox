function [P K H r t] = makeP(x,X,Optimparam,method,normalization)
%Calculates calibration matrix K from real world points X and image points 
%x.
%
%Inputs:
%      x     - Image points
%      X     - Real world coordinates
%      optimparam - Optimization parameter struct with following fields
%        r       - Initial radial distortion for nonlinear 
%                  optimization. Default no radial distortion.
%        r_optim - True/false, if true radial distortion will be optimized.
%                  Default false. If true also r must be set. Default true.
%        t       - Initial tangential distortion for nonlinear optimization
%                  Default, no tangential distortion.
%        t_optim - True/false, if true tangential distortion will be
%                  optimized. Default false. If true also t must be set.
%                  Default false.
%        K_optim - True/false 3x3 matrix used in deciding which parameters
%                  in camera calibration should be optimized. Default
%                  zeros(3)
%
%If method = true, creates 3*n A matrix (default)
%X = x or X (real world coordinates)
%x = x' (image coordinates)
%
%method = 1 -> Heikkila & Silvennoinen
%method = 2 -> "Kalle Marjanen"
%method = 3 -> HZ Algorithm 7.1 p. 181 (3D calibration).
%              This method is suitable for calculating P if 3D points X and
%              their projections 2D points x are well known. Solves P for
%              x = P*X. P can be form P = K*[M -Mt] (calibration matrix
%              can be calculated using this method).
%              Revised 2011.05.31
%method = 4 -> Yi Ma, Stefano Soatto et. al. p. 203 (Planar).
%method = 5 -> Zhang - Flexible Camera Calibration By Viewing a Plane From Unknown Orientations (Planar)
%method = 6 -> HZ Example 8.18 p.211 A simple calibration device (Planar)
%
%Matti Jukola 2010

if nargin < 4
    method = 5;
end
if nargin < 5
    normalization = false;
end

if method == 5 && normalization
    warning('There is few problems with normalization when using Zhang')
    %You should use HZ algorithm
end

%Make sure w = 1
if iscell(X)
    for ii = 1:numel(X)
        X{ii} = wnorm(X{ii});
        x{ii} = wnorm(x{ii});
    end
else
    X = wnorm(X);
    x = wnorm(x);
end

%Normalize if needed. TODO: which algorithms require normalization?
if normalization
    if iscell(X)
        T1 = cell(size(X));
        T2 = T1;
        for ii = 1:numel(X)
            [X{ii} T1{ii}] = normalizePoints(X{ii});
            [x{ii} T2{ii}] = normalizePoints(x{ii});
        end
    else
        [X T1] = normalizePoints(X);
        [x T2] = normalizePoints(x);
    end
end

P = zeros(3,4);

if any(method == [1 2])
    error('Not working')
    
   %Heikkila & Silvennoinen
   L = makeL(X,x); 
   
%    %%TESTZONE
%    [U S V] = svd(L,false);
    %P(:) = V(:,end);
%    P(:) = reshape(V(:,end),4,3)';
%    K = camParamFromP(P);
%    return
%    %%TESTZONE

   
   %Set constraints 
   %1) P(3,4) = 1;
   %2) ||P(3,1:3)|| = 1
%   P(end) = 1; %First constraint
   %Second costraint
%   d=sqrt(sum(P(3,1:3).^2)); 
%   P=P/d;
   
   if method == 1
       [U S V] = svd(L);
   end
elseif method == 3
    warning('Not fully tested (should work)')
    %HZ Algorithm 7.1 p. 181 (3D calibration)
    %"Gold Standard"
    
    %Linear solution susing DLT
    A = makeA(X,x);
    [U,S,V] = svd(A,false);
    P(:) = reshape(V(:,end),4,3)';
    P = P./P(end);
    
    %Non-linear optimization
    params = P(:);
    params = lsqnonlin(@(p)P_HZ_nonlin_fun(X,x,p),params(:));%,[],[],optimset('TolFun',1e-999,'TolX',1e-999,'MaxFunEvals',10000));
    P(:) = params(1:12);
    if nargout > 1
       [K R C] = decomposeP(P); 
    end
elseif method == 4
    warning('Not fully tested')
    %Only for planar objects
    if any(x1(3,:))
        error('Method is suitable only for planar calibration platters')
    end
    H = makeH(X([1 2 4],:),x);
    H(end) = 1; %Constraint
    
    %Invitation p.203 + calibru extinit.m
    h1 = H(:,1);
    h1 = h1/norm(h1);
    h2 = H(:,2);
    h2 = h2/norm(h2);
    h3 = cross(h1,h2); 
    R = [h1 h2 h3];
    
    [U S V] = svd(R-eye(3),false); %HZ p. 584
    v = V(:,3);
    %skew-matrix (vector which does not rotate):
    %v_ = [R(3,2)-R(2,3),R(1,3)-R(3,1),R(2,1)-R(1,2)]';
    ang = atan2(v'*v/2,(trace(R)-1)/2);
elseif method == 5
    %Zhang - Flexible Camera Calibration By Viewing a Plane From Unknown Orientations
    %Notation in this method is from Zhangs paper
    if ~iscell(X)
       error('xy1 and xy2 must be cells') 
    end
    
    %Calculate planar homographys from point correspondances
    %Also makes sure that x1 is in correct form
    [H X] = planarHomographys(X,x);
    
    %NOTE: Zhang writes: "Let the i:th column vector of H be h_i = [h_i1, h_i2, h_i3]'..."
    %      this is little bit confusing as he is marking column (i) before row in this case,
    %      but just few ago he marked rows before columns (B_12...)
    %      Below is wrong indecing commented out and correct one is in use.
%     v = @(H,i,j)([H(i,1)*H(j,1);...
%                   H(i,1)*H(j,2)+H(i,2)*H(j,1);...
%                   H(i,2)*H(j,2);...
%                   H(i,3)*H(j,1)+H(i,1)*H(j,3);...
%                   H(i,3)*H(j,2)+H(i,2)*H(j,3);...
%                   H(i,3)*H(j,3)]);
    v = @(H,i,j)([H(1,i)*H(1,j);...
                  H(1,i)*H(2,j)+H(2,i)*H(1,j);...
                  H(2,i)*H(2,j);...
                  H(3,i)*H(1,j)+H(1,i)*H(3,j);...
                  H(3,i)*H(2,j)+H(2,i)*H(3,j);...
                  H(3,i)*H(3,j)]);
    V = zeros(2*numel(H),6);
    for ii = 1:numel(H)
        V((ii-1)*2+1,:) = v(H{ii},1,2)';
        V(ii*2,:) = (v(H{ii},1,1)-v(H{ii},2,2))';
    end
    %V(end+1,:) = [0 1e3 0 0 0 0]; %Constraint: Skewness = 0
    [U S V] = svd(V);
    b = V(:,end); %Right singular vector associated with smallest (right most in V in MATLAB) singular value
    B = [b(1) b(2)     b(4);...
         b(2) b(3)     b(end-1);...
         b(4) b(end-1) b(end)];
    %b == [B(1,1) B(1,2) B(2,2) B(1,3) B(2,3) B(3,3)]'; %Just for checking that everything is in order
    v0 = (B(1,2)*B(1,3)-B(1,1)*B(2,3))/(B(1,1)*B(2,2)-B(1,2)^2);
    lambda = B(3,3)-(B(1,3)^2+v0*(B(1,2)*B(1,3)-B(1,1)*B(2,3)))/B(1,1);
    alpha = sqrt(lambda/B(1,1));
    beta = sqrt(lambda*B(1,1)/(B(1,1)*B(2,2)-B(1,2)^2));
    gamma = -B(1,2)*alpha^2*beta/lambda;
    u0 = gamma*v0/beta-B(1,3)*alpha^2/lambda;
    A = [alpha gamma u0;... %This matrix K in HZ
         0     beta  v0;...
         0     0     1];
    RT = cell(size(H));
    r = cell(size(H));
    
    %Create P and RT matrices for each view
    P = cell(size(H));
    for ii = 1:numel(H)
        %Calculate new lambda for this homography
        lambda = 1/norm(inv(A)*H{ii}(:,2));
        %And use it to get initial rotation matrix for this homography
        r1 = lambda*inv(A)*H{ii}(:,1);
        r2 = lambda*inv(A)*H{ii}(:,2);
        r3 = cross(r1,r2);
        
        R = [r1 r2 r3];
        %Approximate best 3x3 rotation matrix (Zhang App C)
        %NOTE: After approximating R, projection matrix does no longer
        %      project [X Y Z 1]' points to [u v 1]'. You might
        %      want to comment next few line if you want to test projection.
        [U S V] = svd(R);
        R = U*V';
        
        t = lambda*inv(A)*H{ii}(:,3); %TODO: is this lambda the "new" one or the "old" one?
        RT{ii} = [R t];
        
        %Rotational angles of R
        r{ii} = rodrigues(R);
        P{ii} = A*RT{ii};
        P{ii} = P{ii}./P{ii}(end);
    end
    
    %Nonlinear refinement
    r = [0 0];
    t = [0 0];
    params = [A(1,1) A(2,2) A(1,2) A(1,3) A(2,3) r t]';
    for ii = 1:numel(RT)
        ang = rodrigues(RT{ii}(1:3,1:3));
        t_vec = RT{ii}(:,4);
        params = [params; ang(:);t_vec(:)];
    end
    params = lsqnonlin(@(p)P_Z_nonlin_fun(X,x,p),params(:),[],[],optimset('TolX',1e-10,'TolFun',1e-10,'Algorithm','levenberg-marquardt','Display','iter','MaxIter',20));
    A(1,1) = params(1);
    A(2,2) = params(2);
    A(1,2) = params(3);
    A(1,3) = params(4);
    A(2,3) = params(5);
    r = params(6:7);
    t = params(8:9);
    params = params(10:end);
    for ii = 1:numel(RT)
       vecparam = params(1:6);
       RT{ii} = [rodrigues(vecparam(1:3)) vecparam(4:end)];
       %P{ii} = A*RT{ii}; %Original P
       P{ii} = RT{ii}; %P which has only R and T
       params = params(7:end);
    end
    K = A; %K is A
elseif method == 6
    %HZ Example 8.18 p.211 A simple calibration device (Planar)
    if ~iscell(x1)
       error('xy1 and xy2 must be cells') 
    end
    
    %(i)
    H = planarHomographys(X,x);
    
    %(ii), (iii) and (iv)
    K = makeKfromH(H);
    P = {}; %TODO: calculate all P
    return
end

if normalization
    %P = T2\[P;[0 0 0 1]]'*T1;
    %P = P(1:3,:);
    if iscell(P)
       for ii = 1:numel(P)
           P{ii} = T2{ii}(1:3,1:3)\P{ii}*T1{ii};
       end
    else
        P = T2(1:3,1:3)\P*T1;
    end
end
return

function out = P_HZ_nonlin_fun(x1,x2,p)
P = zeros(3,4);
P(:) = p(1:12);
P = P./P(end);
out = x2-wnorm(P*x1);
out = sum(out.^2,1);
return

function out = P_Z_nonlin_fun(x1,x2,p)
%For Zhang
RT = zeros(3,4);
K = eye(3);
out = [];
nump = 6;
%Get camera matrix parameters
K(1,1) = p(1); 
K(2,2) = p(2);
K(1,2) = p(3); %Should be set to 0 if no skew
K(1,3) = p(4);
K(2,3) = p(5);
r = p(6:7);
t = p(8:9);
%Get camera matrices
for ii = 1:numel(x1)
    vecparam = p(9+(ii-1)*nump+1:9+(ii-1)*nump+nump);
    RT = [rodrigues(vecparam(1:3)) vecparam(4:end)];
%     K(1,1) = p((ii-1)*nump+12-1+1);
%     K(2,2) = p((ii-1)*nump+12-1+2);
%     K(1,2) = p((ii-1)*nump+12-1+3);
%     K(1,3) = p((ii-1)*nump+12-1+4);
%     K(2,3) = p((ii-1)*nump+12-1+5);
    %tmp = x2{ii}-wnorm(P*x1{ii});
    %out = [out sum(tmp.^2,1)];
    [erx ery] = calculatePKdist(x2{ii},x1{ii},RT,K,r,t);
    out = [out;erx';ery'];
end
out = out';
return

function [H x1] = planarHomographys(x1,x2)
H = cell(1,numel(x1));
for ii = 1:numel(x1)
    %Calculate homographys and make sure points x1 and x2 are in
    %correct form
    if size(x1{ii},1) == 4
        %If world points are 3D points
        if numel(unique(x1{ii}(3,:))) ~= 1 %If there is some Z variations
            error('This method requires planar objects')
        end
        H{ii} = makeH(x1{ii}([1 2 4],:),x2{ii});
    else
        %x1s are 2D points
        H{ii} = makeH(x1{ii},x2{ii});
        if nargout > 1
            %This minimzation function requires he point to be 3D, this
            %conversion is easy
            x1{ii} = [x1{ii}(1:2,:); zeros(1,size(x1{ii},2));x1{ii}(3,:)];
        end
    end
    H{ii} = H{ii}./H{ii}(end);
end
return

%Test for radial distortion, not working
%  function out = P_HZ_nonlin_fun(x1,x2,p)
%  P = zeros(3,4);
%  P(:) = p(1:12);
%  P = P./P(end);
%  plotp(undistort(p(13:14),x2,p(end-1:end)))
%  disp(p(13:end))
%  drawnow
%  pause(0.1)
%  out = undistort(p(13:14),x2,p(end-1:end))-wnorm(P*x1);
%  out = sqrt(sum(out.^2,1));


