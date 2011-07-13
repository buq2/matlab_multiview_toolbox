function d = calculateTdist(T,x1,x2,x3,method)
%Calculates distance measure (fittness measure) for trifocal tensor T
%and point correspondaces x1, x2 and x3
%
%Matti Jukola 2010.12.21

if nargin < 5
    method = 'reprojection';
end

if strcmpi(method,'reprojection')
    %HZ2 16.6 p.401
    x1 = wnorm(x1);
    x2 = wnorm(x2);
    x3 = wnorm(x3);
    
    P1 = [eye(3) zeros(3,1)];
    [P2 P3] = makePfromT(T);
    X = triangulateP({P1,P2,P3},{x1,x2,x3});
    
    x1_ = wnorm(P1*X);
    x2_ = wnorm(P2*X);
    x3_ = wnorm(P3*X);    
    
    d = (x1_(1:2,:)-x1(1:2,:)).^2+(x2_(1:2,:)-x2(1:2,:)).^2+(x3_(1:2,:)-x3(1:2,:)).^2;
    d = sum(d,1)';
elseif strcmpi(method,'sampson')
    %HZ2 (16.4) p.399
    error('Not implemented')
else
    error('Unknown method')
end