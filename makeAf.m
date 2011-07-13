function A = makeAf(x1,x2)
%Creates matrix A which is used when calculating fundamental matrix
%x1 = x
%x2 = x'
%
%Matti Jukola 2010
%
%HZ2 (11.3) p.279
A = zeros(size(x1,2),9);
A(:,1) = (x2(1,:).*x1(1,:))'; %x'x
A(:,2) = (x2(1,:).*x1(2,:))'; %x'y
A(:,3) = x2(1,:)';            %x'
A(:,4) = (x2(2,:).*x1(1,:))'; %y'x
A(:,5) = (x2(2,:).*x1(2,:))'; %y'y
A(:,6) = x2(2,:)';            %y'
A(:,7) = x1(1,:)';            %x
A(:,8) = x1(2,:)';            %y
A(:,9) = 1;                   %1
