function [K R C] = decomposeP(P)
%Decomposes camera matrix in to three variables
%K = intricit parameters
%R = rotation matrix
%C = camera centre
%
%Original P = K*[R -R*C(1:3)]
%Or we could write M = K*R and then P = [M -M*C(1:3)]
%
%HZ2 6.2.4 p.163
%
%Matti Jukola 2010

[K R] = rq(P(1:3,1:3));
%Multiple ways to solve camera location
%C2 = -P(1:3,1:3)\P(:,4)
[U S V] = svd(P);
C = V(:,end);
%C = [det([P(:,2) P(:,3) P(:,4)]); ... %Wedge product of P
%    -det([P(:,1) P(:,3) P(:,4)]); ...
%     det([P(:,1) P(:,2) P(:,4)]); ...
%    -det([P(:,1) P(:,2) P(:,3)])]
C = wnorm(C);

% Make sure that diagonal values of the K
% are positive
T = -R*C(1:3);
sigs = sign(diag(K));
for ii = 1:numel(sigs)
    if sigs(ii) < 0
        tmp = eye(3);
        tmp(ii,ii) = -1;
        K = K*tmp;
        R = tmp\R;
        T = tmp\T;
    end
end
% Recalculate C
C = [-inv(R)*T;1];

% We could make sure that last element of K is 1
% which would make certain calculations easier, but
% this would cause K*[R -RC] not to be exactly same as P
%K = K./norm(K(end));
