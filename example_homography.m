syms x y w H11 H12 H21 H22
syms H13 H23 H31 H32 H33
x2d = [x;y];
H2d = [H11 H12;H21 H22];

trans = H2d*x2d;

x_ = [x*w;y*w;w];
H = [H11 H12 H13;H21 H22 H23;H31 H32 H33];
trans = H*x_
simple(trans./trans(3))

%%
x = [1; 0; 1];
R = @(a)[cos(a) -sin(a) 0;sin(a) cos(a) 0;0 0 1];
k = 0.81409;
xx = wnorm(R(k)*x);
plot([0 xx(1)],[0 xx(2)],'r')
axis([-1 1 -1 1])
%%
syms w w_ x x_ y y_
syms h11 h12 h13 h21 h22 h23 h31 h32 h33
X = [x;y;w];
X_ = [x_;y_;w_];
h1 = [h11 h12 h13];
h2 = [h21 h22 h23];
h3 = [h31 h32 h33];
H = [h1;h2;h3];
makeSkew(X_)*H*X
collect(makeSkew(X_)*H*X,[h11 h12 h13 h21 h22 h23 h31 h32 h33])
%%
syms h1 h2 h3
H = [h1;h2;h3];
makeSkew(X_)*(H.'*X).'