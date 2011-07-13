function [P2 P2bestGuess] = makePfromE(E,x1_or_X,x2,K1,K2)
%Calculates second camera matrix P2 from essential Matrix E
%
%Inputs: 
%       E       - Essential matrix
%       x1_or_X - Either 2D point (3xn) or 3D point (4xn). If not provided,
%                 function will return P2s in cell array. If provided,
%                 function will test if X is in front of both of the cameras 
%                 (canonical and computed) and will only return camera which 
%                 fullfills this requirement.
%       x2      - Second point corresponding P2 and x1. Should be given only if
%                 x1_or_X is 2D point
%       K       - Calibration matrix K, needed when x1_or_X and/or x2 is provided.
%
%Outputs:
%       P2          - Cell array of 4 camera matrices or 3x4 camera matrix 
%                      (if no suitable found).
%       P2bestGuess - Best guess which is the correct camera matrix. Always
%                      3x4 camera matrix.
%When P2 is cell array which contains four possible camera matrices for E:
%See HZ2 Fig. 9.12 for good illustration for difference between P2s
%
%HZ2 9.6.2, Result 9.19 pp.258-259
%
%Matti Jukola 2010.12.24, 2010.01.23, 2010.01.24

if nargin < 5
    K2 = K1;
end

W = [0 -1  0;
     1  0  0;
     0  0  1];
[U S V] = svd(E);
S(end) = 0;
E = U*S*V';
[U S V] = svd(E);

P2 = cell(4,1);
P2{1} = [U*W*V' U(:,3)];
P2{2} = [U*W*V' -U(:,3)];
P2{3} = [U*W'*V' U(:,3)];
P2{4} = [U*W'*V' -U(:,3)];

if nargout > 1
    P2bestGuess = [];
    best = Inf;
    calBest = true;
else
    calBest = false;
end

if nargin > 1
   %Check if for one of the camera point X is in front of both cameras
   P1 = K1*[eye(3) zeros(3,1)];
   for ii = 1:numel(P2)
       if size(x1_or_X,1) == 3 %2D point, we must triangulate first
           X = triangulateP({P1 K2*P2{ii}},{x1_or_X,x2});
       else
           X = x1_or_X;
       end
       
       %Not very efficient if x1_or_X is 3D point, depth1 should only be
       %calculated once, but this simplifies this function a little bit.
       depth = calculateXDepth(P1,X);
       if any(depth < 0) && ~calBest
           %At least one point behind the camera
           continue
       elseif calBest
           numBehind = sum(depth < 0);
       end
       
       depth = calculateXDepth(K2*P2{ii},X);
       if all(depth >= 0) && (~calBest || numBehind == 0)
           %All points are in front of both of the cameras -> Return this P2
           %camera
           P2 = P2{ii};
           P2bestGuess = P2;
           return
       elseif calBest
           numBehind = numBehind + sum(depth < 0);
           if numBehind < best
              best = numBehind;
              P2bestGuess = P2{ii};
           end
       end
   end
end
