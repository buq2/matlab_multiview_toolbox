function [H X] = makeHrectangle(x,K,s_or_shape)
%Calculates homography when we know that projected object is rectangle.
%
%Works for papers and playing cards for example.
%
%Inputs:
%      x          - Image coordinates
%      K          - Calibration matrix
%      s_or_shape - Known aspect ratio, if functions finds that 
%                    calculated aspect ratio is closer to 1/s_or_shape
%                    this will be used instead. Can also be
%                    character array, in which case output X and H
%                    will be correctly scaled for this shape.
%
%Outputs:
%      H          - Estimated homography
%      X          - Estimated world points (H = makeH(x,X))
%
%Known shapes:
% 'a4' - 210 × 297mm
% 'bridgecard' - 56 x 88 mm
% 'pokercard' - 63 x 88 mm
% 'customcard' - 58 x 88 mm ("Playing card")
%
%Gilles Simon, Andrew W. Fitzgibbon and Andrew Zisserman - 
%  Markerless Tracking using Planar Structures in the Scene
%
%Matti Jukola 2011.02.02

force_s = false;
if nargin > 2
    force_s = true;
    s_siz = 1;
    if ischar(s_or_shape)
        name_list = {'a4';
                     'bridgecard';
                     'pokercard';
                     'customcard'};
        s_list = [210/297;
                  56/88;
                  63/88;
                  58/88]; %x/y
        siz_list = [0.210;
                    0.056;
                    0.063;
                    0.058]; %[m] Scale of X axis
        
        idx = strcmpi(name_list,s_or_shape);
        s_or_shape = s_list(idx);
        s_siz = siz_list(idx);
    end
end

%Assume square
X = [0 0 1 1;
     0 1 1 0;
     1 1 1 1];

%Calculate homography
H = makeH(X,x);

A = inv(K)*H;
%Estimated aspect ratio
s = norm(A(:,1))./norm(A(:,2));

if force_s
    s_tst = abs(([s 1/s]-s_or_shape)/s_or_shape);
    if s_tst(2) < s_tst(1)
        s = 1/s_or_shape;
        s_siz = s_siz*1/s_or_shape;
    else
        s = s_or_shape;
    end
end

D_inv = [1 0 0;
         0 1/s 0;
         0 0 1];
H = H*D_inv;
X = D_inv*X;

if force_s
    %World coordinates to correct scale
    siz = [s_siz  0     0;
        0      s_siz 0;
        0      0     1];
    X = siz*X;
    H = H*inv(siz);
end
