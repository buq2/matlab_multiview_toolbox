function F = makeFfromP(P,P_)
%Returns fundamental matrix made of projection
%matrix. If both P and P_ are given P1 = P and P2 = P_
%and general camera formula is used. If only P (P2) is given
%canonical camera formula is used.
%
%HZ2 Table 9.1 p. 246
%(Additional information for calibrated camera) HZ2 (9.4) p.244
%
%Matti Jukola 2010

if nargin == 1
    %Returns fundamental matrix made of second canonical camera P'
    %(First one is P1 = [I|0])
    %HZ2 Table 9.1 p. 246
    %F = [e']_x*M where M = P(:,1:3) and [e']_x is skew matrix
    %of right epipole e'
    F = makeSkew(P(:,end))*P(:,1:3);
else
    %Returns fundamental matrix made of general cameras
    %P1 = P and P2 = P_ (or P = P and P_ = P')
    %HZ2 Table 9.1 p. 246
    %
    %Calculate right epipole e_=e'=P'C where P' = P2
    %and C is camera centre of P1 (which is right 
    %null-vector of P1)
    [U S V] = svd(P,false);
    %C = [V(1:2,end)/V(end,end);1];
    C = V(:,end);
    e_ = P_*C;
    %Now...
    F = makeSkew(e_)*P_*pinv(P);
end