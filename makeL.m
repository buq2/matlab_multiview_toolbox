function L = makeL(X,x)
%Makes L matrix as seen in:
%J. Heikkila, O.Silvén
%A Four-step Camera Calibration Procedure with Implicit Image Correction
%p. 4
%
%Inputs:
%      X   - [X1 Y1 Z1 W1; X2 Y2 Z2 W2;...]' (real world coordinates)
%      x   - [x1 y1 w1; x2 y2 w2;...]' (image coordinates)
%
%Outputs:
%      L   - DLT matrix as seen in Heikkila, O.Silvén
%
%Matti Jukola 2010
X = wnorm(X);
x = wnorm(x);
L = zeros(size(x,2)*2,12);
nump = size(x,2);
L(1:2:end,:) = [X' zeros(nump,4) bsxfun(@times,-X',x(1,:)')];
L(2:2:end,:) = [zeros(nump,4) X' bsxfun(@times,-X',x(2,:)')];