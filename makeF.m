function F = makeF(x1,x2,method)
%Calculates fundamental matrix F from point correspondances x1, x2
%
%size(x1,2) == 7 -> HZ2 11.1.2 p.281 7 point algorithm. 
%Method == 1 -> HZ2 Algorithm 11.2 p.284
%
%Matti Jukola 2010
if nargin < 3
    method = 1;
end

if size(x1,2) == 7
    %HZ2 11.1.2 p.281 7 point algorithm. 
    %
    %HZ2 p.281:
    %Solution for A*f=0 is a 2-dimensional space of the form
    %a*F1+(1-a)*F2 where 'a' is a scalar variable and F1 and F2 are
    %matrices correspond to the generators f1, f2 of the right null-space
    %of A. We can use constraint det(F)=0. This can be written as
    %det(a*F1+(1-a)*F2) = 0. Now we can solve 'a', complex solutions will
    %be discarded.
    
    %Few pointers taken from MATLAB code by Hartley & Zisserman
    %vgg_singF_from_FF and signs_OK
    A = makeAf(x1,x2);
    [U S V] = svd(A);
    F1 = reshape(V(:,end-1),[3 3]);
    F2 = reshape(V(:,end),[3 3]);
    
    %Solving cubic equation and getting 1 or 3 solutions for F
    %Note that deterCubic returns results quite different from
    %function vgg_singF_from_FF by HZ(?) when there is noise in x1 and x2. 
    %I would think that one of the functions is numerically more stabile, 
    %but I don't know which one. deterCubic gives more consistent results.
    dq = deterCubic(F1(1,1),F1(2,1),F1(3,1),F1(1,2),F1(2,2),F1(3,2),F1(1,3),F1(2,3),F1(3,3),...
        F2(1,1),F2(2,1),F2(3,1),F2(1,2),F2(2,2),F2(3,2),F2(1,3),F2(2,3),F2(3,3));
    a = roots(dq);
    a = a(abs(imag(a))<10*eps); %Discard complex solutions
    
    %For each solution
    F = [];
    for i = 1:length(a)
        Fi = a(i)*F1 + (1-a(i))*F2;
        if signs_OK(Fi,x1,x2)
            F = cat(3, F, Fi);
        end
    end
    return
end

%First normalize
[x1 T1] = normalizePoints(x1);
[x2 T2] = normalizePoints(x2);
x1 = wnorm(x1); %Make sure that w is 1
x2 = wnorm(x2);
A = makeAf(x1,x2); %Create A matrix
F = zeros(3); %Reserve memory
if any(method == [1 2 3])
    %HZ2 Algorithm 11.1 p.282 The Normalized 8-point algorithm
    %MASKS Algorithm 6.1 p.212 The 8-point algorithm
    [U S V] = svd(A,false); %Solve equation A*f = 0 using SVD
    F(:) = V(:,end); %Right null space
    F = F'; %Previous F was transpose (caused by how we formed A)
    
    %Make sure that det(F) = 0
    [U S V] = svd(F,false); 
    S(end) = 0;
    F =  U*S*V';
end

if method == 2
   %Iterative computation of F by minimizing algebraic error
   %HZ2 Algorithm 11.2 p.284
   %MASKS Algorithm 11.5 p.393 
   %    -MASKS algorithm is little bit different:
   %     -It uses Sampson distance instead of geometric (A*f)
   %     -Algorithm used here does not use reconstruction from MASKS
   
   warning('This method has not beed fully tested');
 
   %(i) Compute right null vector of F
   [U S V] = svd(F,false);
   e = V(:,end);
   
   %(iv)
   alg_lsqmin_fun(e); %Set e_prev
   %Minimize
   e = lsqnonlin(@(e)(alg_lsqmin_fun(A,e)),e(:),[],[],optimset('TolX',1e-10,'TolFun',1e-10,'Algorithm','levenberg-marquardt','Display','iter','MaxIter',10));
   E = zeros(9);
   e_skew = makeSkew(e);
   E(1:3,1:3) = e_skew;
   E(4:6,4:6) = e_skew;
   E(7:9,7:9) = e_skew;
   
   [U S V] = svd(E,false);
   %Rank of E is 6
   U_pr = U(:,1:6); %U'
   [U S V] = svd(A*U_pr,false); %'A' was computed previously
   f = U_pr*V(:,end);
   F(:) = f;
   F = F';
end

if method == 3
    error('Does not work')
    
    %HZ2 Algorithm 11.3 p.285 Gold Standard algorithm
    %P1 = [eye(3) zeros(3,1)]; %P
    %P2 = makePfromF(F);
    
    warning('This method has not beed fully tested');
    
    %Solve nonlinear mimization problem (minimize pixel error)
    F(:) = lsqnonlin(@(f)gold_lsqmin_fun(x1,x2,f),F(:),[],[],optimset('TolX',1e-19,'TolFun',1e-19,'Algorithm','levenberg-marquardt','Display','iter','MaxIter',10));
end

%Denormalize
%In book An Introduction to 3D Vision Techniques and Algorithms
%Cyganek B. Siebert P. 2009
%Example in page 48 uses erronously T1'*F*T2 for final F
F = T2'*F*T1;

return

% function er = alg_lsqmin_fun(A,f)
% %HZ2 p.284
% persistent e_prev;
% if nargin == 1 %Set e_prev
%     e_prev = A;
%     return
% end
% 
% %(i) Compute right null vector of F
% [U S V] = svd(reshape(f,[3 3])',false);
% e = V(:,end);
%    
% %(ii) Compute matrix E_i
% E = zeros(9);
% e_skew = makeSkew(e);
% E(1:3,1:3) = e_skew;
% E(4:6,4:6) = e_skew;
% E(7:9,7:9) = e_skew;
%   
% [U S V] = svd(E,false);
% %Rank of E is 6
% U_pr = U(:,1:6); %U'
% [U S V] = svd(A*U_pr,false); %'A' was computed previously
% f = U_pr*V(:,end);
%    
% %(iii)
% if e'*e_prev < 0
%    f = -f; 
% end
% er = A*f;
% 
% %Save e_i as e_(i-1)
% e_prev = e;
% return

function er = alg_lsqmin_fun(A,e)
error('Not tested')
%HZ2 p.284
persistent e_prev;
if nargin == 1 %Set e_prev
    e_prev = A;
    return
end
   
%(ii) Compute matrix E_i
E = zeros(9);
e_skew = makeSkew(e);
E(1:3,1:3) = e_skew;
E(4:6,4:6) = e_skew;
E(7:9,7:9) = e_skew;
  
% [U S V] = svd(E,false);
% %Rank of E is 6
% U_pr = U(:,1:6); %U'
% [U S V] = svd(A*U_pr,false); %'A' was computed previously
% f = U_pr*V(:,end);
[U S V] = svd(A*E,false);
m = V(:,end);
f = E*m;
   
%(iii)
if e'*e_prev < 0
   f = -f; 
end
er = A*f;

%Save e_i as e_(i-1)
e_prev = e;
return

function out = gold_lsqmin_fun(x1,x2,f)
%Calculate (iii) (HZ Algorithm 11.3)
F = zeros(3);
F(:) = f(:);
P1 = [eye(3) zeros(3,1)];
P2 = makePfromF(F);
X = triangulate(F,x1,x2);
x1_ = x1-P1*X;
x2_ = x2-P2*X;
out = sum(x1_.^2,1)+sum(x2_.^2,1);
out = out';
return

% Checks sign consistence of F and x
function OK = signs_OK(F,x1,x2)
%Compute left epipole (see makeEpipoles.m for more info)
%
%Function mostly by HZ as I (Matti Jukola) can not quite grasp its purpose
%or what it does.
%
%Probably checks that all points, x1 and x2 are either in front of the
%cameras, or behind it.
[U S V] = svd(F);
e = U(:,end);
l1 = makeSkew(e)*x1;
s = sum( (F*x2) .* l1 );
OK = all(s>0) | all(s<0);
return

function deterCubic = deterCubic(F1_11,F1_21,F1_31,F1_12,F1_22,F1_32,F1_13,F1_23,F1_33,F2_11,F2_21,F2_31,F2_12,F2_22,F2_32,F2_13,F2_23,F2_33)
%DETERCUBIC - Returns coefficients for cubic function which roots will be
%solutions for det(a*F1+(1-a)*F2)=0
%    DETERCUBIC = DETERCUBIC(F1_11,F1_21,F1_31,F1_12,F1_22,F1_32,F1_13,F1_23,F1_33,F2_11,F2_21,F2_31,F2_12,F2_22,F2_32,F2_13,F2_23,F2_33)

%    This function was generated by the Symbolic Math Toolbox version 5.5.
%    21-Dec-2010 17:03:13

%This function was generated using following code:
% syms a
% F1 = sym(zeros(3));
% F2 = sym(zeros(3));
% for ii = 1:3
%     for jj = 1:3
%         eval(['syms F1_' num2str(ii) num2str(jj) ';']);
%         eval(['syms F2_' num2str(ii) num2str(jj) ';']);
%         eval(['F1(' num2str(ii) ',' num2str(jj) ') = F1_' num2str(ii) num2str(jj) ';'])
%         eval(['F2(' num2str(ii) ',' num2str(jj) ') = F2_' num2str(ii) num2str(jj) ';'])
%     end
% end
% %Form cubic function whichs coefficients this function returns
% deter = simple(collect(det(a*F1+(1-a)*F2),a));
% str = strrep(strrep(strrep(['[' char(deter) ']'],'*a^3 +',','),'*a^2 +',','),'*a +',',');
% deterCubic = sym(str);
% matlabFunction(deterCubic,'vars',[F1(:).' F2(:).'],'file','deterCubic')
%
%Matti Jukola 2010.12.21

t27 = F1_11.*F1_23.*F2_32;
t28 = F1_11.*F1_32.*F2_23;
t29 = F1_12.*F1_21.*F2_33;
t30 = F1_12.*F1_33.*F2_21;
t31 = F1_21.*F1_33.*F2_12;
t32 = F1_13.*F1_22.*F2_31;
t33 = F1_13.*F1_31.*F2_22;
t34 = F1_22.*F1_31.*F2_13;
t35 = F1_23.*F1_32.*F2_11;
t36 = F1_11.*F2_22.*F2_33;
t37 = F1_12.*F2_31.*F2_23;
t38 = F1_21.*F2_13.*F2_32;
t39 = F1_13.*F2_21.*F2_32;
t40 = F1_22.*F2_11.*F2_33;
t41 = F1_31.*F2_12.*F2_23;
t42 = F1_23.*F2_12.*F2_31;
t43 = F1_32.*F2_21.*F2_13;
t44 = F1_33.*F2_11.*F2_22;
t45 = F2_11.*F2_22.*F2_33.*3.0;
t46 = F2_12.*F2_31.*F2_23.*3.0;
t47 = F2_21.*F2_13.*F2_32.*3.0;
t48 = F2_11.*F2_23.*F2_32;
t49 = F2_12.*F2_21.*F2_33;
t50 = F2_13.*F2_22.*F2_31;
deterCubic = [t27+t28+t29+t30+t31+t32+t33+t34+t35+t36+t37+t38+t39+t40+t41+t42+t43+t44+t48+t49+t50+F1_11.*F1_22.*F1_33-F1_11.*F1_23.*F1_32-F1_12.*F1_21.*F1_33+F1_12.*F1_31.*F1_23+F1_21.*F1_13.*F1_32-F1_13.*F1_22.*F1_31-F1_11.*F1_22.*F2_33-F1_11.*F1_33.*F2_22-F1_12.*F1_31.*F2_23-F1_12.*F1_23.*F2_31-F1_21.*F1_13.*F2_32-F1_21.*F1_32.*F2_13-F1_13.*F1_32.*F2_21-F1_22.*F1_33.*F2_11-F1_31.*F1_23.*F2_12-F1_11.*F2_23.*F2_32-F1_12.*F2_21.*F2_33-F1_21.*F2_12.*F2_33-F1_13.*F2_22.*F2_31-F1_22.*F2_13.*F2_31-F1_31.*F2_13.*F2_22-F1_23.*F2_11.*F2_32-F1_32.*F2_11.*F2_23-F1_33.*F2_12.*F2_21-F2_11.*F2_22.*F2_33-F2_12.*F2_31.*F2_23-F2_21.*F2_13.*F2_32,-t27-t28-t29-t30-t31-t32-t33-t34-t35+t45+t46+t47+F1_11.*F1_22.*F2_33+F1_11.*F1_33.*F2_22+F1_12.*F1_31.*F2_23+F1_12.*F1_23.*F2_31+F1_21.*F1_13.*F2_32+F1_21.*F1_32.*F2_13+F1_13.*F1_32.*F2_21+F1_22.*F1_33.*F2_11+F1_31.*F1_23.*F2_12-F1_11.*F2_22.*F2_33.*2.0+F1_11.*F2_23.*F2_32.*2.0+F1_12.*F2_21.*F2_33.*2.0-F1_12.*F2_31.*F2_23.*2.0+F1_21.*F2_12.*F2_33.*2.0-F1_21.*F2_13.*F2_32.*2.0-F1_13.*F2_21.*F2_32.*2.0+F1_13.*F2_22.*F2_31.*2.0-F1_22.*F2_11.*F2_33.*2.0+F1_22.*F2_13.*F2_31.*2.0-F1_31.*F2_12.*F2_23.*2.0+F1_31.*F2_13.*F2_22.*2.0+F1_23.*F2_11.*F2_32.*2.0-F1_23.*F2_12.*F2_31.*2.0+F1_32.*F2_11.*F2_23.*2.0-F1_32.*F2_21.*F2_13.*2.0-F1_33.*F2_11.*F2_22.*2.0+F1_33.*F2_12.*F2_21.*2.0-F2_11.*F2_23.*F2_32.*3.0-F2_12.*F2_21.*F2_33.*3.0-F2_13.*F2_22.*F2_31.*3.0,t36+t37+t38+t39+t40+t41+t42+t43+t44-t45-t46-t47-F1_11.*F2_23.*F2_32-F1_12.*F2_21.*F2_33-F1_21.*F2_12.*F2_33-F1_13.*F2_22.*F2_31-F1_22.*F2_13.*F2_31-F1_31.*F2_13.*F2_22-F1_23.*F2_11.*F2_32-F1_32.*F2_11.*F2_23-F1_33.*F2_12.*F2_21+F2_11.*F2_23.*F2_32.*3.0+F2_12.*F2_21.*F2_33.*3.0+F2_13.*F2_22.*F2_31.*3.0,-t48-t49-t50+F2_11.*F2_22.*F2_33+F2_12.*F2_31.*F2_23+F2_21.*F2_13.*F2_32];
return