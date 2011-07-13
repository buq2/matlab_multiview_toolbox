%% Creates example H (Example 5.20) from MASKS p. 138
ang = pi/10;
R = [cos(ang) 0 sin(ang); 0 1 0;-sin(ang) 0 cos(ang)];
T = [2 0 0]';
N = [1 0 2]';
d = 5;
lambda = 4;

Hl = lambda*(R+1/d*T*N');

%Decomposition
[R_ T_ N_] = makeHdecomposition(Hl)

%%
X = makeCube3D();
X(2,:) = X(2,:)*1200;
X(1,:) = X(1,:)*1100;
X(3,:) = X(3,:)*1150;

k = zeros(3);
k(1,1) = kk.fc(1);
k(2,2) = kk.fc(2);
k(1,2) = kk.alpha_c;
k(1:2,3) = kk.cc';
k(end) = 1;


iii = 2;
RT = [R_{iii} T_{iii}];
P = [k*RT; 0 0 0 1];
x = (P*X);
plotp(x,false,'r-')
%%











