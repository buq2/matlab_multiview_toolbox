function X = makeCube3D()
%Creates cube (min(X(ii,:)) == 0, max(X(ii,:)) == 1 for ii = 1:3)
X = [0 0 1 1 0 0 0 1 1 0;
     0 1 1 0 0 0 1 1 0 0;
     0 0 0 0 0 1 1 1 1 1;
     1 1 1 1 1 1 1 1 1 1];