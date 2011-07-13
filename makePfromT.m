function [P2 P3 e2 e3] = makePfromT(T)
%Returns camera matrices P' (P2) and P'' (P3) from trifocal tensor T
%P (P1) is [ones(3) zeros(3,1)]. Also epipoles e' (e2) and e'' (e3) are 
%returned
%
%Trifocal tensor T must be size [3 3 3] matrix
%
%Matti Jukola 2010
%
%HZ Algorithm 15.1 p. 375

%Retrieve epipoles
[e2 e3] = makeEpipolesFromT(T);

%Normalize epipoles to unit norm (NOTE: these are not returned)
ne2 = e2./norm(e2);
ne3 = e3./norm(e3);

P2 = [[T(:,:,1)*ne3 T(:,:,2)*ne3 T(:,:,3)*ne3] ne2];
P3 = [(ne3*ne3'-eye(3))*[T(:,:,1)'*ne2 T(:,:,2)'*ne2 T(:,:,3)'*ne2] ne3];