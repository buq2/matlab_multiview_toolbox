function H = makeH3DQuasiAffine(P,X)
%Finds homography H which transforms P*inv(H) = P~ and H*X = X~ where
%P~ and X~ are quasi affine reconstructions of original P and X.
%Function assumes that all P and X have correct signs (fixPXSign.m).
%
%Input: 
%       P (cell) or single 3x4 matrix
%       X 4xn matrix

%HZ. p. 527 Algorithm 21.1

%Algorithm steps i) and ii) have already been performed in fixPXSign.m
%iii) Form the cheiral inequalities