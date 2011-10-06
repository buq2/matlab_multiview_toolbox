function [T1,T2,P1_,P2_] = rectifyP(P1,P2)
%Compute rectifying homographys from two camera matrices
%P1 and P2 where P1 = K*[R1 T1] and P2 = K*[R2 T2]
%
%Inputs:
%      P1 and P2 - Camera matrices with form P = K*[R T]
%
%Outputs:
%      T1  - Rectifying transformation for image1 created by camera P1
%      T2  - Rectifying transformation for image2
%      P1_ - 
%
%References:
%Andrea Fusiello - Epipolar Rectification, 2000
%
%Based heavily on code from Andrea Fusiello which can be acquired from:
%http://profs.sci.univr.it/~fusiello/rectif_cvol/node5.html
  
% factorize old PPMs
[K1,R1,T1] = decomposeP(P1);
[K2,R2,T2] = decomposeP(P2);
  
% optical centers (unchanged)
c1 = - inv(P1(:,1:3))*P1(:,4);
c2 = - inv(P2(:,1:3))*P2(:,4);
  
% new x axis (= direction of the baseline)
v1 = (c1-c2);
% new y axes (orthogonal to new x and old z)
v2 = cross(R1(3,:)',v1);
% new z axes (orthogonal to baseline and y)
v3 = cross(v1,v2);
  
% new extrinsic parameters 
%We have two options for rotations, one of these will result images which
%are rotated ~90 degrees. Try to choose one which rotates the cameras the
%least. (This is experimental)
R_tst1 = [v1'/norm(v1)
          v2'/norm(v2)
          v3'/norm(v3)];
R_tst2 = [R_tst1(2,:)
          R_tst1(1,:)
          R_tst1(3,:)];
      
ang1 = rodrigues(R_tst1);
ang2 = rodrigues(R_tst2);
ang0 = rodrigues(R1);
ang1 = ang1./norm(ang1);
ang2 = ang2./norm(ang2);
ang0 = ang0./norm(ang0);
if dot(ang0,ang1) > dot(ang0,ang2)
    R = R_tst1;
else
    R = R_tst2;
end
% translation is left unchanged
  
% new intrinsic parameters (arbitrary) 
A = (K1 + K2)./2;
A(1,2)=0; % no skew
  
% new projection matrices
P1_ = A * [R -R*c1 ];
P2_ = A * [R -R*c2 ];
  
% rectifying image transformation
T1 = P1_(1:3,1:3)*inv(P1(1:3,1:3));
T2 = P2_(1:3,1:3)*inv(P2(1:3,1:3));