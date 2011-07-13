function H = makeH3d(X1,X2)
%Computes 3D-3D homography H such that X2 = H*X1 where X1 are original
%projectively reconstructed world points and X2 are either metric
%reconstructed points or control points used in computing H.
%
%Input arguments X and Xe must have at least 5 suitable points.
%
%Matti Jukola 2010
%
%HZ 10.5 p.275

%Answer calculated using DLT algorithm. DLT matrix 'solved' using:
% dim = 3;
% h = ones(dim+1);
% h(logical(triu(ones(dim+1)))) = -1;
% h(1:dim+2:end) = 0;
% H = sym(zeros(dim+1));
% for ii = 1:dim+1
%     for jj = 1:dim+1
%         syms(['H' num2str(ii) num2str(jj)])
%         H(ii,jj) = eval(['H' num2str(ii) num2str(jj)]);
%     end
% end
% x1 = sym(zeros(dim+1,1));
% x2 = sym(zeros(dim+1,1));
% for ii = 1:numel(x1)
%    syms(['x1_' num2str(ii)]) 
%    syms(['x2_' num2str(ii)])
%    x1(ii) = eval(['x1_' num2str(ii)]);
%    x2(ii) = eval(['x2_' num2str(ii)]);
% end
% 
% 
% a = H(1,:)*x2
% b = H(2,:)*x2
% c = H(3,:)*x2
% d = H(4,:)*x2
% 
% X1 = subs(a./d,x2_4,1) %=0
% Y1 = subs(b./d,x2_4,1) %=0
% Z1 = subs(c./d,x2_4,1) %=0

X1 = wnorm(X1);
X2 = wnorm(X2);

%Normalize points for stability (needed?)

A = zeros(size(X1,2)*3,16);
for ii = 1:size(X1,2)
    x1 = X1(1:4,ii)';
    x2 = X2(1:4,ii)';
    A((ii-1)*3+1:ii*3,:) = [-x1      0 0 0 0       0 0 0 0      x2(1).*x1;...
                            0 0 0 0  -x1           0 0 0 0      x2(2).*x1;...
                            0 0 0 0  0 0 0 0       -x1          x2(3).*x1];
end
[U S V] = svd(A,false);
H = reshape(V(:,end),[4 4])';