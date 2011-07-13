function P = makeP3d(X,x,method,normalization)
%Creates camera matrix P from 3D points X and 2D image correspondances
%x. Minimum of 5½ correspondances are needed, use NaN for missing ½.
%Following outline of HZ. p. 181 Algorithm 7.1

if nargin < 3
    %Normalization should always be used. This input arguments is only for
    %those who want to easily test what happens if normalization is not used.
    normalization = true;
end

if normalization
    [x TT] = normalizePoints(x);
    [X TU] = normalizePoints(X);
end

%DLT algorithm
P = zeros(3,4);
A = makeA(X,x);
[U,S,V] = svd(A,false);
P(:) = reshape(V(:,end),4,3)';

if normalization
   P = inv(TT)*P*TU; 
end

P = P./P(end);
