function K = makeKfromH(H)
%Calcualtes internal camera parameters in matrix K from 
%plane homographys H (at least three homographies are needed)
%
%Inputs:  H - cell array of plane homographies. Each cell is 3x3 matrix
%Outputs: K - Internal parameters, upper triangular matrix
%
%Ma et. al - An Invitation to 3-D Vision pp. 203-204
%HZ - pp. 211 Example 8.18
%
%Matti Jukola 2010.11.12

%Calculate image of absolute conic
w = makewfromH(H);

%Calculate K from absolute conic
K = makeKfromw(w);