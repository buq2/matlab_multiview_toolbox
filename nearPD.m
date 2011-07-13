function X = nearPD(x)
%Compute the nearest positive definite matrix to an approximate one, typically a correlation or variance-covariance matrix.
%Matrix must be symmetric
%
%Original algorithm R implementation: Jens Oehlschlaegel,Douglas Bates and Martin, Maechler
%
%Matti Jukola 2010.11.13

error('Not working / finished')

maxit = 100;
conv_tol = 1e-07;
posd_tol = 1e-08;
eig_tol = 1e-06;
n = size(x,2);
U = zeros(size(x));
X = x;
iter = 0;
converged = false;
while (iter < maxit && ~converged)
    Y = X;
    T = Y - U;
    
    [Q d] = eig(Y);
    d = diag(d);
    
    p = d > eig_tol * d(1);
    Q = Q(:,p); %Drop columns where d <= eig_tol*d(1)
    X = bsxfun(@times,Q,d(p)')*Q.';
    U = X - T;
    X = (X + X.')/2;
    
    conv = norm(Y - X, inf)/norm(Y, inf);
    iter = iter + 1;
    
    converged = conv <= conv_tol;
end
if (~converged)
    warning('nearPD did not converge')
end

[Q d] = eig(X);
d = diag(d);

Eps = posd_tol * abs(d(1));
if (d(n) < Eps)
    d(d < Eps) = Eps;
    o_diag = diag(X);
    X = Q *(d * Q.');
    D = sqrt(max(Eps, o_diag)./diag(X));
    X(:) = bsxfun(@times,D * X,D);
end
disp(X)