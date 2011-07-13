%Mas changing focal length "autocalibration" algorithm
%This algorithm can be used when 
%
%Using Mas notation (Ma p. 400)
%Q consist of 5 non-zero elements
syms a1 a2 a3 a4 a5
Q = [a1 0 0 a2;
     0 a1 0 a3;
     0  0 1 a4;
     a2 a3 a4 a5];
%Campera matrix P = [u v w]'
syms u1 u2 u3 u4 v1 v2 v3 v4 w1 w2 w3 w4
u = [u1 u2 u3 u4].';
v = [v1 v2 v3 v4].';
w = [w1 w2 w3 w4].';

%Ma (11.26) constraints for autocalibration
constraint1 = u.'*Q*u-v.'*Q*v; %=0
constraint2 = u.'*Q*v;
constraint3 = u.'*Q*w;
constraint4 = v.'*Q*w;
constraint1 = collect(constraint1,[a1 a2 a3 a4 a5]);
constraint2 = collect(constraint2,[a1 a2 a3 a4 a5]);
constraint3 = collect(constraint3,[a1 a2 a3 a4 a5]);
constraint4 = collect(constraint4,[a1 a2 a3 a4 a5]);
%%
