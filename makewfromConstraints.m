function w = makewfromConstraints(v1_v2, l_v, H_h1_h2, zero_skew, square_pixels)
%General image of absolute (w) computation from different constraints
%
%Inputs:
%      v1_v2         -  Vanishing points v1 and v2 corresponding to orhogonal
%                       lines. Cell array of 3x2 matrices [v1 v2]
%      l_v           -  Vanishing point v and vanishing line l corresponding to
%                       orthogonal line and plane. Cell array of 3x2 matrices [l v]
%      H_h1_h2       -  Metric plane imaged with known homography H = [h1 h2 h3].
%                       Cell array of 3x3 matrices H or 3x2 matrices [h1 h2]. 
%                       Different matrices can be mixed
%      zero_skew     -  Calibration matrix K has no skew. True/false
%      square_pixels -  Pixels in camera are square. True/false
%
%Matti Jukola 2010.12.22
%
%HZ Table 8.1 p.224
%HZ Algorithm 8.2 p.225 Computing K from scene and internal constraints

if nargin < 2;l_v = [];end
if nargin < 3;H_h1_h2 = [];end
if nargin < 4;zero_skew = false;end
if nargin < 5;square_pixels = false;end

min_constraints = 5;
num_constraints = numel(v1_v2)+numel(l_v)*2+numel(H_h1_h2)*2+max(zero_skew+square_pixels*2);

%if num_constraints < min_constraints
%   error('Too few constraints') 
%end

A = zeros(numel(v1_v2)+numel(l_v)*3+numel(H_h1_h2)*2,6);

num = 1;
for ii = 1:numel(v1_v2)
    %HZ Algorithm 8.2 (ii) p.225
    v = v1_v2{ii}(:,1);
    u = v1_v2{ii}(:,2);
    A(num,:) = [v(1)*u(1) (v(1)*u(2)+v(2)*u(1)) v(2)*u(2) (v(1)*u(3)+v(3)*u(1)) (v(2)*u(3)+v(3)*u(2)) v(3)*u(3)];    
    num = num+1;
end

for ii = 1:numel(l_v)  
    l = l_v{ii}(:,1);
    v = l_v{ii}(:,2);
    %Computed using code:
    %syms l1 l2 l3 v1 v2 v3 w1 w2 w3 w4 w5 w6
    %l = [l1 l2 l3].';
    %v = [v1 v2 v3].';
    %w = [w1 w2 w4;w2 w3 w5;w4 w5 w6];
    %collect(makeSkew(l)*w*v,[w1 w2 w3 w4 w5 w6])
    %
    %Gives:    
    %-l3*v1*w2 -l3*v2*w3 +l2*v1*w4 +w5*(l2*v2 - l3*v3) +l2*v3*w6 = 0
    A(num,:) = [0 -l(3)*v(1) -l(3)*v(2) l(2)*v(1) (l(2)*v(2)-l(3)*v(3)) l(2)*v(3)];
    num = num+1;
    %l3*v1*w1 +l3*v2*w2 -w4*(l1*v1 - l3*v3) -l1*v2*w5 -l1*v3*w6 = 0
    A(num,:) = [l(3)*v(1) l(3)*v(2) 0 -(l(1)*v(1)-l(3)*v(3)) -l(1)*v(2) -l(1)*v(3)];
    num = num+1;
    %-l2*v1*w1 w2*(l1*v1 - l2*v2)  +l1*v2*w3 -l2*v3*w4 +l1*v3*w5 = 0
    A(num,:) = [-l(2)*v(1) (l(1)*v(1)-l(2)*v(2)) l(1)*v(2) -l(2)*v(3) l(1)*v(3) 0];
    num = num+1;    
end

for ii = 1:numel(H_h1_h2)
    %Ma et. al - An Invitation to 3-D Vision pp. 203-204
    %HZ Example 8.18 p.211
    %HZ Table 8.1 p.224
    %HZ Algorithm 8.2 p.225
    h1 = H_h1_h2{ii}(:,1); %First column
    h2 = H_h1_h2{ii}(:,2);
    %First homography costraint (h1.'*w*h2 = 0)
    A(num,:) = [h1(1)*h2(1) (h1(1)*h2(2) + h2(1)*h1(2)) h1(2)*h2(2) (h1(1)*h2(3) + h2(1)*h1(3)) (h1(2)*h2(3) + h2(2)*h1(3)) h1(3)*h2(3)];
    num = num+1;
    %Second homography constraint (h1.'*w*h1 - h2.'*w*h2 = 0)
    A(num,:) = [(h1(1)^2 - h2(1)^2) (2*h1(1)*h1(2) - 2*h2(1)*h2(2)) (h1(2)^2 - h2(2)^2) (2*h1(1)*h1(3) - 2*h2(1)*h2(3)) (2*h1(2)*h1(3) - 2*h2(2)*h2(3)) (h1(3)^2 - h2(3)^2)];
    num = num+1;
end

if zero_skew && ~square_pixels
    %w12 = w21 = 0
    %Remove second column as it will be multiplied with zero
    A(:,2) = [];
end

if square_pixels
    %w12 = w21 = 0
    %Remove second column as it is 0
    A(:,2) = [];
    %w11 = w22
    %Sum first and third (now second) column as w11 = w22 and we can combine
    %w1*x+w2*y = w1_w2*(x+y)
    A(:,1) = A(:,1)+A(:,2);
    A(:,2) = [];
end

%Now we can solve this linear equation using SVD
%A*w = 0
[U S V] = svd(A);
w = V(:,end);
%Construct w using knowledge of A
if ~zero_skew && ~square_pixels
    w = [w(1) w(2) w(4);
         w(2) w(3) w(5);
         w(4) w(5) w(6)];
elseif zero_skew
    w = [w(1)  0   w(3);
         0    w(2) w(4);
         w(3) w(4) w(5)];
elseif square_pixels
    w = [w(1)  0   w(2);
         0    w(1) w(3);
         w(2) w(3) w(4)];
end
