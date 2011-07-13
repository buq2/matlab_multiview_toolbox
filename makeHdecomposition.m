function [R_ T_ N_] = makeHdecomposition(H,onlyPhysicallyPossible)
%Calculates decomposition H = (R + 1/d * T * N.') where d is unknown
%distance, H planar homography, R rotation matrix, T translation vector and
%N plane normal
%
%Inputs: H                      - Planar homography
%        onlyPhysicallyPossible - Retursn only physically possible
%                                 decompositions
%Outputs: R - Cell array containing rotation matrixes
%         T - Cell array containing translation vectors
%         N - Cell array containing planes normal vectors
%
%NOTES: Functions is not fully tested (onlyPhysiallyPossible)
%
%Ma et al - An Invitation to 3-D Vision p. 136
%Matti Jukola 2010.11.13

if nargin < 2
    onlyPhysicallyPossible = true;
end

%First normalize homography matrix (Ma Lemma 5.18)
[U S V] = svd(H);
S = diag(S);
H = H./S(2);

%(5.42)
[U S V] = svd(H'*H);
if abs(det(V)+1)<eps
   V = -V; 
end
S = diag(S);

% Using decomposition H'*H = V*S*V' ([U S V] = svd(H'*H))
v1 = V(:,1);
v2 = V(:,2);
v3 = V(:,3);

%(5.44)
u1 = (sqrt(1-S(3))*v1+sqrt(S(1)-1)*v3)/sqrt(S(1)-S(3));
u2 = (sqrt(1-S(3))*v1-sqrt(S(1)-1)*v3)/sqrt(S(1)-S(3));

U1 = [v2 u1 makeSkew(v2)*u1];
U2 = [v2 u2 makeSkew(v2)*u2];
W1 = [H*v2 H*u1 makeSkew(H*v2)*H*u1];
W2 = [H*v2 H*u2 makeSkew(H*v2)*H*u2];

%Table 5.1
R_ = {W1*U1', W2*U2', [], []};
R_{3} = R_{1};
R_{4} = R_{2};
N_ = {makeSkew(v2)*u1, makeSkew(v2)*u2,[],[]};
N_{3} = -N_{1};
N_{4} = -N_{2};
T_ = {(H-R_{1})*N_{1}, (H-R_{2})*N_{2}, [], []};
T_{3} = -T_{1};
T_{4} = -T_{2};

if onlyPhysicallyPossible
    suitable = false(4,1);
    for ii = 1:numel(suitable)
        if N_{ii}(3) > 0
            suitable(ii) = 1;
        end
    end
    
    R_ = R_(suitable);
    T_ = T_(suitable);
end
N_ = N_(suitable);