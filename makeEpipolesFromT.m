function [e2 e3] = makeEpipolesFromT(T,method)
%Returns epipoles e' (e2) and e'' (e3) from trifocal tensor T
%Method == 1
%       HZ2 Algorithm 15.1 p.375
%Method == 2
%       HZ2 p.395
if nargin < 2
    method = 2;
end

%Retrieve epipoles
e2 = zeros(3,1);
e3 = zeros(3,1);

if method == 1
    %HZ Algorithm 15.1 p. 375
    [U1 S1 V1] = svd(T(:,:,1));
    [U2 S2 V2] = svd(T(:,:,2));
    [U3 S3 V3] = svd(T(:,:,3));
    
    [U S V] = svd([U1(:,end) U2(:,end) U3(:,end)]);
    e2 = U(:,end);
    [U S V] = svd([V1(:,end) V2(:,end) V3(:,end)]);
    e3 = U(:,end);
elseif method == 2
    %HZ p. 395
    %TODO: Check if this is necessacery at all
    %      previous algorithm might be exactly the same
    V = zeros(3);
    for ii = 1:3
        [U_ S_ V_] = svd(T(:,:,ii));
        V(ii,:) = V_(:,end);
    end
    [U_ S_ V_] = svd(V);
    e3(:) = V_(:,end);
    
    for ii = 1:3
        [U_ S_ V_] = svd(T(:,:,ii)');
        V(ii,:) = V_(:,end);
    end
    [U_ S_ V_] = svd(V);
    e2(:) = V_(:,end);
else
   error('Unknown method'); 
end