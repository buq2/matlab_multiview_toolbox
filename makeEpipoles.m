function [e e_] = makeEpipoles(F)
%Computers left and right epipole from fundamental matrix F
%
%HZ2 (iii) and Table 9.1 p.245-246
[U S V] = svd(F);
e = V(:,end); %Right epipole (Right null vector)
e_ = U(:,end); %Left epipole (Left null vector)

%Or using null
%e = null(F);
%e_ = null(F');