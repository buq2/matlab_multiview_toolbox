function d = calculateLinedist(l,x1,calc_wnorm)
%Calculates 2D points (x1, homogenous coordinates) euclidean distance to 
%line l (a*x+b*y+c*w = 0)
%
%Inputs:
%      l          - line, 3x1 vector [a;b;c] a*x+b*y+c*w = 0
%      x1         - 2D homogenous points 3xn matrix
%      calc_wnorm - If true, x1 = wnorm(x1); is calculated. Default true
%
%Outpus:
%      d          - Euclidean distance to line with sign
%
%Matti Jukola 2011.02.02

if nargin < 3 || calc_wnorm
    x1 = wnorm(x1);
end
div = norm(l(1:2));
l = l./div;

d = sum(bsxfun(@times,x1(1:2,:),l(1:2)))+l(3);