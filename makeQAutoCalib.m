function [Q H P f] = makeQAutoCalib(Pcell)
%Pollefeys Tutorial p.62
%
%Matti Jukola 2010
A = zeros(6*numel(Pcell),16);
v = ones(numel(Pcell),1);
for kk = 1:10
    for ii = 1:numel(Pcell)
        P = Pcell{ii};
        amini = [1/(9*v(ii)).*[(P(1,1)^2 - P(3,1)^2) (P(1,1)*P(1,2) - P(3,1)*P(3,2)) (P(1,1)*P(1,3) - P(3,1)*P(3,3))  (P(1,1)*P(1,4) - P(3,1)*P(3,4)) (P(1,1)*P(1,2) - P(3,1)*P(3,2)) (P(1,2)^2 - P(3,2)^2) (P(1,2)*P(1,3) - P(3,2)*P(3,3)) (P(1,2)*P(1,4) - P(3,2)*P(3,4))  (P(1,1)*P(1,3) - P(3,1)*P(3,3)) (P(1,2)*P(1,3) - P(3,2)*P(3,3)) (P(1,3)^2 - P(3,3)^2) (P(1,3)*P(1,4) - P(3,3)*P(3,4)) (P(1,1)*P(1,4) - P(3,1)*P(3,4)) (P(1,2)*P(1,4) - P(3,2)*P(3,4)) (P(1,3)*P(1,4) - P(3,3)*P(3,4)) (P(1,4)^2 - P(3,4)^2)];...
            1/(9*v(ii)).*[(P(2,1)^2 - P(3,1)^2) (P(2,1)*P(2,2) - P(3,1)*P(3,2)) (P(2,1)*P(2,3) - P(3,1)*P(3,3)) (P(2,1)*P(2,4) - P(3,1)*P(3,4)) (P(2,1)*P(2,2) - P(3,1)*P(3,2)) (P(2,2)^2 - P(3,2)^2) (P(2,2)*P(2,3) - P(3,2)*P(3,3)) (P(2,2)*P(2,4) - P(3,2)*P(3,4)) (P(2,1)*P(2,3) - P(3,1)*P(3,3)) (P(2,2)*P(2,3) - P(3,2)*P(3,3)) (P(2,3)^2 - P(3,3)^2) (P(2,3)*P(2,4) - P(3,3)*P(3,4)) (P(2,1)*P(2,4) - P(3,1)*P(3,4)) (P(2,2)*P(2,4) - P(3,2)*P(3,4)) (P(2,3)*P(2,4) - P(3,3)*P(3,4)) (P(2,4)^2 - P(3,4)^2)];...
            1./(0.2*v(ii)).*[(P(1,1)^2 - P(2,1)^2) (P(1,1)*P(1,2) - P(2,1)*P(2,2)) (P(1,1)*P(1,3) - P(2,1)*P(2,3)) (P(1,1)*P(1,4) - P(2,1)*P(2,4)) (P(1,1)*P(1,2) - P(2,1)*P(2,2)) (P(1,2)^2 - P(2,2)^2) (P(1,2)*P(1,3) - P(2,2)*P(2,3)) (P(1,2)*P(1,4) - P(2,2)*P(2,4)) (P(1,1)*P(1,3) - P(2,1)*P(2,3)) (P(1,2)*P(1,3) - P(2,2)*P(2,3)) (P(1,3)^2 - P(2,3)^2) (P(1,3)*P(1,4) - P(2,3)*P(2,4)) (P(1,1)*P(1,4) - P(2,1)*P(2,4)) (P(1,2)*P(1,4) - P(2,2)*P(2,4)) (P(1,3)*P(1,4) - P(2,3)*P(2,4)) (P(1,4)^2 - P(2,4)^2)];...
            1/(0.1*v(ii)).*[(P(1,1)*P(2,1)) (P(1,2)*P(2,1)) (P(1,3)*P(2,1)) (P(1,4)*P(2,1)) (P(1,1)*P(2,2)) (P(1,2)*P(2,2)) (P(1,3)*P(2,2)) (P(1,4)*P(2,2)) (P(1,1)*P(2,3)) (P(1,2)*P(2,3)) (P(1,3)*P(2,3)) (P(1,4)*P(2,3)) (P(1,1)*P(2,4)) (P(1,2)*P(2,4)) (P(1,3)*P(2,4)) (P(1,4)*P(2,4))];...
            1/(0.1*v(ii)).*[(P(1,1)*P(3,1)) (P(1,2)*P(3,1)) (P(1,3)*P(3,1)) (P(1,4)*P(3,1)) (P(1,1)*P(3,2)) (P(1,2)*P(3,2)) (P(1,3)*P(3,2)) (P(1,4)*P(3,2)) (P(1,1)*P(3,3)) (P(1,2)*P(3,3)) (P(1,3)*P(3,3)) (P(1,4)*P(3,3)) (P(1,1)*P(3,4)) (P(1,2)*P(3,4)) (P(1,3)*P(3,4)) (P(1,4)*P(3,4))];...
            1/(0.01*v(ii)).*[(P(2,1)*P(3,1)) (P(2,2)*P(3,1)) (P(2,3)*P(3,1)) (P(2,4)*P(3,1)) (P(2,1)*P(3,2)) (P(2,2)*P(3,2)) (P(2,3)*P(3,2)) (P(2,4)*P(3,2)) (P(2,1)*P(3,3)) (P(2,2)*P(3,3)) (P(2,3)*P(3,3)) (P(2,4)*P(3,3)) (P(2,1)*P(3,4)) (P(2,2)*P(3,4)) (P(2,3)*P(3,4)) (P(2,4)*P(3,4))]...
            ];
        A((ii-1)*6+1:ii*6,:) = amini;
    end
    [U S V] = svd(A);
    Q = reshape(V(:,end),[4 4]);
    for ii = 1:numel(Pcell)
       v(ii) = Pcell{ii}(3,:)*Q*Pcell{ii}(3,:)'; 
    end
end

Qt = Q';
Q(:) = mean([Q(:) Qt(:)],2);

% %Rest of the functions is from MASKS (see makeQAutocalib2)
% 
% %Yi Ma et. al. An Invitation to 3-D Vision p. 401
% %6) Enforce the rank-3 constraint on Q_
% [U S V] = svd(Q);
% S(end) = 0;
% Q = U*S*V';
% 
% %7) Calculate new focal lengths
% f = zeros(size(Pcell));
% for ii = 1:numel(f)
%    tmp = Pcell{ii}*Q*Pcell{ii}.';
%    f(ii) = sqrt(tmp(1));
% end
% 
% %8)
% K1 = [sqrt(Qt(1)) 0 0; 0 sqrt(Qt(1)) 0; 0 0 1];
% v = -[Qt(2)/Qt(1) Qt(3)/Qt(1) Qt(4)]';
% H = [K1 zeros(3,1);-v'*K1 1];
% if nargout > 1
%    for ii = 1:numel(Pcell)
%       Pcell{ii} = Pcell{ii}*H; 
%    end
% end
% 
% P = Pcell;

%From mvg_autocalibration.cpp
[U S V] = svd(Q);
for ii = 1:4
    for jj = 1:3
        U(ii,jj) = U(ii,jj) * sqrt(S(jj,jj));
    end
end
H = inv(-U');