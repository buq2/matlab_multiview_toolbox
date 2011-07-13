function T = makeTfromP(P2,P3,P1)
%Makes trifocal tensor T from camera matrices P' (P2) and P'' (P3)
%If only two arguments are given, we assume that camera matrix P (P1) is [I|0]
%
%HZ. p. 415 (see also HZ. p. 377)

if nargin < 3
    P1 = [eye(3) zeros(3,1)];
end

warning('This function has not been tested. I have no idea of tensor notation. Please recosider using this function')

T = zeros(3,3,3); 
for q = 1:3
    for r = 1:3
        for ii = 1:3
            T(q,r,ii) = (-1)^(ii+1)*det([P1(ii,:);P2(q,:);P3(r,:)]);
        end
    end
end