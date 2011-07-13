function drawQuadric(x,y,d)
%HZ2 3.2.3, (3.15) p.73
%Not very well tested
%Matti Jukola 2010
z = (sqrt((-d(1).*x.^2-d(2).*y.^2-d(4))./d(3)));
surf(x,y,z);