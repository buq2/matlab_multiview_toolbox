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
H1 = makeH(X,corner_points(:,1:4));
H2 = makeH(X,corner_points(:,5:8));
H3 = makeH(X,corner_points(:,9:12));

K = makeKfromH({H1,H2,H3})

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










