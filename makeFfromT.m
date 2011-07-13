function [F21 F31 e2 e3] = makeFfromT(T)
%Returns funamental matrices F_21 and F_31 corresponding to trifocal
%tensor T. Also epipoles e' (e2) and e'' (e3) are 
%returned.
%
%Trifocal tensor T must be size [3 3 3] matrix
%
%HZ Algorithm 15.1 p. 375

warning('This algorithm has not bee fully tested');

%Retrieve epipoles
[e2 e3] = makeEpipolesFromT(T);

F21 = makeSkew(e2)*[T(:,:,1) T(:,:,2) T(:,:,3)]*e3;
F31 = makeSkew(e3)*[T(:,:,1)' T(:,:,2)' T(:,:,3)']*e2;