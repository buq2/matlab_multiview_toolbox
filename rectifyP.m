function [T1,T2,P1_,P2_] = rectifyP(P1,P2)
%Compute rectifying homographys from two camera matrices
%P1 and P2 where P1 = K*[R1 T1]=K*[R1 -R1*C1] and P2 = K*[R2 T2]
%
%Inputs:
%      P1 and P2 - Camera matrices with form P = K*[R T] = K*[R -R*C]
%
%Outputs:
%      T1  - Rectifying transformation for image1 created by camera P1
%      T2  - Rectifying transformation for image2
%      P1_ - 
%
%References:
%Andrea Fusiello - Epipolar Rectification, 2000
%
%Code from Andrea Fusiello. Original code can be acquired from:
%http://profs.sci.univr.it/~fusiello/rectif_cvol/node5.html
%
%Matti Jukola 2011.10.06
%
%See also: rectify (used when we only have point correspondances)
  
%Decompose camera matrix, we need the camera rotations and centers/optical centers
[K1,R1,C1] = decomposeP(P1);
[K2,R2,C2] = decomposeP(P2);

%We can not use homogenous presentation of camera center, so remove
%homogenous coordinate (constant 1)
C1 = C1(1:3);
C2 = C2(1:3);
  
%We want to find point correspondances from same row.
%This means that both cameras must have parallel X-axis.
%Make vector which is parallel to the base line and use it as a new X-axis
v1 = (C1-C2);

%New y axes can be created by taking _original_ Z-axis and
%calculating orthogonal vector to old Z-axis and new X-axis.
v2 = cross(R1(3,:)',v1);

%As R must be orthogonal, final axis can be calculated from the two new axis
v3 = cross(v1,v2);
  
%New extrinsic parameters 
R = [v1'/norm(v1)
     v2'/norm(v2)
     v3'/norm(v3)];
      
%New intrinsic parameters (arbitrary, can be freely selected) 
A = (K1 + K2)./2;
A(1,2)=0; % no skew
  
%New projection matrices. Do not change the optical centers.
P1_ = A * [R -R*C1 ];
P2_ = A * [R -R*C2 ];
  
%Rectifying image transformation
%First reproject 2D image points to world coordinates using original projection
%matrices, then project them back to new image plane using new camera
%matrices.
T1 = P1_(1:3,1:3)*inv(P1(1:3,1:3));
T2 = P2_(1:3,1:3)*inv(P2(1:3,1:3));