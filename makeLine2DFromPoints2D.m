function l = makeLine2DFromPoints2D(x1,x2)
%Computes 2D line l = [a b c]', a*x+b*y+c = 0 from point pair 
%x1 ([x1_1 y1_1;x1_2 y1_2;...]') 2xn or 3xn
%x2 ([x2_1 y2_1;x2_2 y2_2;...]') 2xn or 3xn
%
%Points in x1 and x2 can be either homogenous or only xy pairs
%
%HZ2 p.28
%
%Matti Jukola 2010

%xy pairs must be column vectors
if numel(x1) == 2
    x1 = x1(:);
end
if numel(x2) == 2
    x2 = x2(:);
end

l = zeros(3,size(x1,2));
if size(x1,1) == 3
    x1 = wnorm(x1);
    x2 = wnorm(x2);
end
for ii = 1:size(l,2)
    l(:,ii) = cross([x1(1:2,ii); 1],[x2(1:2,ii); 1]);
end
