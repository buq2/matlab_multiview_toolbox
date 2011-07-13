function [H H_] = rectify(x1,x2,rigidPoint)
%Rectifying transform for two image with point correspondance 'x1' and 'x2'
%
%Inputs:
%      x1         - Points from first image
%      x2         - Points from second image
%      rigidPoint - (optionel) 2D homogenous coordinate point for rigid point. Usually
%                   should be chosen to be image center. If not given,
%                   point [0 0 1] will be used.
%
%1) Faugeras & Luong. The Geometry of Multiple Images. p. 372-376
%Hartley & Zisserman Multiple view geometry. p. 304-307
%
%Matti Jukola 2010, 2011.01.30

if nargin < 3
    rigidPoint = [0 0 1]';
else
    rigidPoint = wnorm(rigidPoint);
end

method = 1;

if method == 1
    %HZ2 11.12 Image rectification pp. 304-307
    %
    %Rigid transformation around interest point
    
    %Transform interest point to origin
    T = [1 0 -rigidPoint(1);
         0 1 -rigidPoint(2);
         0 0  1];
    
    %Calculate fundamental matrix
    F = makeF(x1,x2);
    
    %Calculate epipole (left epipole e_)
    %e_ = wnorm(makeEpipoles(F')); %Transpose of F -> left epipole. F'*e_ = 0
    e_ = (makeEpipoles(F')); %Transpose of F -> left epipole. F'*e_ = 0
    e_trans = T*e_;
    
    %Calculate how much epipole should be rotated to get it to x-axis
    theta = atan2(e_trans(2)/e_trans(3), e_trans(1)/e_trans(3));
    
    %atan2 gets values from -pi to pi, we should see which main axis is
    %closest to current epipole. -pi and pi are same axis.
    angles = -pi:pi/2:pi;
    
    %Calculate closest axis (and direction, -Inf or Inf)
    delta = angles - theta;
    [tmp,idx] = min(abs(delta));
    
    %From which we get desider angle
    ang = delta(idx);
    
    %And we can then calculate correct rotation matrix
    R = [cos(ang) -sin(ang) 0;
        sin(ang)  cos(ang) 0;
        0           0      1];
    
    %Now we can transform epipole to x-axis
    e_trans = wnorm(R*e_trans);
    
    
    %And now we can calculate transformation which brings the epipole to 
    %infinity
    G = [1             0 0; 
         0             1 0; 
         -1/e_trans(1) 0 1];
    
    %Finally transformation is combinations of these three transformations
    H_ = G*R*T;
    
    %e_trans = H_*e_;
    %H_ = H_./e_trans(1);

    %Now we need projective transformation which for which 
    %Distance between points H*x1, H0*x2 is minimal where H is HA*H0
    %HA is affine transform and H0 is H_*M where M is rotation matrix
    %from second camera of canonical camera pair
    
    %Calculate camera matrix P2
    P2 = makePfromF(F);
    M = P2(:,1:3);
    
    %Make sure M is not singular
    %Note that if values in P2 (M) are not close to one, this might cause 
    %problems. This normalization is done in makePfromF.
    if det(M) < 1e-3
       M = M+e_*rand(1,3);
    end
    
    %Calculate H0
    H0 = H_*M;

    
    %Minimize HA*H0x1-H_*x2
    x1 = wnorm(H0*x1);
    x2 = wnorm(H_*x2);
    abc = [x1(1:2,:)' ones(size(x1,2),1)]\x2(1,:)';
    HA = [abc';0 1 0;0 0 1];
    
    H = HA*H0;
end
