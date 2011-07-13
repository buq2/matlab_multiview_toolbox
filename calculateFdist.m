function d = calculateFdist(F,x1,x2,method)
%Calculates how well fundamental fits to point correspondances
%
%Matti Jukola
%2010.12.15
%
%As in HZ 11.6 (ii)

if nargin < 4
    method = 'reprojection';
end

if strcmpi(method,'sampson')
    %HZ2 (11.9) p.287 (used)
    %MASKS (6.83) p.214 (reference)
    %Output d will be in Sampson's distance
    
    top = sum(bsxfun(@times,x2'*F,x1'),2);%For each point: x2'*F*x1;
    bottom_1 = F*x1;
    bottom_2 = F'*x2;
    bottom = sum(bottom_1(1:2,:).^2+bottom_2(1:2,:).^2,1);
    d = top.^2./bottom';
elseif strcmpi(method,'reprojection')
    %HZ2 12.5 and (11.6) (used) altough triangulateP uses only linear triangulation
    %MASKS (6.81) p.214 (reference)
    %Output will be in pixels^2
    x1 = wnorm(x1);
    x2 = wnorm(x2);
    P1 = [eye(3) zeros(3,1)];
    P2 = makePfromF(F);
    X = triangulateP({P1 P2},{x1 x2});
    %Reproject
    x1_ = wnorm(P1*X);
    x2_ = wnorm(P2*X);
    d = (x1_(1:2,:)-x1(1:2,:)).^2+(x2_(1:2,:)-x2(1:2,:)).^2;
    d = sum(d,1)';
else
    error('Unknwon method')
end

%Defective method
%d = sum(bsxfun(@times,x2'*F,x1'),2);%For each point: x2'*F*x1;