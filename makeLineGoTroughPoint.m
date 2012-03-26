function l2 = makeLineGoTroughPoint(l1,x1)
%Modifies line 'l1' such that it travels trough point x1 but does not
%modify lines angle, only modifies lines distance from origo.
%
%Inputs: 
%      l1  - Implicit lines 3xn array (l = [a b c]', a*x + b*y + c = 0)
%      x1 - Homogenous 2D points
%
%Outputs:
%      l2  - Modified input lines
%
%Matti Jukola: 2012-03-26

%1) Lines gradient is:
%l = [a b c]', ax + by + c = 0
%ax + c = -by
%-ax -c = by
%-ax/b -c/b = y (this is same form as in explicit line 'kx+b=y'
%So gradient is -ax/b, meaning that we can not modify -a/b

%2) Line must travel trough 'x1'. Meaning that for resulting line
% dot(x1,l) = 0

%x1(1)*l2(1) + x1(2)*l2(2) + l(3) = 0
%l2(1)/l2(1) = l1(1)/l1(2)
%We can choose l2(1) freely
%Lets use l2(1) = l1(1)
%Now
%x1(1)*l1(1) + x1(2)*l2(2) + l2(3) = 0
%l1(1)/l2(1) = l1(1)/l1(2)
%-> l2(2) = l1(2)
%
%Only unknwon is l2(3) which can be solved from  first eq
%l(3) = -(x1(1)*l1(1) + x1(2)*l1(2))

if size(l1,1) ~= 3
    error('This function expects line to be implicit and in 3xn matrix')
end
if size(x1,1) ~= 3
    error('This function expects points to be homogenous and in 3xn matrix')
end

if size(l1,2) == size(x1,2) || size(x1,2) == 1
    %Input arrays same size, or oly single point
    l2 = l1;
elseif size(l1,2) == 1
    %Single line, multiple points
    l2 = zeros(size(x1));
    l2(1,:) = l1(1);
    l2(2,:) = l1(2);
else
    error('Input dimensions dismatch')
end
l2(3,:) = -(x1(1,:).*l2(1,:) + x1(2,:).*l2(2,:));




