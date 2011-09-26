%From
%Liebowitz & Zisserman - Combining Scene and Auto-calibration Constraints
syms w1 w2 w3 w4 w5 w6
syms v1 v2 v3 u1 u2 u3
syms f k u0 v0 rf
syms h11 h12 h21 h22 h31 h32 %Homography 3x3 matrix frist two columns

%Internal parameters
K = [f k  u0;
     0 rf v0;
     0 0   1];

%First two columns from homography matrix (3x3)
h1 = [h11 h21 h31].';
h2 = [h12 h22 h32].'; 
 
%Absolute conic
w = [w1 w2 w4;
     w2 w3 w5;
     w4 w5 w6];

%Vanishing points v1_ v2_ (there is also third one v3_, but all
%formulas use only two at the most)
v1_ = [v1 v2 v3].';
v2_ = [u1 u2 u3].';

%Orthogonality constraint for three vanishing points v1_, v2_, v3_
%v1_.'*w*v2_ = v1_.'*w*v3_ = v2_.'*w*v3 = 0 (Formula (6))
constraint_orthogonality = v1_.'*w*v2_;
constraint_orthogonality = collect(constraint_orthogonality,[w1 w2 w3 w4 w5 w6]);

%Homography constraints
constraint_homography1 = h1.'*w*h2; %=0
constraint_homography1 = collect(constraint_homography1,[w1 w2 w3 w4 w5 w6]);
constraint_homography2 = h1.'*w*h1-h2.'*w*h2;
constraint_homography2 = collect(constraint_homography2,[w1 w2 w3 w4 w5 w6]);

str = char(constraint_homography2);
for ii = 1:numel(h1)
    str = strrep(str,char(h1(ii)),['h1(' num2str(ii) ')']);
    str = strrep(str,char(h2(ii)),['h2(' num2str(ii) ')']);
end
%% Using planar homographies
img = imread('imgs_proprietary/test_image1.jpg');
load imgs_proprietary/test_image1.jpg.mat
X = [0 1 1; 1 1 1;1 0 1; 0 0 1]';

figure(1)
imagesc(img)
hold on
plot(corner_points(1,1:4),corner_points(2,1:4))
plot(corner_points(1,5:8),corner_points(2,5:8))
plot(corner_points(1,9:12),corner_points(2,9:12))
hold off

figure(2)
plot(X(1,:),X(2,:))

H1 = makeH(X,corner_points(:,1:4));
H2 = makeH(X,corner_points(:,5:8));
H3 = makeH(X,corner_points(:,9:12));

[K w] = makeKfromH({H1,H2,H3})

K_shuld_be = [1108.3 -9.8 525; %Something like this
              0      1097.8 395.9;
              0 0 1];
%% Using knowledge of internal parameters and planar homography
error('Does not work')
[R T N] = makeHdecomposition(H1);

X = makeCube3D();
k = inv(K);

iii = 2;
RT = [R{iii} T{iii}];
P = [RT; 0 0 0 1];
P = [k*R{iii}*inv(k) k*T{iii}];
x = (P*X);

%plotp(x,false,'r-')
plotp(wnorm(x(1:3,:)))

%% Using vanishing points
%error('Might not work (2011.09.26)')

%img = imread('imgs_proprietary/test_image_cabin1.jpg');
%img = imread('imgs_proprietary/test_image2.jpg');
img = imread('imgs_proprietary/test_image3.jpg');
imagesc(img)

vert1 = ginput(2);
vert2 = ginput(2);
horz1 = ginput(2);
hotz2 = ginput(2);
dept1 = ginput(2);
dept2 = ginput(2);

%load imgs_proprietary/test_image_cabin1.jpg.mat
%load imgs_proprietary/test_image2.jpg.mat

hold on
plot(vert1(:,1),vert1(:,2))
plot(vert2(:,1),vert2(:,2))
plot(horz1(:,1),horz1(:,2))
plot(hotz2(:,1),hotz2(:,2))
plot(dept1(:,1),dept1(:,2))
plot(dept2(:,1),dept2(:,2))
hold off

l_vert1 = makeLine2DFromPoints2D(vert1(1,:),vert1(2,:));
l_vert2 = makeLine2DFromPoints2D(vert2(1,:),vert2(2,:));
l_horz1 = makeLine2DFromPoints2D(horz1(1,:),horz1(2,:));
l_horz2 = makeLine2DFromPoints2D(hotz2(1,:),hotz2(2,:));
l_dept1 = makeLine2DFromPoints2D(dept1(1,:),dept1(2,:));
l_dept2 = makeLine2DFromPoints2D(dept2(1,:),dept2(2,:));

v1 = lineintersect2D([l_vert1 l_vert2]);
v2 = lineintersect2D([l_horz1 l_horz2]);
v3 = lineintersect2D([l_dept1 l_dept2]);

v1 = convertToHom(v1');
v2 = convertToHom(v2');
v3 = convertToHom(v3');

hold on
plotp(v1)
plotp(v2)
plotp(v3)
hold off
axis tight

w = makewfromConstraints({[v1 v2],[v1 v3],[v2 v3]},[],[],true);
K = makeKfromw(w,1)
