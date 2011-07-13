function [c C] = makeConic(x)
%Fits conic C = [a   b/2 d/2;
%                b/2 c   e/2
%                d/2 e/2 f];
%Where a*xi^2+ b*xi*yi + c*yi^2 + d*xi + e*yi + f = 0
%
%Inputs:
%      x - 2D Homogenous points which are on the conic
%
%Outputs:
%      c - Conic in vector form c = [a b c d e f]
%      C - Conic in matrix form as above
%
%
%HZ2 p. 31
%
%Matti Jukola 2011.06.12

%Normalize w=1
x = wnorm(x);

%For clearer code
X = x(1,:)';
Y = x(2,:)';

%Form constraints
A = [X.^2 X.*Y Y.^2 X Y ones(numel(X),1)];

%Linear solution
[U S V] = svd(A);
c = V(:,end); %Conic in vector form

%Conic in matrix form
a_ = c(1);
b_ = c(2);
c_ = c(3);
d_ = c(4);
e_ = c(5);
f_ = c(6);

C = [a_   b_/2 d_/2;
     b_/2 c_   e_/2
     d_/2 e_/2 f_];