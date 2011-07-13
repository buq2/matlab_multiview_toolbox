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
K = K./K(end); %Added 2010.07.26